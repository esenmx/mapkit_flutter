import UIKit

extension UIColor {
    /// Builds a color from Flutter's `Color.toARGB32()` value (`0xAARRGGBB`).
    convenience init(argb: some BinaryInteger) {
        let value = UInt32(truncatingIfNeeded: argb)
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: CGFloat((value >> 24) & 0xFF) / 255
        )
    }
}
