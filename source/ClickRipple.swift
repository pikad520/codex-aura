import AppKit
import QuartzCore

final class ClickRipple: NSView {
    private var monitor: Any?
    var isMonitoring: Bool { monitor != nil }

    override init(frame:NSRect) {
        super.init(frame:frame)
        autoresizingMask = [.width,.height]
        wantsLayer = true; layer?.masksToBounds = true
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) not supported") }
    override func hitTest(_ point:NSPoint) -> NSView? { nil }

    func setActive(_ active:Bool) {
        if !active {
            if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
            clear(); return
        }
        guard monitor == nil else { return }
        // This monitor observes copies; the original click is delivered by macOS unchanged.
        monitor = NSEvent.addGlobalMonitorForEvents(matching:.leftMouseDown) { [weak self] event in
            guard let self, self.isMonitoring, let window = self.window, window.isVisible,
                  NSWorkspace.shared.frontmostApplication?.bundleIdentifier == WindowPolicy.targetBundle,
                  let location = event.cgEvent?.location,
                  let point = WindowPolicy.ripplePoint(location,primaryTop:NSScreen.screens.first?.frame.maxY ?? 0,target:window.frame) else { return }
            self.show(at:point,reducedMotion:NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        }
    }

    func show(at point:CGPoint, reducedMotion:Bool) {
        guard !reducedMotion, point.x.isFinite, point.y.isFinite, bounds.contains(point), let layer else { return }
        if let oldest = layer.sublayers?.first, (layer.sublayers?.count ?? 0) >= 8 { oldest.removeFromSuperlayer() }
        let ring = CAShapeLayer()
        ring.frame = CGRect(x:point.x-48,y:point.y-48,width:96,height:96)
        ring.path = CGPath(ellipseIn:ring.bounds.insetBy(dx:6,dy:6),transform:nil)
        ring.fillColor = nil; ring.lineWidth = 1.5
        ring.strokeColor = NSColor(calibratedRed:0.45,green:0.75,blue:1,alpha:1).cgColor
        ring.opacity = 0
        let spread = CABasicAnimation(keyPath:"path")
        spread.fromValue = CGPath(ellipseIn:ring.bounds.insetBy(dx:42,dy:42),transform:nil)
        spread.toValue = ring.path
        spread.duration = 0.5
        spread.timingFunction = CAMediaTimingFunction(controlPoints:0.16,1,0.3,1)
        let fade = CABasicAnimation(keyPath:"opacity"); fade.fromValue = 0.6; fade.toValue = 0
        fade.duration = 0.5; fade.timingFunction = CAMediaTimingFunction(name:.linear)
        let animation = CAAnimationGroup(); animation.animations = [spread,fade]; animation.duration = 0.5
        layer.addSublayer(ring); ring.add(animation,forKey:"click")
        DispatchQueue.main.asyncAfter(deadline:.now()+0.5) { [weak ring] in ring?.removeFromSuperlayer() }
    }

    func clear() { layer?.sublayers?.forEach { $0.removeFromSuperlayer() } }
}
