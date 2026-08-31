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
//  WHAT IS HONEST: no parsing happens. The document holds the raw HTML and has
//  no children, so the markdown walk walks nothing and text comes out plain.
//

import Foundation

nonisolated public func parse(_ html: String) throws -> Document { Document(html) }
nonisolated public func clean(
    _ html: String, _ baseUri: String, _ whitelist: Whitelist,
    _ settings: OutputSettings
) throws -> String? { html }

nonisolated open class Node: @unchecked Sendable, CustomStringConvertible {
    nonisolated public init() {}
    nonisolated public func nodeName() -> String { "#root" }
    nonisolated public func getChildNodes() -> [Node] { [] }
    nonisolated public func attr(_ key: String) throws -> String { "" }
    /// The node's outer HTML in the real library; nothing was parsed here.
    nonisolated public var description: String { "" }
}

nonisolated public final class TextNode: Node, @unchecked Sendable {
    // Explicit: the implicit override synthesises as MainActor under the
    // mirrored default and clashes with the nonisolated base init.
    nonisolated override public init() { super.init() }
    nonisolated public func text() -> String { "" }
    nonisolated public func getWholeText() -> String { "" }
}

nonisolated public final class Element: Node, @unchecked Sendable {
    nonisolated override public init() { super.init() }
}

/// A selection: every select() finds nothing, and every mutation of nothing
/// succeeds.
nonisolated public final class Elements: @unchecked Sendable {
    nonisolated public init() {}
    nonisolated public func remove() throws {}
    nonisolated public func after(_ html: String) throws {}
    nonisolated public func text() throws -> String { "" }
    nonisolated public func array() -> [Element] { [] }
}

nonisolated public final class Document: Node, @unchecked Sendable {
    private let raw: String
    nonisolated public init(_ raw: String = "") {
        self.raw = raw
        super.init()
    }
    nonisolated public func select(_ query: String) throws -> Elements { Elements() }
    nonisolated public func html() throws -> String { raw }
    @discardableResult
    nonisolated public func outputSettings(_ settings: OutputSettings) -> Document { self }
}

nonisolated public final class OutputSettings: @unchecked Sendable {
    nonisolated public init() {}
    @discardableResult
    nonisolated public func prettyPrint(pretty: Bool) -> OutputSettings { self }
}

nonisolated public final class Whitelist: @unchecked Sendable {
    nonisolated public init() {}
    nonisolated public static func none() throws -> Whitelist { Whitelist() }
}


/// Thrown by everything below.
///
/// A stand-in has no behaviour to offer, and throwing is the only
/// way to satisfy a return type without inventing a value. At a
/// `try?` call site this becomes nil, so the screen renders empty
/// rather than wrong, and nothing crashes.
private enum SwiftSoupPreviewError: Error { case unavailable }


open class Entities: @unchecked Sendable {
    nonisolated public init() {}
}


extension Entities {
    /// Entity decoding has no honest generic fallback without parsing.
    nonisolated public static func unescape<T>(_ arguments: Any...) throws -> T {
        throw SwiftSoupPreviewError.unavailable
    }
}
