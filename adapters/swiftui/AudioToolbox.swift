// Preview adapter for AudioToolbox. Sounds receive stable identifiers and play
// silently because the preview host has no application audio session.

import Foundation

#if canImport(Darwin)
public typealias AudioServicesURL = CFURL
#else
/// On Linux the preview's SwiftUI re-exports CoreFoundation, so `CFURL` is
/// CoreFoundation's own class in every app file, and a stand-in declaring a
/// second `CFURL` makes the name ambiguous wherever both are imported. That
/// class has no bridge from `URL` either, so the app's `url as CFURL` could
/// never type-check against it: the engine drops that cast from the staged
/// copy of app source, and the URL arrives here as itself.
public typealias AudioServicesURL = URL
#endif

public typealias SystemSoundID = UInt32
public typealias OSStatus = Int32

public let kSystemSoundID_Vibrate: SystemSoundID = 4095

nonisolated(unsafe) private var nextSoundID: SystemSoundID = 1

@discardableResult
nonisolated public func AudioServicesCreateSystemSoundID(
    _ url: AudioServicesURL, _ soundID: inout SystemSoundID
) -> OSStatus {
    soundID = nextSoundID
    nextSoundID += 1
    return 0
}

nonisolated public func AudioServicesPlaySystemSound(_ soundID: SystemSoundID) {}
nonisolated public func AudioServicesPlayAlertSound(_ soundID: SystemSoundID) {}

nonisolated public func AudioServicesPlaySystemSoundWithCompletion(
    _ soundID: SystemSoundID, _ completion: (() -> Void)?
) {
    completion?()
}

nonisolated public func AudioServicesPlayAlertSoundWithCompletion(
    _ soundID: SystemSoundID, _ completion: (() -> Void)?
) {
    completion?()
}

@discardableResult
nonisolated public func AudioServicesDisposeSystemSoundID(_ soundID: SystemSoundID) -> OSStatus { 0 }
