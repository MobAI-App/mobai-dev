//
//  TelemetryDeck.swift
//  Hand-written stand-in. Analytics has no business firing from a preview,
//  so every call is taken and dropped - which is not a compromise, it is the
//  correct behaviour: a preview session is not usage.
//
//  Top-level declarations on purpose: the app writes `TelemetryDeck.Config`
//  and `TelemetryDeck.initialize`, module-qualified. A namespace type of the
//  module's own name would swallow those references.
//

import Foundation

nonisolated public final class Config: @unchecked Sendable {
    nonisolated public init(appID: String) {}
    nonisolated(unsafe) public var defaultSignalPrefix: String?
    nonisolated(unsafe) public var defaultParameterPrefix: String?
    nonisolated(unsafe) public var testMode: Bool = false
}

nonisolated public func initialize(config: Config) {}

nonisolated public func signal(
    _ name: String, parameters: [String: String] = [:]
) {}
