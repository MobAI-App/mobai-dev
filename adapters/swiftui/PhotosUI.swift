//
//  PhotosUI.swift
//  Hand-written stand-in. A headless preview has no photo library, so the
//  picker never presents and an item never loads - `loadTransferable` answers
//  nil, which is the app's own "user picked nothing yet" path.
//

import Foundation
import SwiftUI
// The library argument some call sites pass; the Photos stand-in beside
// this file declares it.
import Photos

nonisolated public struct PhotosPickerItem: Hashable, Sendable {
    public init() {}
    public func loadTransferable<T>(type: T.Type) async throws -> T? { nil }
    nonisolated(unsafe) public var itemIdentifier: String? = nil
}

nonisolated public struct PHPickerFilter: Sendable {
    nonisolated(unsafe) public static let any = PHPickerFilter()
    nonisolated(unsafe) public static let images = PHPickerFilter()
    nonisolated(unsafe) public static let videos = PHPickerFilter()
    public static func any(of filters: [PHPickerFilter]) -> PHPickerFilter { .init() }
}

extension View {
    /// Accepted and dropped: presenting a system picker needs a system.
    public func photosPicker(
        isPresented: Binding<Bool>,
        selection: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        matching filter: PHPickerFilter? = nil,
        photoLibrary: PHPhotoLibrary = .shared()
    ) -> some View { self }

    public func photosPicker(
        isPresented: Binding<Bool>,
        selection: Binding<PhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        photoLibrary: PHPhotoLibrary = .shared()
    ) -> some View { self }
}
