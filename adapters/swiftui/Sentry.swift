// Stand-in for Sentry: crash reporting and tracing with nothing behind it.
// Application telemetry glue compiles and every call is a no-op, which is
// what a still preview wants from an SDK that phones home.
import SwiftUI

public enum SentrySDK {
    public static func start(configureOptions: (Options) -> Void) {
        configureOptions(Options())
    }
    public static func capture(error: Error) {}
    public static func capture(message: String) {}
    @discardableResult
    public static func startTransaction(name: String, operation: String) -> Span { Span() }
    public static var isEnabled: Bool { false }
    public static func close() {}
}

public final class Options: @unchecked Sendable {
    public init() {}
    public var dsn: String? = nil
    public var debug = false
    public var tracesSampleRate: NSNumber? = nil
    public var profilesSampleRate: NSNumber? = nil
    public var enableAutoSessionTracking = false
    public var enableWatchdogTerminationTracking = false
    public var attachScreenshot = false
    public var beforeSend: ((Event) -> Event?)? = nil
}

public final class Event: @unchecked Sendable {
    public init() {}
}

/// Sentry's tracing span, non-generic exactly like the SDK's protocol; a
/// generic guess here read as `Span<...>` at call sites and failed.
public final class Span: @unchecked Sendable {
    public init() {}
    public func finish() {}
    public func setTag(value: String, key: String) {}
    @discardableResult
    public func startChild(operation: String, description: String? = nil) -> Span { Span() }
}
