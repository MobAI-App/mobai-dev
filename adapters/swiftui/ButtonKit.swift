//
//  ButtonKit.swift
//  Hand-written stand-in. The real library cannot build for this host, and
//  its surface is small: a Button whose action is async and throwing.
//
//  WHAT IS HONEST: the label is the app's own view and DRAWS; a tap runs the
//  app's real async action on the main actor, so a preview that follows an
//  account exercises the app's actual code path. Errors are swallowed the way
//  the library swallows them into its error styles, which this engine cannot
//  draw.
//

import Foundation
import SwiftUI

public struct AsyncButton<Label: View>: View {
    private let action: () async throws -> Void
    private let label: Label

    public init(
        action: @escaping () async throws -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
    }

    public var body: some View {
        let run = action
        Button {
            Task { @MainActor in try? await run() }
        } label: {
            label
        }
    }
}

/// `.asyncButtonStyle(.none)` and friends: presentation of in-flight and
/// failed states, which a still frame does not have.
public struct AsyncButtonStyle: Sendable {
    public static let none = AsyncButtonStyle()
    public static let overlay = AsyncButtonStyle()
    public static let pulse = AsyncButtonStyle()
}

extension View {
    public func asyncButtonStyle(_ style: AsyncButtonStyle) -> some View { self }
    public func throwableButtonStyle(_ style: Any) -> some View { self }
    /// Tunables the library exposes; nothing here is in flight to tune.
    public func disabledWhenLoading(_ flag: Bool = true) -> some View { self }
    public func allowsHitTestingWhenLoading(_ flag: Bool = true) -> some View { self }
}
