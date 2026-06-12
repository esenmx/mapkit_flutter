import Flutter
import Foundation
import UIKit

enum IconType {
    case marker, image
}

/// Decoded annotation imagery: either the system balloon marker
/// (`MKMarkerAnnotationView`) with optional tint/glyph branding, or a fully
/// custom image (`MKAnnotationView.image`).
class AnnotationIcon: Equatable {

    let iconType: IconType
    var image: UIImage?
    var glyphText: String?
    var glyphImage: UIImage?
    var glyphTint: UIColor?
    var markerTint: UIColor?

    /// Custom-image variant: rendered via a plain `MKAnnotationView`.
    var isCustomImage: Bool { iconType == .image }

    init(fromPlatform icon: PlatformAnnotationIcon) {
        switch icon.type {
        case .marker:
            self.iconType = .marker
            self.glyphText = icon.glyphText
            if let systemImage = icon.glyphSystemImage {
                self.glyphImage = UIImage(systemName: systemImage)
            }
            if let argb = icon.glyphTintArgb {
                self.glyphTint = UIColor(argb: argb)
            }
            if let argb = icon.markerTintArgb {
                self.markerTint = UIColor(argb: argb)
            }
        case .image:
            self.iconType = .image
            if let data = icon.imageBytes?.data {
                self.image = UIImage(data: data, scale: UIScreen.main.scale)
            }
        }
    }

    static func == (lhs: AnnotationIcon, rhs: AnnotationIcon) -> Bool {
        return lhs.iconType == rhs.iconType
            && lhs.image == rhs.image
            && lhs.glyphText == rhs.glyphText
            && lhs.glyphImage == rhs.glyphImage
            && lhs.glyphTint == rhs.glyphTint
            && lhs.markerTint == rhs.markerTint
    }
}
