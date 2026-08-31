//
//  AVKit.swift
//  Hand-written stand-in. A headless preview has no playback stack, so a
//  player here holds its settings and does nothing, and `VideoPlayer` draws a
//  labelled dark rectangle - visibly a video slot, never a fake frame.
//

import Foundation
import SwiftUI

open class AVPlayerItem: @unchecked Sendable {
    public init(url: URL) {}
}

open class AVPlayer: @unchecked Sendable {
    public enum AudiovisualBackgroundPlaybackPolicy: Sendable {
        case automatic, pauses, continuesIfPossible
    }

    nonisolated public init() {}
    nonisolated public init(url: URL) {}

    nonisolated(unsafe) public var isMuted: Bool = false
    nonisolated(unsafe) public var audiovisualBackgroundPlaybackPolicy:
        AudiovisualBackgroundPlaybackPolicy = .automatic
    nonisolated(unsafe) public var preventsDisplaySleepDuringVideoPlayback = true
    nonisolated public var currentItem: AVPlayerItem? { nil }

    nonisolated public func play() {}
    nonisolated public func pause() {}
    nonisolated public func seek(to time: CMTime) {}
}

public struct CMTime: Sendable {
    nonisolated(unsafe) public static let zero = CMTime()
    nonisolated public init() {}
}

extension Notification.Name {
    /// Never posted: nothing here ever finishes playing.
    nonisolated(unsafe) public static let AVPlayerItemDidPlayToEndTime =
        Notification.Name("MobAIPreview.AVPlayerItemDidPlayToEndTime")
}

/// The audio session a video view configures around playback. Every call is
/// taken and dropped: there is no audio route here to duck or deactivate.
public final class AVAudioSession: @unchecked Sendable {
    // Every static and init below is explicitly nonisolated, matching the
    // real API. These compile under the app package's mirrored
    // `defaultIsolation(MainActor)`, which isolates stored statics - and the
    // app reads them from inside a `@Sendable` Dispatch closure, which under
    // v6 inherits no isolation. One isolated member in that closure and
    // overload resolution collapses to the DispatchWorkItem overload, whose
    // error names none of this.
    public struct Category: Sendable {
        nonisolated public init() {}
        nonisolated(unsafe) public static let playback = Category()
        nonisolated(unsafe) public static let ambient = Category()
    }
    public struct CategoryOptions: OptionSet, Sendable {
        public let rawValue: Int
        nonisolated public init(rawValue: Int) { self.rawValue = rawValue }
        nonisolated(unsafe) public static let duckOthers = CategoryOptions(rawValue: 1)
        nonisolated(unsafe) public static let mixWithOthers = CategoryOptions(rawValue: 2)
    }
    public struct SetActiveOptions: OptionSet, Sendable {
        public let rawValue: Int
        nonisolated public init(rawValue: Int) { self.rawValue = rawValue }
        nonisolated(unsafe) public static let notifyOthersOnDeactivation =
            SetActiveOptions(rawValue: 1)
    }

    nonisolated(unsafe) private static let single = AVAudioSession()
    // nonisolated explicitly, like the real API: the app configures its audio
    // session from a background Dispatch closure, and mocks compile under the
    // mirrored MainActor default - isolated methods here made that closure
    // fail overload resolution with an error about DispatchWorkItem.
    nonisolated public static func sharedInstance() -> AVAudioSession { single }

    nonisolated public func setActive(
        _ active: Bool, options: SetActiveOptions = []) throws {}
    nonisolated public func setCategory(
        _ category: Category, options: CategoryOptions = []) throws {}
}

/// The one AVKit VIEW these screens use. A dark plate with a play glyph:
/// unmistakably "a video goes here", and unmistakably not playing. The
/// app's own overlay closure RUNS and draws on top, because that overlay is
/// real screen code (mute buttons, duration labels) worth seeing.
public struct VideoPlayer<Overlay: View>: View {
    private let overlay: Overlay

    public init(player: AVPlayer?, @ViewBuilder videoOverlay: () -> Overlay) {
        self.overlay = videoOverlay()
    }

    public var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.12)
            Text("\u{25B6}")
                .font(.system(size: 34.0))
                .foregroundColor(Color(white: 0.85))
            overlay
        }
    }
}

extension VideoPlayer where Overlay == EmptyView {
    public init(player: AVPlayer?) {
        self.init(player: player, videoOverlay: { EmptyView() })
    }
}
