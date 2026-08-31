//
//  AVFoundation.swift
//  Preview adapter for the AVFoundation surface used by media-export screens.
//
//  WHAT IS REAL: `UTType`. The SDK's UniformTypeIdentifiers is re-exported
//  below, exactly as real AVFoundation carries it, so `UTType.jpeg` in a file
//  that imports only AVFoundation means Apple's type with Apple's identifiers.
//  Nothing here declares a second UTType - or a second FileRepresentation or
//  ReceivedTransferredFile, which the real CoreTransferable already provides -
//  because a same-named twin makes every use ambiguous.
//
//  WHAT IS NOT: media. A headless preview cannot transcode video, so
//  `AVAssetExportSession` declines to construct (its init returns nil) and the
//  app takes its own "could not compress" path, which is the honest one.
//

import Foundation
import SwiftUI
#if canImport(UniformTypeIdentifiers)
  @_exported import UniformTypeIdentifiers
#endif

/// Preset names are String constants, matching the SDK declarations.
public let AVAssetExportPreset1280x720 = "AVAssetExportPreset1280x720"
public let AVAssetExportPreset1920x1080 = "AVAssetExportPreset1920x1080"

nonisolated open class AVURLAsset: @unchecked Sendable {
  public let url: URL
  nonisolated public init(url: URL, options: [String: Any]? = nil) { self.url = url }
}

nonisolated public struct AVFileType: Sendable, Equatable {
  let raw: String
  public static let mp4 = AVFileType(raw: "public.mpeg-4")
}

/// Declines to construct. Real export needs an encoder this preview does not
/// have; returning nil sends the caller down its own failure branch instead
/// of pretending a transcode happened.
nonisolated open class AVAssetExportSession: @unchecked Sendable {
  public var outputURL: URL?
  public var outputFileType: AVFileType?
  public var shouldOptimizeForNetworkUse = false
  nonisolated public init?(asset: AVURLAsset, presetName: String) { return nil }
  nonisolated public func export(to url: URL, as fileType: AVFileType) async throws {}
}

/// Named but inert because image extraction requires a media decoder.
nonisolated open class AVAssetImageGenerator: @unchecked Sendable {
  nonisolated public init() {}
}
