// Preview adapter for SFSafeSymbols. It preserves the RawRepresentable symbol
// API, the SwiftUI and UIKit initializers the library adds, and a small
// deterministic inventory for icon pickers without shipping Apple's generated
// symbol catalogue.
//
// The library declares one static per symbol (`.line3HorizontalDecrease`,
// thousands of them). This file declares none: the engine appends each one
// the app actually names, as `SFSymbol(rawValue: "line3HorizontalDecrease")`,
// and `init(rawValue:)` turns that camel-case spelling into the symbol's
// real name ("line.3.horizontal.decrease"), which is what the preview draws.

import Foundation
import SwiftUI

public struct SFSymbol: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = SFSymbol.symbolName(from: rawValue)
    }

    /// The symbol's real name for a camel-case spelling ("line3HorizontalDecrease"
    /// is "line.3.horizontal.decrease"); a dotted name is returned as it is.
    public static func symbolName(from spelling: String) -> String {
        guard !spelling.contains("."), spelling.contains(where: { $0.isUppercase || $0.isNumber }) else {
            return spelling
        }
        var out = ""
        var previous: Character = " "
        for character in spelling {
            if character.isUppercase {
                out.append(".")
                out.append(Character(character.lowercased()))
            } else if character.isNumber, !previous.isNumber {
                out.append(".")
                out.append(character)
            } else if !character.isNumber, previous.isNumber {
                out.append(".")
                out.append(character)
            } else {
                out.append(character)
            }
            previous = character
        }
        return out
    }

    public static let allSymbols: [SFSymbol] = [
        "tag", "tag.fill", "globe", "number", "person.2", "person.2.fill",
        "swift", "bubble.left", "bubble.left.fill", "star", "star.fill",
        "bookmark", "bookmark.fill", "heart", "heart.fill", "bell", "bell.fill"
    ].map(SFSymbol.init(rawValue:))
}

extension Image {
    public init(systemSymbol: SFSymbol) {
        self.init(systemName: systemSymbol.rawValue)
    }
}

extension Label where Title == Text, Icon == Image {
    public init(_ titleKey: LocalizedStringKey, systemSymbol: SFSymbol) {
        self.init(titleKey, systemImage: systemSymbol.rawValue)
    }

    public init<S: StringProtocol>(_ title: S, systemSymbol: SFSymbol) {
        self.init(String(title), systemImage: systemSymbol.rawValue)
    }
}

#if canImport(UIKit)
import UIKit

extension UIImage {
    public convenience init?(systemSymbol: SFSymbol) {
        self.init(systemName: systemSymbol.rawValue)
    }
}
#endif
