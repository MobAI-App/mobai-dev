// Preview adapter for WishKit. Configuration remains constructible and the
// feedback list renders empty because the preview host has no WishKit account.

import SwiftUI

open class FeedbackListView: @unchecked Sendable {
    nonisolated public init() {}
}

open class WishKit: @unchecked Sendable {
    nonisolated public init() {}

    /// Member lookup resolves here when the WishKit type shadows its module.
    nonisolated public static func FeedbackListView() -> some View {
        EmptyView()
    }
}
