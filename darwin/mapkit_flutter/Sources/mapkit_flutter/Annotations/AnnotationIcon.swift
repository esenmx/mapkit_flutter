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

    /// Throws `invalid-icon` for an SF Symbol name the OS doesn't know or image
    /// bytes it can't decode — never an invisible or silently plain marker.
    init(fromPlatform icon: PlatformAnnotationIcon) throws {
        switch icon.type {
        case .marker:
            self.iconType = .marker
            self.glyphText = icon.glyphText
            if let systemImage = icon.glyphSystemImage {
                guard let glyph = PlatformImage.systemSymbol(systemImage) else {
                    throw mapKitError(.invalidIcon, "Unknown SF Symbol \"\(systemImage)\".")
                }
                self.glyphImage = glyph
            }
            if let argb = icon.glyphTintArgb {
                self.glyphTint = PlatformColor(argb: argb)
            }
            if let argb = icon.markerTintArgb {
                self.markerTint = PlatformColor(argb: argb)
            }
        case .image:
            self.iconType = .image
            guard let data = icon.imageBytes?.data,
                  let image = PlatformImage.fromImageData(
                    data, pixelRatio: CGFloat(icon.imagePixelRatio ?? 1)) else {
                throw mapKitError(.invalidIcon, "Annotation image bytes could not be decoded.")
            }
            self.image = image
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
