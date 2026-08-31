// Preview adapter for SwipeActions. It renders the content in its closed state;
// action labels and callbacks remain constructible for application code.

import SwiftUI

public enum SwipeState: Sendable {
    case closed
    case expanded
}

public struct SwipeContext {
    public let state: Binding<SwipeState>

    public init(state: Binding<SwipeState>) {
        self.state = state
    }
}

public enum SwipeActionsStyle: Sendable {
    case mask
    case equalWidths
    case cascade
}

public enum SwipeDragGesturePriority: Sendable {
    case normal
    case high
    case simultaneous
}

public struct SwipeView<Content: View, LeadingActions: View, TrailingActions: View>: View {
    private let content: Content

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder leadingActions: (SwipeContext) -> LeadingActions,
        @ViewBuilder trailingActions: (SwipeContext) -> TrailingActions
    ) {
        self.content = content()
    }

    public var body: some View { content }
}

public struct SwipeViewGroup<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View { content }
}

public struct SwipeAction<Label: View, Background: View>: View {
    private let action: () -> Void
    private let label: (Bool) -> Label
    private let background: (Bool) -> Background

    public init(
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping (Bool) -> Label,
        @ViewBuilder background: @escaping (Bool) -> Background
    ) {
        self.action = action
        self.label = label
        self.background = background
    }

    public var body: some View {
        label(false)
            .background { background(false) }
            .onTapGesture(perform: action)
    }
}

public extension SwipeAction where Label == Image, Background == Color {
    init(
        systemImage: String,
        backgroundColor: Color = Color.primary.opacity(0.1),
        action: @escaping () -> Void
    ) {
        self.init(action: action) { _ in
            Image(systemName: systemImage)
        } background: { _ in
            backgroundColor
        }
    }

    func allowSwipeToTrigger() -> Self { self }
}

public extension View {
    func swipeSpacing(_ spacing: CGFloat) -> some View { self }
    func swipeActionsStyle(_ style: SwipeActionsStyle) -> some View { self }
    func swipeMinimumDistance(_ distance: CGFloat) -> some View { self }
    func swipeDragGesturePriority(_ priority: SwipeDragGesturePriority) -> some View { self }
}
