// Preview adapter for BackgroundTasks. Registration and submission succeed,
// but no background work is scheduled on the preview host.

import Foundation

open class BGTask: @unchecked Sendable {
    public var expirationHandler: (() -> Void)?
    public init() {}
    public func setTaskCompleted(success: Bool) {}
}

open class BGAppRefreshTask: BGTask, @unchecked Sendable {}

open class BGTaskRequest: @unchecked Sendable {
    public let identifier: String
    public var earliestBeginDate: Date?

    public init(identifier: String) {
        self.identifier = identifier
    }
}

public final class BGAppRefreshTaskRequest: BGTaskRequest, @unchecked Sendable {}

public final class BGTaskScheduler: @unchecked Sendable {
    public static let shared = BGTaskScheduler()

    public init() {}

    @discardableResult
    public func register(
        forTaskWithIdentifier identifier: String,
        using queue: DispatchQueue?,
        launchHandler: @escaping (BGTask) -> Void
    ) -> Bool {
        true
    }

    public func submit(_ taskRequest: BGTaskRequest) throws {}
    public func cancel(taskRequestWithIdentifier identifier: String) {}
    public func cancelAllTaskRequests() {}
}
