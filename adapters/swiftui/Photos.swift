//
//  Photos.swift
//  Hand-written stand-in, shaped by MediaPickerPanelView.swift and the
//  save-image actions. A headless preview has no photo library: access reads
//  as denied, fetches come back empty, and image requests answer nil through
//  the same callbacks the real framework uses - synchronously, because the
//  app wraps them in continuations and an unanswered continuation is a hung
//  preview. Screens show their own no-access / empty states, which is what
//  they would show on a locked-down device.
//

import Foundation
import SwiftUI

nonisolated public enum PHAuthorizationStatus: Sendable {
    case notDetermined, restricted, denied, authorized, limited
}

nonisolated public enum PHAccessLevel: Sendable {
    case addOnly, readWrite
}

nonisolated public enum PHAssetMediaType: Int, Sendable {
    case unknown = 0, image = 1, video = 2, audio = 3
}

nonisolated public enum PHImageRequestOptionsDeliveryMode: Int, Sendable {
    case opportunistic = 0, highQualityFormat = 1, fastFormat = 2
}

nonisolated public enum PHImageRequestOptionsResizeMode: Int, Sendable {
    case none = 0, fast = 1, exact = 2
}

nonisolated public enum PHImageContentMode: Int, Sendable {
    case aspectFit = 0, aspectFill = 1
}

nonisolated public final class PHPhotoLibrary: @unchecked Sendable {
    nonisolated(unsafe) static let sharedLibrary = PHPhotoLibrary()
    nonisolated public init() {}
    nonisolated public static func shared() -> PHPhotoLibrary { sharedLibrary }
    /// Denied, honestly: there is no library to grant access to, and the
    /// denied branch is a screen the app has already designed.
    nonisolated public static func authorizationStatus(
        for level: PHAccessLevel
    ) -> PHAuthorizationStatus { .denied }
    nonisolated public static func requestAuthorization(
        for level: PHAccessLevel
    ) async -> PHAuthorizationStatus { .denied }
    nonisolated public func performChanges(
        _ changeBlock: @escaping @Sendable () -> Void,
        completionHandler: (@Sendable (Bool, (any Error)?) -> Void)? = nil
    ) { completionHandler?(false, nil) }
}

/// Accepted and dropped: there is no album to write to.
nonisolated public func UIImageWriteToSavedPhotosAlbum(
    _ image: UIImage, _ completionTarget: Any?, _ completionSelector: Any?,
    _ contextInfo: Any?
) {}

nonisolated open class PHFetchOptions: @unchecked Sendable {
    nonisolated public init() {}
    nonisolated(unsafe) public var sortDescriptors: [NSSortDescriptor]?
    nonisolated(unsafe) public var fetchLimit: Int = 0
}

/// Always empty; enumerate visits nothing.
nonisolated public final class PHFetchResult<T>: @unchecked Sendable {
    nonisolated public init() {}
    nonisolated public var count: Int { 0 }
    nonisolated public func enumerateObjects(_ block: (T, Int, Bool) -> Void) {}
}

nonisolated open class PHAsset: @unchecked Sendable {
    nonisolated public init() {}
    nonisolated public var mediaType: PHAssetMediaType { .unknown }
    nonisolated public var localIdentifier: String { "" }
    nonisolated public static func fetchAssets(
        with mediaType: PHAssetMediaType, options: PHFetchOptions?
    ) -> PHFetchResult<PHAsset> { PHFetchResult() }
}

nonisolated open class PHImageRequestOptions: @unchecked Sendable {
    nonisolated public init() {}
    nonisolated(unsafe) public var isNetworkAccessAllowed = false
    nonisolated(unsafe) public var isSynchronous = false
    nonisolated(unsafe) public var deliveryMode: PHImageRequestOptionsDeliveryMode = .opportunistic
    nonisolated(unsafe) public var resizeMode: PHImageRequestOptionsResizeMode = .none
}

nonisolated open class PHImageManager: @unchecked Sendable {
    nonisolated(unsafe) static let sharedManager = PHImageManager()
    nonisolated public init() {}
    nonisolated public static func `default`() -> PHImageManager { sharedManager }
    /// nil, immediately, on the caller's thread: the app wraps these in
    /// checked continuations, and a callback that never comes is a hang.
    nonisolated public func requestImage(
        for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode,
        options: PHImageRequestOptions?,
        resultHandler: (UIImage?, [AnyHashable: Any]?) -> Void
    ) { resultHandler(nil, nil) }
    nonisolated public func requestImageDataAndOrientation(
        for asset: PHAsset, options: PHImageRequestOptions?,
        resultHandler: (Data?, String?, UInt32, [AnyHashable: Any]?) -> Void
    ) { resultHandler(nil, nil, 0, nil) }
}
