// Preview adapter for CoreHaptics. Nothing headless vibrates, so the hardware
// capability probe reports that haptics are unavailable.

import Foundation

nonisolated public class CHHapticEngine {
    public struct Capabilities: Sendable {
        public let supportsHaptics = false
    }
    nonisolated public init() throws {}
    nonisolated public static func capabilitiesForHardware() -> Capabilities { Capabilities() }
    nonisolated public func start() throws {}
    nonisolated public func stop() {}
}
