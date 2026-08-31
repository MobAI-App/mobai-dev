//
//  EmojiText.swift
//  Hand-written stand-in for the EmojiText library, which cannot build for
//  this host. Hand-written of necessity: the library's main TYPE shares the
//  MODULE's name, and the generator refuses to declare that shape on purpose
//  (a type named after its module swallows every `Module.Type` reference,
//  which is how the SwiftSoup stand-in once broke a build). A person can make
//  the call; the generator cannot.
//
//  WHAT IS HONEST: the markdown renders as plain Text - the words are the
//  app's own. Custom emoji inside it draw as their shortcodes rather than as
//  fetched images, which reads as ":smile:" - visibly a stand-in, never an
//  invented picture.
//

import Foundation
import SwiftUI

public protocol CustomEmoji: Sendable {
    var shortcode: String { get }
}

public struct RemoteEmoji: CustomEmoji, Sendable {
    public let shortcode: String
    public let url: URL
    public init(shortcode: String, url: URL) {
        self.shortcode = shortcode
        self.url = url
    }
}

/// The library's main view. Markdown in, Text out.
public struct EmojiText: View {
    private let markdown: String
    private var appended: (@Sendable () -> Text)?

    public init(markdown: String, emojis: [any CustomEmoji]) {
        self.markdown = markdown
    }

    public var body: some View {
        let base = (try? AttributedString(markdown: markdown)).map(Text.init)
            ?? Text(markdown)
        if let appended {
            base + appended()
        } else {
            base
        }
    }

    /// Chainable configuration, accepted and dropped: animation and emoji
    /// sizing shape fetched images, and there are none.
    public func animated(_ value: Bool = true) -> EmojiText { self }
    public func append(text: @escaping @Sendable () -> Text) -> EmojiText {
        var copy = self
        copy.appended = text
        return copy
    }
}

/// `.emojiText.size(...)` / `.emojiText.baselineOffset(...)`, the environment
/// spelling the library adds to every view. A dot-chained pair of no-ops.
public struct EmojiTextConfiguration<Content: View> {
    let content: Content
    public func size(_ value: CGFloat?) -> Content { content }
    public func baselineOffset(_ value: CGFloat?) -> Content { content }
}

extension View {
    public var emojiText: EmojiTextConfiguration<Self> {
        EmojiTextConfiguration(content: self)
    }
}
