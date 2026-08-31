// Preview adapter for CryptoKit. NOT cryptography: a preview never
// protects anything, it only needs deterministic digests so app code that
// derives cache keys or identifiers keeps working.

import Foundation

public enum SHA256 {
  public struct Digest: Sequence, CustomStringConvertible {
    let bytes: [UInt8]
    public func makeIterator() -> IndexingIterator<[UInt8]> { bytes.makeIterator() }
    public var description: String {
      "SHA256 digest: " + bytes.map { String(format: "%02x", $0) }.joined()
    }
  }

  /// FNV-1a folded to 32 bytes: stable and collision-poor at preview
  /// scale, and in no sense cryptographic.
  public static func hash<D: DataProtocol>(data: D) -> Digest {
    var h: UInt64 = 0xcbf29ce484222325
    for byte in data {
      h ^= UInt64(byte)
      h = h &* 0x100000001b3
    }
    var bytes: [UInt8] = []
    var v = h
    for _ in 0..<4 {
      for shift in stride(from: 56, through: 0, by: -8) {
        bytes.append(UInt8((v >> UInt64(shift)) & 0xff))
      }
      v = v &* 0x100000001b3
    }
    return Digest(bytes: bytes)
  }
}
