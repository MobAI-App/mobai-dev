// Preview adapter for LinkPresentation. Metadata remains editable for share
// sheets; network metadata fetching returns an empty metadata object.

import Foundation

public final class LPLinkMetadata: @unchecked Sendable {
    public init() {}

    public var originalURL: URL?
    public var url: URL?
    public var title: String?
    public var imageProvider: NSItemProvider?
    public var iconProvider: NSItemProvider?
    public var videoProvider: NSItemProvider?
    public var remoteVideoURL: URL?
}

public final class LPMetadataProvider: @unchecked Sendable {
    public init() {}

    public var shouldFetchSubresources = true
    public var timeout: TimeInterval = 30

    public func startFetchingMetadata(
        for url: URL,
        completionHandler: @escaping (LPLinkMetadata?, Error?) -> Void
    ) {
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        metadata.url = url
        completionHandler(metadata, nil)
    }

    public func startFetchingMetadata(for url: URL) async throws -> LPLinkMetadata {
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        metadata.url = url
        return metadata
    }

    public func cancel() {}
}
