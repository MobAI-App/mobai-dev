// Preview adapter for RevenueCat. The store is deliberately empty: there are
// no products or active entitlements, purchases read as cancelled, and restore
// returns the same empty customer information.

import Foundation

public enum LogLevel: Sendable {
    case error
}

public struct StoreProduct: Hashable, Identifiable, Sendable {
    public let productIdentifier: String
    public let price: Decimal
    public let localizedPriceString: String

    public var id: String { productIdentifier }

    public init(
        productIdentifier: String = "",
        price: Decimal = 0,
        localizedPriceString: String = ""
    ) {
        self.productIdentifier = productIdentifier
        self.price = price
        self.localizedPriceString = localizedPriceString
    }
}

public struct EntitlementInfo: Hashable, Sendable {
    public let isActive: Bool

    public init(isActive: Bool = false) {
        self.isActive = isActive
    }
}

public struct EntitlementInfos: Sendable {
    public let active: [String: EntitlementInfo]

    public init(active: [String: EntitlementInfo] = [:]) {
        self.active = active
    }

    public subscript(identifier: String) -> EntitlementInfo? {
        active[identifier]
    }
}

public struct CustomerInfo: Sendable {
    public let entitlements: EntitlementInfos

    public init(entitlements: EntitlementInfos = EntitlementInfos()) {
        self.entitlements = entitlements
    }
}

public struct PurchaseResultData: Sendable {
    public let customerInfo: CustomerInfo
    public let userCancelled: Bool

    public init(customerInfo: CustomerInfo = CustomerInfo(), userCancelled: Bool = true) {
        self.customerInfo = customerInfo
        self.userCancelled = userCancelled
    }
}

public final class Purchases: @unchecked Sendable {
    public static let shared = Purchases()
    nonisolated(unsafe) public static var logLevel: LogLevel = .error

    public init() {}

    public static func configure(withAPIKey apiKey: String) {}

    public func getProducts(
        _ identifiers: [String],
        completion: @escaping ([StoreProduct]) -> Void
    ) {
        completion([])
    }

    public func getCustomerInfo(
        completion: @escaping (CustomerInfo?, Error?) -> Void
    ) {
        completion(CustomerInfo(), nil)
    }

    public func restorePurchases(
        completion: @escaping (CustomerInfo?, Error?) -> Void
    ) {
        completion(CustomerInfo(), nil)
    }

    public func purchase(product: StoreProduct) async throws -> PurchaseResultData {
        PurchaseResultData()
    }
}
