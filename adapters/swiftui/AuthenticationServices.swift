// Preview adapter for the SwiftUI web-authentication environment API. A
// preview cannot open an authentication browser, so authenticate fails with a
// typed error and lets the application render its existing failure path.

import Foundation
import SwiftUI

public enum AuthenticationSessionUnavailable: Error, Sendable {
    case preview
}

public struct WebAuthenticationSession: Sendable {
    public init() {}

    public func authenticate(
        using url: URL,
        callbackURLScheme: String
    ) async throws -> URL {
        throw AuthenticationSessionUnavailable.preview
    }
}

extension EnvironmentValues {
    public var webAuthenticationSession: WebAuthenticationSession {
        get { WebAuthenticationSession() }
        set {}
    }
}
