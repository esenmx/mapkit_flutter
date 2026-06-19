#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension PlatformColor {
    /// Builds a color from Flutter's `Color.toARGB32()` value (`0xAARRGGBB`).
    convenience init(argb: some BinaryInteger) {
        let value = UInt32(truncatingIfNeeded: argb)
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        let a = CGFloat((value >> 24) & 0xFF) / 255
        #if os(iOS)
        self.init(red: r, green: g, blue: b, alpha: a)
        #elseif os(macOS)
        self.init(srgbRed: r, green: g, blue: b, alpha: a)
        #endif
    }
}
