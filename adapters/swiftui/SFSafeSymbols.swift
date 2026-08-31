// Preview adapter for SFSafeSymbols. It preserves the RawRepresentable symbol
// API and provides a small deterministic inventory for icon pickers without
// shipping Apple's generated symbol catalogue.

import Foundation

public struct SFSymbol: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let allSymbols: [SFSymbol] = [
        "tag", "tag.fill", "globe", "number", "person.2", "person.2.fill",
        "swift", "bubble.left", "bubble.left.fill", "star", "star.fill",
        "bookmark", "bookmark.fill", "heart", "heart.fill", "bell", "bell.fill"
    ].map(SFSymbol.init(rawValue:))
}
