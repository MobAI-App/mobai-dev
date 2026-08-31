// Preview adapter for Bodega. Reads are empty, writes and removals succeed
// without persistence, and the exposed storage directory is temporary.

import Foundation

open class Directory: @unchecked Sendable {
    nonisolated public init() {}
}

open class SQLiteStorageEngine: @unchecked Sendable {
    nonisolated public init() {}

    nonisolated public static func `default`(
        appendingPath: String
    ) -> SQLiteStorageEngine {
        SQLiteStorageEngine()
    }

    nonisolated public func removeAllData() async throws {}
    nonisolated public func write(_ items: [(CacheKey, Data)]) async throws {}
    nonisolated public func readAllData() async -> [Data] { [] }

    // Compatibility fallbacks for package versions with additional arguments.
    @discardableResult
    nonisolated public func allKeys(_ arguments: Any...) -> [SQLiteStorageEngine] { [] }

    @discardableResult
    nonisolated public func removeAllData(
        _ arguments: Any...
    ) -> SQLiteStorageEngine { self }

    @discardableResult
    nonisolated public func write(_ arguments: Any...) -> SQLiteStorageEngine { self }

    @discardableResult
    nonisolated public func readAllData(
        _ arguments: Any...
    ) -> SQLiteStorageEngine { self }
}

open class CacheKey: @unchecked Sendable {
    nonisolated public init() {}

    nonisolated public convenience init(_ arguments: Any...) {
        self.init()
    }
}

// Bodega exposes its directory helper under Foundation's FileManager.
extension FileManager {
    public final class Directory: @unchecked Sendable {
        nonisolated public init() {}

        nonisolated public var url: URL {
            URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("bodega")
        }

        nonisolated public static func defaultStorageDirectory(
            appendingPath: String
        ) -> Directory {
            Directory()
        }
    }
}
