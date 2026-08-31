//
//  Nuke.swift
//  Hand-written stand-in for Nuke, kept because the real library cannot build
//  against this engine's SwiftUI shim. Covers requests and processors here;
//  view types live in NukeUI.swift.
//
//  WHAT IS HONEST: a request carries its URL and is never loaded; a state
//  reports no image, so every screen shows its own placeholder branch, which
//  is real app code drawing a real app state.
//

import Foundation
import SwiftUI

public enum ImageProcessors {
    /// A resize processor. The static
    /// `.resize(size:)` spelling below is how call sites build it.
    public struct Resize: @unchecked Sendable {
        public let size: CGSize
        public init(size: CGSize) { self.size = size }
        public static func resize(size: CGSize) -> Resize { Resize(size: size) }
    }
}

open class ImageRequest: @unchecked Sendable {
    public let url: URL?
    public init(url: URL? = nil, processors: [ImageProcessors.Resize] = []) {
        self.url = url
    }
}

/// What a loaded GIF hands back; previews have none, so `data` is nil and the
/// GIF branch never runs.
public final class ImageContainer: @unchecked Sendable {
    public enum ImageType: Sendable { case gif, jpeg, png, webp }
    public var type: ImageType?
    public var data: Data?
    public init() {}
}

public final class LazyImageState: @unchecked Sendable {
    public init() {}
    public var image: Image? { nil }
    // A CONTAINER with no image, not nil: apps branch on the container
    // first (`if let container = state.imageContainer`), and nil renders
    // NOTHING. The empty container walks the application into its
    // own placeholder branch, which draws the bordered box it designed.
    public var imageContainer: ImageContainer? { ImageContainer() }
    public var isLoading: Bool { false }
    public var error: Error? { nil }
}

open class ImagePipeline: @unchecked Sendable {
    nonisolated(unsafe) public static let shared = ImagePipeline()
    // nonisolated: mocks compile under the app package's mirrored MainActor
    // default, and a static let cannot call an isolated init.
    nonisolated public init(_ configuration: Any? = nil) {}

    /// The cache MediaUI reads saved images back out of. Empty here, which is
    /// true: nothing was ever fetched.
    public struct Cache: Sendable {
        public func cachedData(for request: ImageRequest) -> Data? { nil }
        public func removeAll() {}
    }
    nonisolated public var cache: Cache { Cache() }
}
