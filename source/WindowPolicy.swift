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
    static func ripplePoint(_ quartz:CGPoint, primaryTop:CGFloat, target:CGRect) -> CGPoint? {
        guard quartz.x.isFinite, quartz.y.isFinite, primaryTop.isFinite else { return nil }
        let screen = CGPoint(x:quartz.x,y:primaryTop-quartz.y)
        guard target.contains(screen) else { return nil }
        return CGPoint(x:screen.x-target.minX,y:screen.y-target.minY)
    }
    static func musicRect(_ target: CGRect) -> CGRect {
        let width = min(356, max(0, target.width-24))
        let center = target.minX+target.width*2/3
        let left = min(max(center-width/2,target.minX+12),target.maxX-12-width)
        let top: CGFloat = target.width < 620 ? 48 : 0
        return CGRect(x:left,y:target.maxY-top-44,width:width,height:44)
    }
}
