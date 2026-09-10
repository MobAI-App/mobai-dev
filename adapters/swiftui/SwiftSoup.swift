//
//  SwiftSoup.swift
//  Hand-written stand-in for the common HTML parsing and tree-walking surface.
//
//  TWO SHAPES THIS MUST HAVE. `Document` IS a `Node`
//  (`handleNode(node: document)` proves it), and `SwiftSoup.parse` /
//  `SwiftSoup.Node` are MODULE-qualified names - so there is deliberately no
//  type called SwiftSoup in here. A namespace enum of that name swallows every
//  qualified reference; with the engine's module aliasing, the module itself
//  answers to the name, which is what the app means.
//
//  Everything is explicitly nonisolated: this compiles under the app package's
//  mirrored MainActor default, and HTMLString does its parsing in nonisolated
//  code.
//
//  WHAT IS HONEST: a small real parser. Tags with attributes, text, comments,
//  entities, void elements, auto-closed paragraphs and list items. The tree
//  it builds is what an app's markdown walk reads (nodeName, children, attr,
//  description), so a Mastodon post body comes out as its text, links and
//  paragraphs. What is NOT here: error recovery for misnested tags beyond
//  closing the innermost open element, CSS selectors beyond
//  `tag`, `.class`, `#id`, `[attr]`, `:not(.class)` and comma lists, and
//  pretty printing. An earlier version of this file parsed nothing and every
//  post rendered empty with no diagnostic; that is the failure this one
//  exists to prevent.
//

import Foundation

nonisolated public func parse(_ html: String) throws -> Document { Parser(html).document() }
nonisolated public func parse(_ html: String, _ baseUri: String) throws -> Document { Parser(html).document() }
nonisolated public func parseBodyFragment(_ html: String) throws -> Document { Parser(html).document() }

/// `clean` with an empty whitelist keeps the text and drops every tag, which
/// is what the app reads back as "raw text" before unescaping it.
nonisolated public func clean(
    _ html: String, _ baseUri: String, _ whitelist: Whitelist,
    _ settings: OutputSettings
) throws -> String? {
    Parser(html).document().rawText()
}

nonisolated public func clean(_ html: String, _ whitelist: Whitelist) throws -> String? {
    Parser(html).document().rawText()
}

// MARK: - Nodes

nonisolated open class Node: @unchecked Sendable, CustomStringConvertible {
    nonisolated(unsafe) public internal(set) weak var parentNode: Node?
    nonisolated(unsafe) var childNodesStorage: [Node] = []
    /// The node's attributes; text nodes have none.
    nonisolated(unsafe) var attributesStorage: [(key: String, value: String)] = []

    nonisolated public init() {}

    nonisolated open func nodeName() -> String { "#root" }
    nonisolated public func getChildNodes() -> [Node] { childNodesStorage }
    nonisolated public func childNodeSize() -> Int { childNodesStorage.count }
    nonisolated public func childNode(_ index: Int) -> Node { childNodesStorage[index] }
    nonisolated public func parent() -> Node? { parentNode }
    nonisolated public func hasParent() -> Bool { parentNode != nil }

    nonisolated public func attr(_ key: String) throws -> String {
        let wanted = key.lowercased()
        return attributesStorage.first { $0.key == wanted }?.value ?? ""
    }
    nonisolated public func hasAttr(_ key: String) -> Bool {
        let wanted = key.lowercased()
        return attributesStorage.contains { $0.key == wanted }
    }
    @discardableResult
    nonisolated public func attr(_ key: String, _ value: String) throws -> Node {
        let wanted = key.lowercased()
        if let index = attributesStorage.firstIndex(where: { $0.key == wanted }) {
            attributesStorage[index].value = value
        } else {
            attributesStorage.append((wanted, value))
        }
        return self
    }

    /// The outer HTML, as the real library's `description` is.
    nonisolated public var description: String { outerHtmlText() }
    nonisolated public func outerHtml() throws -> String { outerHtmlText() }
    nonisolated open func outerHtmlText() -> String {
        childNodesStorage.map { $0.outerHtmlText() }.joined()
    }

    /// Text of every text node below, entities still encoded.
    nonisolated open func rawText() -> String {
        childNodesStorage.map { $0.rawText() }.joined()
    }

    nonisolated public func remove() throws {
        parentNode?.childNodesStorage.removeAll { $0 === self }
        parentNode = nil
    }

    /// Inserts the parsed fragment after this node.
    @discardableResult
    nonisolated public func after(_ html: String) throws -> Node {
        guard let parent = parentNode,
              let index = parent.childNodesStorage.firstIndex(where: { $0 === self })
        else { return self }
        let fragment = Parser(html).document().childNodesStorage
        for (offset, node) in fragment.enumerated() {
            node.parentNode = parent
            parent.childNodesStorage.insert(node, at: index + 1 + offset)
        }
        return self
    }

    @discardableResult
    nonisolated public func before(_ html: String) throws -> Node {
        guard let parent = parentNode,
              let index = parent.childNodesStorage.firstIndex(where: { $0 === self })
        else { return self }
        let fragment = Parser(html).document().childNodesStorage
        for (offset, node) in fragment.enumerated() {
            node.parentNode = parent
            parent.childNodesStorage.insert(node, at: index + offset)
        }
        return self
    }

    nonisolated func appendChild(_ node: Node) {
        node.parentNode = self
        childNodesStorage.append(node)
    }
}

nonisolated public final class TextNode: Node, @unchecked Sendable {
    /// The text as written in the source, entities included.
    nonisolated(unsafe) private var raw: String

    nonisolated public init(_ text: String, _ baseUri: String? = nil) {
        raw = text
        super.init()
    }
    // Explicit: the implicit override synthesises as MainActor under the
    // mirrored default and clashes with the nonisolated base init.
    nonisolated override public convenience init() { self.init("") }

    nonisolated override public func nodeName() -> String { "#text" }
    /// Decoded text, as the real library returns it.
    nonisolated public func text() -> String { Entities.unescape(raw) }
    nonisolated public func getWholeText() -> String { Entities.unescape(raw) }
    nonisolated public func isBlank() -> Bool {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    nonisolated override public func outerHtmlText() -> String { raw }
    nonisolated override public func rawText() -> String { raw }
}

nonisolated public final class Comment: Node, @unchecked Sendable {
    nonisolated(unsafe) private let data: String
    nonisolated public init(_ data: String) {
        self.data = data
        super.init()
    }
    nonisolated override public func nodeName() -> String { "#comment" }
    nonisolated override public func outerHtmlText() -> String { "<!--" + data + "-->" }
    nonisolated override public func rawText() -> String { "" }
}

nonisolated open class Element: Node, @unchecked Sendable {
    nonisolated(unsafe) private let tag: String

    nonisolated public init(tag: String) {
        self.tag = tag
        super.init()
    }
    nonisolated override public convenience init() { self.init(tag: "div") }

    nonisolated override public func nodeName() -> String { tag }
    nonisolated public func tagName() -> String { tag }
    nonisolated public func id() -> String { (try? attr("id")) ?? "" }
    nonisolated public func className() throws -> String { try attr("class") }
    nonisolated public func classNames() throws -> Set<String> {
        Set(try attr("class").split(separator: " ").map(String.init))
    }
    nonisolated public func hasClass(_ name: String) -> Bool {
        ((try? attr("class")) ?? "").split(separator: " ").contains { $0 == name }
    }

    /// Decoded text of the whole subtree, whitespace collapsed like the real
    /// library's `text()`.
    nonisolated public func text() throws -> String {
        Element.normalize(Entities.unescape(rawText()))
    }
    nonisolated public func ownText() -> String {
        Element.normalize(childNodesStorage.compactMap { ($0 as? TextNode)?.text() }.joined())
    }
    nonisolated public func html() throws -> String {
        childNodesStorage.map { $0.outerHtmlText() }.joined()
    }
    nonisolated public func children() -> Elements {
        Elements(childNodesStorage.compactMap { $0 as? Element })
    }
    nonisolated public func child(_ index: Int) -> Element {
        childNodesStorage.compactMap { $0 as? Element }[index]
    }
    nonisolated public func getElementsByTag(_ name: String) throws -> Elements {
        try select(name)
    }
    nonisolated public func getAllElements() -> Elements {
        Elements(descendants())
    }

    nonisolated public func select(_ query: String) throws -> Elements {
        let selectors = query.split(separator: ",").map {
            Selector(String($0).trimmingCharacters(in: .whitespaces))
        }
        return Elements(descendants().filter { element in
            selectors.contains { $0.matches(element) }
        })
    }

    nonisolated func descendants() -> [Element] {
        var out: [Element] = []
        for child in childNodesStorage {
            if let element = child as? Element {
                out.append(element)
                out.append(contentsOf: element.descendants())
            }
        }
        return out
    }

    nonisolated override public func outerHtmlText() -> String {
        let attributes = attributesStorage
            .map { " \($0.key)=\"\($0.value)\"" }.joined()
        if Parser.voidTags.contains(tag) { return "<\(tag)\(attributes)>" }
        return "<\(tag)\(attributes)>" + childNodesStorage.map { $0.outerHtmlText() }.joined()
            + "</\(tag)>"
    }

    nonisolated static func normalize(_ text: String) -> String {
        var out = ""
        var pendingSpace = false
        for scalar in text.unicodeScalars {
            if scalar == " " || scalar == "\n" || scalar == "\t" || scalar == "\r" {
                pendingSpace = !out.isEmpty
            } else {
                if pendingSpace { out.append(" "); pendingSpace = false }
                out.unicodeScalars.append(scalar)
            }
        }
        return out
    }
}

nonisolated public final class Document: Element, @unchecked Sendable {
    nonisolated public init(_ baseUri: String = "") {
        super.init(tag: "#root")
    }
    nonisolated override public func nodeName() -> String { "#root" }
    nonisolated public func body() -> Element? { self }
    nonisolated public func title() -> String {
        ((try? select("title"))?.array().first).flatMap { try? $0.text() } ?? ""
    }
    @discardableResult
    nonisolated public func outputSettings(_ settings: OutputSettings) -> Document { self }
    nonisolated public func outputSettings() -> OutputSettings { OutputSettings() }
    nonisolated override public func outerHtmlText() -> String {
        childNodesStorage.map { $0.outerHtmlText() }.joined()
    }
}

/// A selection. Mutations apply to every element in it.
nonisolated public final class Elements: @unchecked Sendable, Sequence {
    nonisolated(unsafe) private var elements: [Element]

    nonisolated public init(_ elements: [Element] = []) { self.elements = elements }

    nonisolated public func array() -> [Element] { elements }
    nonisolated public var count: Int { elements.count }
    nonisolated public var isEmpty: Bool { elements.isEmpty }
    nonisolated public func size() -> Int { elements.count }
    nonisolated public func first() -> Element? { elements.first }
    nonisolated public func last() -> Element? { elements.last }
    nonisolated public func get(_ index: Int) -> Element { elements[index] }
    nonisolated public func makeIterator() -> IndexingIterator<[Element]> { elements.makeIterator() }

    nonisolated public func remove() throws { for element in elements { try element.remove() } }
    nonisolated public func after(_ html: String) throws { for element in elements { try element.after(html) } }
    nonisolated public func before(_ html: String) throws { for element in elements { try element.before(html) } }
    nonisolated public func text() throws -> String {
        try elements.map { try $0.text() }.joined(separator: " ")
    }
    nonisolated public func html() throws -> String {
        try elements.map { try $0.html() }.joined(separator: "\n")
    }
    nonisolated public func attr(_ key: String) throws -> String {
        try elements.first?.attr(key) ?? ""
    }
    nonisolated public func hasClass(_ name: String) -> Bool {
        elements.contains { $0.hasClass(name) }
    }
    nonisolated public func select(_ query: String) throws -> Elements {
        Elements(try elements.flatMap { try $0.select(query).array() })
    }
}

nonisolated public final class OutputSettings: @unchecked Sendable {
    nonisolated public init() {}
    @discardableResult
    nonisolated public func prettyPrint(pretty: Bool) -> OutputSettings { self }
    @discardableResult
    nonisolated public func indentAmount(indentAmount: UInt) -> OutputSettings { self }
    @discardableResult
    nonisolated public func outline(outlineMode: Bool) -> OutputSettings { self }
}

nonisolated public final class Whitelist: @unchecked Sendable {
    nonisolated public init() {}
    nonisolated public static func none() throws -> Whitelist { Whitelist() }
    nonisolated public static func basic() throws -> Whitelist { Whitelist() }
    nonisolated public static func simpleText() throws -> Whitelist { Whitelist() }
    nonisolated public static func relaxed() throws -> Whitelist { Whitelist() }
}

// MARK: - Entities

open class Entities: @unchecked Sendable {
    nonisolated public init() {}

    nonisolated private static let named: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": "\u{00A0}",
        "copy": "\u{00A9}", "reg": "\u{00AE}", "hellip": "\u{2026}", "mdash": "\u{2014}",
        "ndash": "\u{2013}", "lsquo": "\u{2018}", "rsquo": "\u{2019}", "ldquo": "\u{201C}",
        "rdquo": "\u{201D}", "euro": "\u{20AC}", "pound": "\u{00A3}", "yen": "\u{00A5}",
        "trade": "\u{2122}", "times": "\u{00D7}", "laquo": "\u{00AB}", "raquo": "\u{00BB}",
        "bull": "\u{2022}", "middot": "\u{00B7}", "deg": "\u{00B0}", "para": "\u{00B6}",
    ]

    /// Decodes the entities in `string`. Unknown ones are left as written.
    nonisolated public static func unescape(_ string: String) -> String {
        guard string.contains("&") else { return string }
        var out = ""
        var rest = Substring(string)
        while let amp = rest.firstIndex(of: "&") {
            out += rest[..<amp]
            let after = rest[rest.index(after: amp)...]
            guard let semicolon = after.firstIndex(of: ";"),
                  after.distance(from: after.startIndex, to: semicolon) <= 10 else {
                out.append("&")
                rest = after
                continue
            }
            let body = after[..<semicolon]
            let decoded: String?
            if body.hasPrefix("#x") || body.hasPrefix("#X") {
                decoded = UInt32(body.dropFirst(2), radix: 16)
                    .flatMap(Unicode.Scalar.init).map { String(Character($0)) }
            } else if body.hasPrefix("#") {
                decoded = UInt32(body.dropFirst(1))
                    .flatMap(Unicode.Scalar.init).map { String(Character($0)) }
            } else {
                decoded = named[String(body)]
            }
            if let decoded {
                out += decoded
                rest = after[after.index(after: semicolon)...]
            } else {
                out.append("&")
                rest = after
            }
        }
        out += rest
        return out
    }

    nonisolated public static func unescape(string: String, strict: Bool) -> String {
        unescape(string)
    }

    nonisolated public static func escape(_ string: String) -> String {
        var out = ""
        for character in string {
            switch character {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            default: out.append(character)
            }
        }
        return out
    }
}

// MARK: - Selector

/// `tag`, `.class`, `#id`, `[attr]`, `:not(.class)`, in any combination
/// without spaces. Anything else matches nothing, loudly enough: the app's
/// walk then sees the untouched tree rather than a wrong subset.
nonisolated struct Selector {
    var tag: String?
    var classes: [String] = []
    var id: String?
    var attributes: [String] = []
    var notClasses: [String] = []

    init(_ text: String) {
        var rest = Substring(text)
        func takeName() -> String {
            let name = rest.prefix { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
            rest = rest.dropFirst(name.count)
            return String(name).lowercased()
        }
        if let first = rest.first, first.isLetter || first == "*" {
            if first == "*" { rest = rest.dropFirst() } else { tag = takeName() }
        }
        while let first = rest.first {
            switch first {
            case ".":
                rest = rest.dropFirst()
                classes.append(takeName())
            case "#":
                rest = rest.dropFirst()
                id = takeName()
            case "[":
                rest = rest.dropFirst()
                let name = takeName()
                if let close = rest.firstIndex(of: "]") { rest = rest[rest.index(after: close)...] }
                attributes.append(name)
            case ":":
                rest = rest.dropFirst()
                let pseudo = takeName()
                if pseudo == "not", rest.hasPrefix("(.") {
                    rest = rest.dropFirst(2)
                    notClasses.append(takeName())
                    if rest.hasPrefix(")") { rest = rest.dropFirst() }
                } else {
                    tag = "\u{0}"  // an unsupported pseudo class: match nothing
                    return
                }
            default:
                tag = "\u{0}"
                return
            }
        }
    }

    func matches(_ element: Element) -> Bool {
        if let tag, tag != element.tagName() { return false }
        if let id, element.id() != id { return false }
        for name in classes where !element.hasClass(name) { return false }
        for name in notClasses where element.hasClass(name) { return false }
        for name in attributes where !element.hasAttr(name) { return false }
        return true
    }
}

// MARK: - Parser

nonisolated struct Parser {
    static let voidTags: Set<String> = [
        "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta",
        "param", "source", "track", "wbr",
    ]
    /// An open one of these closes when another of the same family opens.
    static let autoClosing: Set<String> = ["p", "li", "dt", "dd", "option", "tr", "td", "th"]

    private let source: String

    init(_ html: String) { source = html }

    func document() -> Document {
        let root = Document()
        var open: [Element] = [root]
        var text = Substring(source)
        var pendingText = ""

        func flushText() {
            guard !pendingText.isEmpty else { return }
            open.last!.appendChild(TextNode(pendingText))
            pendingText = ""
        }

        while !text.isEmpty {
            guard text.first == "<" else {
                let next = text.dropFirst().firstIndex(of: "<") ?? text.endIndex
                pendingText += text[..<next]
                text = text[next...]
                continue
            }
            if text.hasPrefix("<!--") {
                flushText()
                let closing = text.range(of: "-->")
                let body = text.dropFirst(4).prefix(upTo: closing?.lowerBound ?? text.endIndex)
                open.last!.appendChild(Comment(String(body)))
                text = text[(closing?.upperBound ?? text.endIndex)...]
                continue
            }
            if text.hasPrefix("<!") || text.hasPrefix("<?") {
                let end = text.firstIndex(of: ">").map { text.index(after: $0) } ?? text.endIndex
                text = text[end...]
                continue
            }
            guard let close = text.firstIndex(of: ">") else {
                pendingText += text
                break
            }
            let inside = text[text.index(after: text.startIndex)..<close]
            text = text[text.index(after: close)...]
            if inside.hasPrefix("/") {
                flushText()
                let name = String(inside.dropFirst().prefix { !$0.isWhitespace }).lowercased()
                if let index = open.lastIndex(where: { $0.tagName() == name }), index > 0 {
                    open.removeSubrange(index...)
                }
                continue
            }
            var tagText = inside
            let selfClosing = tagText.hasSuffix("/")
            if selfClosing { tagText = tagText.dropLast() }
            let name = String(tagText.prefix { !$0.isWhitespace && $0 != "/" }).lowercased()
            guard let lead = name.first, lead.isLetter else {
                pendingText += "<" + inside + ">"
                continue
            }
            flushText()
            if Parser.autoClosing.contains(name),
               let last = open.last, last.tagName() == name, open.count > 1 {
                open.removeLast()
            }
            let element = Element(tag: name)
            element.attributesStorage = Parser.attributes(in: tagText.dropFirst(name.count))
            open.last!.appendChild(element)
            if !selfClosing && !Parser.voidTags.contains(name) {
                open.append(element)
            }
        }
        flushText()
        return root
    }

    /// `key="value"`, `key='value'`, `key=value` and bare `key`.
    static func attributes(in text: Substring) -> [(key: String, value: String)] {
        var out: [(key: String, value: String)] = []
        var rest = text
        while true {
            rest = rest.drop { $0.isWhitespace }
            guard !rest.isEmpty else { break }
            let key = rest.prefix { !$0.isWhitespace && $0 != "=" && $0 != "/" }
            rest = rest.dropFirst(key.count)
            guard !key.isEmpty else { rest = rest.dropFirst(); continue }
            rest = rest.drop { $0.isWhitespace }
            var value = ""
            if rest.first == "=" {
                rest = rest.dropFirst().drop { $0.isWhitespace }
                if let quote = rest.first, quote == "\"" || quote == "'" {
                    rest = rest.dropFirst()
                    let end = rest.firstIndex(of: quote) ?? rest.endIndex
                    value = String(rest[..<end])
                    rest = end < rest.endIndex ? rest[rest.index(after: end)...] : rest[end...]
                } else {
                    let bare = rest.prefix { !$0.isWhitespace }
                    value = String(bare)
                    rest = rest.dropFirst(bare.count)
                }
            }
            out.append((String(key).lowercased(), value))
        }
        return out
    }
}
