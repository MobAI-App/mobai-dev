// Preview adapter for SwiftyCrop. The original image is shown without crop
// interaction; completion is intentionally not fired automatically.

import SwiftUI

public struct SwiftyCropConfiguration: Hashable, Sendable {
    public var rotateImage: Bool
    public var zoomSensitivity: CGFloat

    public init(rotateImage: Bool = true, zoomSensitivity: CGFloat = 1) {
        self.rotateImage = rotateImage
        self.zoomSensitivity = zoomSensitivity
    }
}

public enum MaskShape: Hashable, Sendable {
    case circle
    case square
}

public struct SwiftyCropView: View {
    private let image: UIImage

    public init(
        imageToCrop: UIImage,
        maskShape: MaskShape = .circle,
        configuration: SwiftyCropConfiguration = SwiftyCropConfiguration(),
        onComplete: @escaping (UIImage?) -> Void
    ) {
        self.image = imageToCrop
    }

    public var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .accessibilityLabel("Crop preview")
    }
}
