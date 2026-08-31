//
//  NukeUI.swift
//  Hand-written stand-in; the request types live in Nuke.swift beside it.
//
//  `LazyImage` runs the app's own content closure with an empty state, so the
//  placeholder branch the app wrote is what draws - real code, real layout,
//  no invented pixels.
//

import Foundation
import SwiftUI
// The request and state types live in the Nuke stand-in, and a mock module
// sees a sibling only through a real import: the engine derives cross-module
// dependencies from these lines.
import Nuke

public struct LazyImage<Content: View>: View {
    private let content: (LazyImageState) -> Content
    private let url: URL?

    public init(request: Any?, @ViewBuilder content: @escaping (LazyImageState) -> Content) {
        self.content = content
        self.url = (request as? ImageRequest)?.url
    }

    // `transaction:` accepted and unused: the stand-in swaps no phases, so
    // there is no animation to attach it to.
    public init(
        url: URL?, transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (LazyImageState) -> Content
    ) {
        self.content = content
        self.url = url
    }

    // The app's placeholder branch draws (real layout); the overlay registers
    // the URL so a paint host with a real image stack fetches and draws the
    // pixels over it, which is the sequence a device shows.
    public var body: some View {
        content(LazyImageState()).overlay(PreviewRemoteImage(url: url))
    }

    /// Accepted and dropped: processing applies to pixels, and there are none.
    public func processors(_ processors: [ImageProcessors.Resize]) -> Self { self }
    public func priority(_ priority: Any) -> Self { self }
    public func pipeline(_ pipeline: ImagePipeline) -> Self { self }
}
