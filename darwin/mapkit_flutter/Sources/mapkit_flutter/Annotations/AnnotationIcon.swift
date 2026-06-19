import Foundation

#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
import AppKit
#endif

enum IconType {
    case marker, image
}

/// Decoded annotation imagery: either the system balloon marker
/// (`MKMarkerAnnotationView`) with optional tint/glyph branding, or a fully
/// custom image (`MKAnnotationView.image`).
class AnnotationIcon: Equatable {

    let iconType: IconType
    var image: PlatformImage?
    var glyphText: String?
    var glyphImage: PlatformImage?
    var glyphTint: PlatformColor?
    var markerTint: PlatformColor?

    /// Custom-image variant: rendered via a plain `MKAnnotationView`.
    var isCustomImage: Bool { iconType == .image }

    init(fromPlatform icon: PlatformAnnotationIcon) {
        switch icon.type {
        case .marker:
            self.iconType = .marker
            self.glyphText = icon.glyphText
            if let systemImage = icon.glyphSystemImage {
                self.glyphImage = PlatformImage.systemSymbol(systemImage)
            }
            if let argb = icon.glyphTintArgb {
                self.glyphTint = PlatformColor(argb: argb)
            }
            if let argb = icon.markerTintArgb {
                self.markerTint = PlatformColor(argb: argb)
            }
        case .image:
            self.iconType = .image
            if let data = icon.imageBytes?.data {
                self.image = PlatformImage.fromImageData(data)
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
