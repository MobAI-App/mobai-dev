//
//  UniformTypeIdentifiers.swift
//  Stand-in for Apple's UniformTypeIdentifiers.
//
//  Pure data: a type identifier, its file extension, and a MIME guess. The
//  statics cover what apps name in Transferable representations and photo
//  pickers; the MIME table covers the extensions a share/upload path asks
//  about. Nothing here touches the type registry a real OS keeps.
//

import Foundation

public struct UTType: Hashable, Sendable {
    public let identifier: String

    public init(_ identifier: String) { self.identifier = identifier }
    public init?(filenameExtension: String) {
        guard !filenameExtension.isEmpty else { return nil }
        self.identifier = "public.filename-extension." + filenameExtension.lowercased()
    }
    public init?(mimeType: String) {
        guard !mimeType.isEmpty else { return nil }
        self.identifier = "public.mime-type." + mimeType.lowercased()
    }

    public var preferredMIMEType: String? {
        let ext = identifier.components(separatedBy: ".").last ?? ""
        return UTType.mimeByExtension[ext]
    }
    public var preferredFilenameExtension: String? {
        identifier.components(separatedBy: ".").last
    }
    public func conforms(to type: UTType) -> Bool {
        identifier == type.identifier
    }

    private static let mimeByExtension: [String: String] = [
        "jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png",
        "gif": "image/gif", "heic": "image/heic", "webp": "image/webp",
        "mp4": "video/mp4", "mov": "video/quicktime", "m4v": "video/x-m4v",
        "mp3": "audio/mpeg", "m4a": "audio/mp4", "wav": "audio/wav",
        "txt": "text/plain", "json": "application/json", "pdf": "application/pdf",
    ]

    public static let item = UTType("public.item")
    public static let data = UTType("public.data")
    public static let content = UTType("public.content")
    public static let text = UTType("public.text")
    public static let plainText = UTType("public.plain-text")
    public static let utf8PlainText = UTType("public.utf8-plain-text")
    public static let url = UTType("public.url")
    public static let fileURL = UTType("public.file-url")
    public static let image = UTType("public.image")
    public static let jpeg = UTType("public.jpeg")
    public static let png = UTType("public.png")
    public static let gif = UTType("com.compuserve.gif")
    public static let heic = UTType("public.heic")
    public static let webP = UTType("org.webmproject.webp")
    public static let movie = UTType("public.movie")
    public static let video = UTType("public.video")
    public static let audio = UTType("public.audio")
    public static let mpeg4Movie = UTType("public.mpeg-4")
    public static let quickTimeMovie = UTType("com.apple.quicktime-movie")
    public static let pdf = UTType("com.adobe.pdf")
    public static let folder = UTType("public.folder")
}
