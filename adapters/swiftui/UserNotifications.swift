//
//  UserNotifications.swift
//  Hand-written stand-in. The REAL framework was tried first and cannot
//  serve a preview: +[UNUserNotificationCenter currentNotificationCenter]
//  throws NSInternalInconsistencyException ("bundleProxyForCurrentProcess
//  is nil") in any process that is not an app bundle, which a preview
//  binary is not. A preview must not touch the developer's notification
//  permissions anyway, so everything here is inert on purpose.
//

import Foundation

nonisolated public struct UNAuthorizationOptions: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let alert = UNAuthorizationOptions(rawValue: 1 << 0)
    public static let sound = UNAuthorizationOptions(rawValue: 1 << 1)
    public static let badge = UNAuthorizationOptions(rawValue: 1 << 2)
    public static let provisional = UNAuthorizationOptions(rawValue: 1 << 3)
}

nonisolated public struct UNNotificationPresentationOptions: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let banner = UNNotificationPresentationOptions(rawValue: 1 << 0)
    public static let sound = UNNotificationPresentationOptions(rawValue: 1 << 1)
    public static let badge = UNNotificationPresentationOptions(rawValue: 1 << 2)
    public static let list = UNNotificationPresentationOptions(rawValue: 1 << 3)
}

/// Deliberately empty: the app's delegate methods then stay plain methods
/// and no signature written here can drift out of step with the app's.
/// Nothing in a preview delivers a notification, so nothing calls them.
public protocol UNUserNotificationCenterDelegate: AnyObject {}

// No Sendable conformance on the classes below: apps declare
// `@unchecked @retroactive Sendable` on the real types,
// and a conformance here would collide with exactly that line.

nonisolated open class UNNotificationContent {
    nonisolated public init() {}
    nonisolated public var userInfo: [AnyHashable: Any] { [:] }
}

nonisolated open class UNNotificationRequest {
    nonisolated public init() {}
    nonisolated public var content: UNNotificationContent { UNNotificationContent() }
}

nonisolated open class UNNotification {
    nonisolated public init() {}
    nonisolated public var request: UNNotificationRequest { UNNotificationRequest() }
}

nonisolated open class UNNotificationResponse {
    nonisolated public init() {}
    nonisolated public var notification: UNNotification { UNNotification() }
}

nonisolated open class UNUserNotificationCenter {
    nonisolated(unsafe) static let sharedCenter = UNUserNotificationCenter()
    nonisolated public static func current() -> UNUserNotificationCenter { sharedCenter }
    nonisolated(unsafe) public weak var delegate: (any UNUserNotificationCenterDelegate)?
    /// Never answers. The authorization dialog belongs to a device, and the
    /// completion registering for remote notifications must not run here.
    nonisolated public func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping @Sendable (Bool, (any Error)?) -> Void
    ) {}
    nonisolated public func setBadgeCount(
        _ newBadgeCount: Int, withCompletionHandler: (@Sendable ((any Error)?) -> Void)? = nil
    ) {}
}
