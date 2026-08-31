// Preview adapter for CodeScanner. It renders a stable scanner placeholder;
// `simulatedData` is exposed as text but no scan is fired automatically.

import SwiftUI

public struct ScanResult: Sendable {
    public let string: String
    public let type: ScanCodeType

    public init(string: String, type: ScanCodeType) {
        self.string = string
        self.type = type
    }
}

public enum ScanError: Error, Sendable {
    case badInput
    case badOutput
    case initError(String)
    case permissionDenied
}

public enum ScanMode: Sendable {
    case once
    case oncePerCode
    case continuous
}

public struct ScanCodeType: Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let qr = ScanCodeType(rawValue: "qr")
}

public struct CodeScannerView: View {
    private let simulatedData: String

    public init(
        codeTypes: [ScanCodeType],
        scanMode: ScanMode = .once,
        scanInterval: Double = 2,
        showViewfinder: Bool = false,
        simulatedData: String = "",
        shouldVibrateOnSuccess: Bool = true,
        completion: @escaping (Result<ScanResult, ScanError>) -> Void
    ) {
        self.simulatedData = simulatedData
    }

    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "qrcode.viewfinder")
            Text(simulatedData.isEmpty ? "Scanner unavailable in preview" : simulatedData)
        }
        .accessibilityLabel("Code scanner")
    }
}
