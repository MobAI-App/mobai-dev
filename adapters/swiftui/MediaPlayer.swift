// Preview adapter for MediaPlayer. Now Playing state is retained in memory and
// remote commands accept registrations but are never triggered by the host.

import Foundation
import SwiftUI

public let MPMediaItemPropertyTitle = "title"
public let MPMediaItemPropertyArtist = "artist"
public let MPMediaItemPropertyArtwork = "artwork"
public let MPMediaItemPropertyMediaType = "mediaType"
public let MPMediaItemPropertyPlaybackDuration = "duration"
public let MPNowPlayingInfoPropertyDefaultPlaybackRate = "defaultPlaybackRate"
public let MPNowPlayingInfoPropertyElapsedPlaybackTime = "elapsedPlaybackTime"
public let MPNowPlayingInfoPropertyIsLiveStream = "isLiveStream"
public let MPNowPlayingInfoPropertyPlaybackQueueCount = "playbackQueueCount"
public let MPNowPlayingInfoPropertyPlaybackQueueIndex = "playbackQueueIndex"
public let MPNowPlayingInfoPropertyPlaybackRate = "playbackRate"

public struct MPMediaType: RawRepresentable, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let anyVideo = MPMediaType(rawValue: 0x1ff00)
}

public enum MPNowPlayingPlaybackState: Sendable {
    case unknown, playing, paused, stopped, interrupted
}

public final class MPMediaItemArtwork: @unchecked Sendable {
    public init<Image>(boundsSize: CGSize, requestHandler: @escaping (CGSize) -> Image) {}
}

public final class MPNowPlayingInfoCenter: @unchecked Sendable {
    private static let instance = MPNowPlayingInfoCenter()
    public static func `default`() -> MPNowPlayingInfoCenter { instance }

    public var nowPlayingInfo: [String: Any]?
    public var playbackState: MPNowPlayingPlaybackState = .unknown
}

open class MPRemoteCommandEvent: @unchecked Sendable {
    public init() {}
}

public final class MPSkipIntervalCommandEvent: MPRemoteCommandEvent, @unchecked Sendable {
    public var interval: TimeInterval = 0
}

public final class MPChangePlaybackPositionCommandEvent: MPRemoteCommandEvent, @unchecked Sendable {
    public var positionTime: TimeInterval = 0
}

public enum MPRemoteCommandHandlerStatus: Sendable {
    case success, noSuchContent, noActionableNowPlayingItem, deviceNotFound, commandFailed
}

open class MPRemoteCommand: @unchecked Sendable {
    public var isEnabled = false
    public init() {}

    @discardableResult
    public func addTarget(
        handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    ) -> Any {
        UUID()
    }

    public func removeTarget(_ target: Any?) {}
}

public final class MPSkipIntervalCommand: MPRemoteCommand, @unchecked Sendable {
    public var preferredIntervals: [NSNumber] = []
}

public final class MPRemoteCommandCenter: @unchecked Sendable {
    private static let instance = MPRemoteCommandCenter()
    public static func shared() -> MPRemoteCommandCenter { instance }

    public let playCommand = MPRemoteCommand()
    public let pauseCommand = MPRemoteCommand()
    public let togglePlayPauseCommand = MPRemoteCommand()
    public let nextTrackCommand = MPRemoteCommand()
    public let previousTrackCommand = MPRemoteCommand()
    public let changePlaybackPositionCommand = MPRemoteCommand()
    public let skipForwardCommand = MPSkipIntervalCommand()
    public let skipBackwardCommand = MPSkipIntervalCommand()
}
