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

/// Inert P256 key agreement: push-notification plumbing constructs keys and
/// reads their representations; a preview needs the shapes, never the math.
nonisolated public enum P256 {
  public enum KeyAgreement {
    public struct PublicKey: Sendable {
      public var rawRepresentation: Data { Data(repeating: 0, count: 64) }
      public var x963Representation: Data { Data(repeating: 4, count: 65) }
    }
    public struct PrivateKey: Sendable {
      public init() {}
      public init(rawRepresentation: Data) throws {}
      public var rawRepresentation: Data { Data(repeating: 0, count: 32) }
      public var publicKey: PublicKey { PublicKey() }
    }
  }
}
