// Preview adapter for the KeychainSwift package: the same API over an
// in-memory store. There is no keychain in a headless preview; accounts and
// keys saved during a session live for the session.

import Foundation

nonisolated public enum KeychainSwiftAccessOptions {
  case accessibleAfterFirstUnlock
  case accessibleWhenUnlocked
  case accessibleAlways
}

nonisolated public final class KeychainSwift {
  /// One store across instances: the app constructs a fresh KeychainSwift
  /// per access and expects the platform keychain behind all of them.
  nonisolated(unsafe) private static var store: [String: Data] = [:]

  public var accessGroup: String?
  public var synchronizable: Bool = false

  public init() {}
  public init(keyPrefix: String) {}

  @discardableResult
  public func set(_ value: String, forKey key: String, withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
    Self.store[key] = Data(value.utf8)
    return true
  }

  @discardableResult
  public func set(_ value: Data, forKey key: String, withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
    Self.store[key] = value
    return true
  }

  public func get(_ key: String) -> String? {
    Self.store[key].flatMap { String(data: $0, encoding: .utf8) }
  }

  public func getData(_ key: String) -> Data? {
    Self.store[key]
  }

  @discardableResult
  public func delete(_ key: String) -> Bool {
    Self.store.removeValue(forKey: key) != nil
  }

  public var allKeys: [String] {
    Array(Self.store.keys)
  }

  @discardableResult
  public func clear() -> Bool {
    Self.store.removeAll()
    return true
  }
}
