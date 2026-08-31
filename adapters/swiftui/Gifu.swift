// Preview adapter for Gifu. GIFImageView keeps its UIKit-compatible shape;
// animation methods are inert because previews do not decode GIF frames.

import Foundation
import SwiftUI

/// The engine's UIImageView supplies the layout anchors and image-view surface
/// expected by code embedding Gifu in a UIViewRepresentable.
open class GIFImageView: UIImageView {
    @discardableResult
    nonisolated public func prepareForAnimation(
        _ arguments: Any...
    ) -> GIFImageView { self }

    @discardableResult
    nonisolated public func startAnimatingGIF(
        _ arguments: Any...
    ) -> GIFImageView { self }

    @discardableResult
    nonisolated public func prepareForAnimation(
        withGIFData: Any,
        _ rest: Any...
    ) -> GIFImageView { self }
}
