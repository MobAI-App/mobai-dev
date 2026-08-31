// Preview adapter for AudioToolbox. Sounds receive stable identifiers and play
// silently because the preview host has no application audio session.

import Foundation

/// Toll-free bridging does not exist in corelibs, so the CF spelling IS the
/// Foundation type here and `url as CFURL` compiles as an identity cast.
/// Darwin only gets the real one: corelibs' CFURL is not a usable Swift
/// type from a plain `import Foundation`, so Linux takes the alias and
/// `url as CFURL` compiles as an identity cast; on Darwin a second CFURL
/// beside the SDK's is ambiguous.
#if !canImport(Darwin)
public typealias CFURL = URL
#endif

public typealias SystemSoundID = UInt32

nonisolated(unsafe) private var nextSoundID: SystemSoundID = 1

@discardableResult
nonisolated public func AudioServicesCreateSystemSoundID(
    _ url: CFURL, _ soundID: inout SystemSoundID
) -> Int32 {
    soundID = nextSoundID
    nextSoundID += 1
    return 0
}

nonisolated public func AudioServicesPlaySystemSound(_ soundID: SystemSoundID) {}

@discardableResult
nonisolated public func AudioServicesDisposeSystemSoundID(_ soundID: SystemSoundID) -> Int32 { 0 }
