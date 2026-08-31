// Preview adapter for NaturalLanguage. Recognition returns no hypotheses so
// applications retain their own unknown-language or default state.

import Foundation

nonisolated public struct NLLanguage: Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let english = NLLanguage(rawValue: "en")
    public static let undetermined = NLLanguage(rawValue: "und")
}

nonisolated public final class NLLanguageRecognizer {
    nonisolated public init() {}
    nonisolated public func processString(_ string: String) {}
    nonisolated public func languageHypotheses(withMaximum maxHypotheses: Int) -> [NLLanguage: Double] { [:] }
    nonisolated public var dominantLanguage: NLLanguage? { nil }
    nonisolated public func reset() {}
}
