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

// MARK: - Audio (AVFAudio, re-exported by AVFoundation on a phone)
//
// Sound engines built on AVAudioEngine compile and stay silent: nodes
// connect, buffers allocate real sample memory so synthesis code can write
// into them, playback schedules nothing, and the session accepts every
// category. Signatures follow the SDK, failable where the SDK's are, so
// `AVAudioFormat(...)!` and `AVAudioPCMBuffer(pcmFormat:frameCapacity:)!`
// compile unchanged.

public typealias AVAudioFrameCount = UInt32
public typealias AVAudioChannelCount = UInt32
public typealias AVAudioNodeBus = Int
public typealias AVAudioFramePosition = Int64

public enum AVAudioCommonFormat: UInt, Sendable {
  case otherFormat = 0, pcmFormatFloat32 = 1, pcmFormatFloat64 = 2, pcmFormatInt16 = 3, pcmFormatInt32 = 4
}

nonisolated open class AVAudioFormat: @unchecked Sendable {
  public let sampleRate: Double
  public let channelCount: AVAudioChannelCount
  public let commonFormat: AVAudioCommonFormat
  public let isInterleaved: Bool
  public var isStandard: Bool { commonFormat == .pcmFormatFloat32 && !isInterleaved }
  nonisolated public init?(standardFormatWithSampleRate sampleRate: Double, channels: AVAudioChannelCount) {
    self.sampleRate = sampleRate
    self.channelCount = channels
    self.commonFormat = .pcmFormatFloat32
    self.isInterleaved = false
  }
  nonisolated public init?(commonFormat: AVAudioCommonFormat, sampleRate: Double, channels: AVAudioChannelCount, interleaved: Bool) {
    self.sampleRate = sampleRate
    self.channelCount = channels
    self.commonFormat = commonFormat
    self.isInterleaved = interleaved
  }
}

nonisolated open class AVAudioBuffer: @unchecked Sendable {
  public let format: AVAudioFormat
  nonisolated public init(format: AVAudioFormat) { self.format = format }
}

/// Real sample memory, so a synthesiser's writes through `floatChannelData`
/// land somewhere; nothing reads it back.
nonisolated open class AVAudioPCMBuffer: AVAudioBuffer, @unchecked Sendable {
  public let frameCapacity: AVAudioFrameCount
  public var frameLength: AVAudioFrameCount = 0
  public var stride: Int { 1 }
  private let channels: UnsafeMutablePointer<UnsafeMutablePointer<Float>>
  private let channelCount: Int
  nonisolated public init?(pcmFormat format: AVAudioFormat, frameCapacity: AVAudioFrameCount) {
    self.frameCapacity = frameCapacity
    channelCount = max(1, Int(format.channelCount))
    channels = UnsafeMutablePointer<UnsafeMutablePointer<Float>>.allocate(capacity: channelCount)
    for channel in 0..<channelCount {
      let samples = UnsafeMutablePointer<Float>.allocate(capacity: max(1, Int(frameCapacity)))
      samples.initialize(repeating: 0, count: max(1, Int(frameCapacity)))
      channels[channel] = samples
    }
    super.init(format: format)
  }
  deinit {
    for channel in 0..<channelCount { channels[channel].deallocate() }
    channels.deallocate()
  }
  public var floatChannelData: UnsafePointer<UnsafeMutablePointer<Float>>? { UnsafePointer(channels) }
  public var int16ChannelData: UnsafePointer<UnsafeMutablePointer<Int16>>? { nil }
  public var int32ChannelData: UnsafePointer<UnsafeMutablePointer<Int32>>? { nil }
}

nonisolated open class AVAudioTime: @unchecked Sendable {
  public let sampleTime: AVAudioFramePosition
  public let sampleRate: Double
  public let hostTime: UInt64
  nonisolated public init(sampleTime: AVAudioFramePosition, atRate sampleRate: Double) {
    self.sampleTime = sampleTime; self.sampleRate = sampleRate; hostTime = 0
  }
  nonisolated public init(hostTime: UInt64) { self.hostTime = hostTime; sampleTime = 0; sampleRate = 0 }
}

nonisolated open class AVAudioNode: @unchecked Sendable {
  public weak var engine: AVAudioEngine?
  public var numberOfInputs: Int { 1 }
  public var numberOfOutputs: Int { 1 }
  public var lastRenderTime: AVAudioTime? { nil }
  nonisolated public init() {}
  public func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat {
    AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
  }
  public func inputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat { outputFormat(forBus: bus) }
  public func installTap(onBus bus: AVAudioNodeBus, bufferSize: AVAudioFrameCount, format: AVAudioFormat?, block: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) {}
  public func removeTap(onBus bus: AVAudioNodeBus) {}
  public func reset() {}
}

nonisolated open class AVAudioMixerNode: AVAudioNode, @unchecked Sendable {
  public var outputVolume: Float = 1
  public var volume: Float = 1
  public var pan: Float = 0
}

nonisolated open class AVAudioOutputNode: AVAudioNode, @unchecked Sendable {}
nonisolated open class AVAudioInputNode: AVAudioNode, @unchecked Sendable {}

public struct AVAudioPlayerNodeBufferOptions: OptionSet, Sendable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let loops = AVAudioPlayerNodeBufferOptions(rawValue: 1)
  public static let interrupts = AVAudioPlayerNodeBufferOptions(rawValue: 2)
  public static let interruptsAtLoop = AVAudioPlayerNodeBufferOptions(rawValue: 4)
}

public enum AVAudioPlayerNodeCompletionCallbackType: Int, Sendable {
  case dataConsumed, dataRendered, dataPlayedBack
}

nonisolated open class AVAudioPlayerNode: AVAudioNode, @unchecked Sendable {
  public private(set) var isPlaying = false
  public var volume: Float = 1
  public var pan: Float = 0
  public var rate: Float = 1
  public func scheduleBuffer(_ buffer: AVAudioPCMBuffer, completionHandler: (() -> Void)? = nil) {}
  public func scheduleBuffer(_ buffer: AVAudioPCMBuffer, at when: AVAudioTime?, options: AVAudioPlayerNodeBufferOptions = [], completionHandler: (() -> Void)? = nil) {}
  public func scheduleBuffer(_ buffer: AVAudioPCMBuffer, at when: AVAudioTime?, options: AVAudioPlayerNodeBufferOptions = [], completionCallbackType: AVAudioPlayerNodeCompletionCallbackType, completionHandler: ((AVAudioPlayerNodeCompletionCallbackType) -> Void)? = nil) {}
  public func play() { isPlaying = true }
  public func play(at when: AVAudioTime?) { isPlaying = true }
  public func pause() { isPlaying = false }
  public func stop() { isPlaying = false }
  public func nodeTime(forPlayerTime time: AVAudioTime) -> AVAudioTime? { nil }
  public func playerTime(forNodeTime time: AVAudioTime) -> AVAudioTime? { nil }
}

nonisolated open class AVAudioEngine: @unchecked Sendable {
  public let mainMixerNode = AVAudioMixerNode()
  public let outputNode = AVAudioOutputNode()
  public let inputNode = AVAudioInputNode()
  public private(set) var isRunning = false
  public var attachedNodes: Set<ObjectIdentifier> = []
  nonisolated public init() {}
  public func attach(_ node: AVAudioNode) { node.engine = self; attachedNodes.insert(ObjectIdentifier(node)) }
  public func detach(_ node: AVAudioNode) { node.engine = nil; attachedNodes.remove(ObjectIdentifier(node)) }
  public func connect(_ node1: AVAudioNode, to node2: AVAudioNode, format: AVAudioFormat?) {}
  public func connect(_ node1: AVAudioNode, to node2: AVAudioNode, fromBus bus1: AVAudioNodeBus, toBus bus2: AVAudioNodeBus, format: AVAudioFormat?) {}
  public func disconnectNodeOutput(_ node: AVAudioNode) {}
  public func disconnectNodeInput(_ node: AVAudioNode) {}
  public func prepare() {}
  public func start() throws { isRunning = true }
  public func pause() { isRunning = false }
  public func stop() { isRunning = false }
  public func reset() {}
}

nonisolated open class AVAudioSession: @unchecked Sendable {
  public struct Category: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let ambient = Category(rawValue: "AVAudioSessionCategoryAmbient")
    public static let soloAmbient = Category(rawValue: "AVAudioSessionCategorySoloAmbient")
    public static let playback = Category(rawValue: "AVAudioSessionCategoryPlayback")
    public static let record = Category(rawValue: "AVAudioSessionCategoryRecord")
    public static let playAndRecord = Category(rawValue: "AVAudioSessionCategoryPlayAndRecord")
    public static let multiRoute = Category(rawValue: "AVAudioSessionCategoryMultiRoute")
  }
  public struct Mode: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let `default` = Mode(rawValue: "AVAudioSessionModeDefault")
    public static let voiceChat = Mode(rawValue: "AVAudioSessionModeVoiceChat")
    public static let videoChat = Mode(rawValue: "AVAudioSessionModeVideoChat")
    public static let moviePlayback = Mode(rawValue: "AVAudioSessionModeMoviePlayback")
    public static let spokenAudio = Mode(rawValue: "AVAudioSessionModeSpokenAudio")
    public static let measurement = Mode(rawValue: "AVAudioSessionModeMeasurement")
  }
  public struct CategoryOptions: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let mixWithOthers = CategoryOptions(rawValue: 1)
    public static let duckOthers = CategoryOptions(rawValue: 2)
    public static let allowBluetooth = CategoryOptions(rawValue: 4)
    public static let defaultToSpeaker = CategoryOptions(rawValue: 8)
    public static let interruptSpokenAudioAndMixWithOthers = CategoryOptions(rawValue: 0x11)
    public static let allowBluetoothA2DP = CategoryOptions(rawValue: 0x20)
    public static let allowAirPlay = CategoryOptions(rawValue: 0x40)
  }
  public struct SetActiveOptions: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let notifyOthersOnDeactivation = SetActiveOptions(rawValue: 1)
  }
  private static let shared = AVAudioSession()
  public class func sharedInstance() -> AVAudioSession { shared }
  public private(set) var category: Category = .soloAmbient
  public private(set) var mode: Mode = .default
  public private(set) var categoryOptions: CategoryOptions = []
  public var sampleRate: Double { 44_100 }
  public var outputVolume: Float { 1 }
  public var isOtherAudioPlaying: Bool { false }
  nonisolated public init() {}
  public func setCategory(_ category: Category) throws { self.category = category }
  public func setCategory(_ category: Category, options: CategoryOptions = []) throws {
    self.category = category; categoryOptions = options
  }
  public func setCategory(_ category: Category, mode: Mode, options: CategoryOptions = []) throws {
    self.category = category; self.mode = mode; categoryOptions = options
  }
  public func setMode(_ mode: Mode) throws { self.mode = mode }
  public func setActive(_ active: Bool, options: SetActiveOptions = []) throws {}
  public func setPreferredSampleRate(_ sampleRate: Double) throws {}
  public func setPreferredIOBufferDuration(_ duration: TimeInterval) throws {}
}
