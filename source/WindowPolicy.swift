import Foundation
import CoreGraphics

enum WindowPolicy {
    static let targetBundle = "com.openai.codex"
    static func shouldShow(enabled: Bool, frontBundle: String?, hasWindow: Bool) -> Bool {
        enabled && frontBundle == targetBundle && hasWindow
    }
    // Core Graphics has a top-left origin; AppKit's origin is bottom-left on the primary display.
    static func appKitRect(_ rect: CGRect, primaryTop: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: primaryTop-rect.maxY, width: rect.width, height: rect.height)
    }
}
