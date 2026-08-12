import CoreGraphics
import Foundation

/// Cross-platform aliases bridging UIKit (iOS) and AppKit (macOS) so the bulk
/// of the plugin compiles unchanged on both. Divergent APIs stay behind
/// `#if os(...)` at their call sites; this file covers the common types.
#if os(iOS)
import UIKit

typealias PlatformColor = UIColor
typealias PlatformImage = UIImage
typealias PlatformView = UIView
typealias PlatformGestureRecognizer = UIGestureRecognizer
typealias PlatformGestureRecognizerDelegate = UIGestureRecognizerDelegate
#elseif os(macOS)
import AppKit

typealias PlatformColor = NSColor
typealias PlatformImage = NSImage
typealias PlatformView = NSView
typealias PlatformGestureRecognizer = NSGestureRecognizer
typealias PlatformGestureRecognizerDelegate = NSGestureRecognizerDelegate
#endif

extension PlatformView {
    /// View opacity, bridging `UIView.alpha` and `NSView.alphaValue`.
    var platformAlpha: CGFloat {
        get {
            #if os(iOS)
            return alpha
            #elseif os(macOS)
            return alphaValue
            #endif
        }
        set {
            #if os(iOS)
            alpha = newValue
            #elseif os(macOS)
            alphaValue = newValue
            #endif
        }
    }
}

extension PlatformImage {
    /// An SF Symbol image by name (`UIImage(systemName:)` /
    /// `NSImage(systemSymbolName:)`).
    static func systemSymbol(_ name: String) -> PlatformImage? {
        #if os(iOS)
        return UIImage(systemName: name)
        #elseif os(macOS)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil)
        #endif
    }

    /// A bitmap image from raw PNG/image bytes, sized in points via the
    /// Dart-supplied pixel ratio of the bytes (`UIImage(data:scale:)` has no
    /// AppKit equivalent, so the macOS path divides the pixel size by it).
    static func fromImageData(_ data: Data, pixelRatio: CGFloat) -> PlatformImage? {
        #if os(iOS)
        return UIImage(data: data, scale: pixelRatio)
        #elseif os(macOS)
        guard let image = NSImage(data: data) else { return nil }
        if let rep = image.representations.first {
            image.size = NSSize(
                width: CGFloat(rep.pixelsWide) / pixelRatio,
                height: CGFloat(rep.pixelsHigh) / pixelRatio
            )
        }
        return image
        #endif
    }

    /// PNG-encoded bytes of the image (`UIImage.pngData()` /
    /// `NSBitmapImageRep` round-trip on macOS).
    var pngRepresentation: Data? {
        #if os(iOS)
        return pngData()
        #elseif os(macOS)
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
        #endif
    }
}
