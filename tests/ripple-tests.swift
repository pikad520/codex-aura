import AppKit
import QuartzCore

@main struct Tests {
    static func wait(_ seconds:Double) { RunLoop.current.run(until:Date().addingTimeInterval(seconds)) }
    static func main() throws {
        let app = NSApplication.shared; app.setActivationPolicy(.accessory)
        let panel = NSPanel(contentRect:NSRect(x:100,y:100,width:320,height:180),
            styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.ignoresMouseEvents = true
        let view = ClickRipple(frame:panel.contentView!.bounds); panel.contentView = view
        assert(view.hitTest(CGPoint(x:160,y:90)) == nil)
        view.setActive(true); assert(view.isMonitoring)
        view.setActive(true); assert(view.isMonitoring)
        view.setActive(false); assert(!view.isMonitoring)
        panel.orderFrontRegardless()
        view.show(at:CGPoint(x:160,y:90),reducedMotion:true)
        view.show(at:CGPoint(x:-1,y:90),reducedMotion:false)
        view.show(at:CGPoint(x:Double.nan,y:90),reducedMotion:false)
        assert(view.layer!.sublayers?.isEmpty != false)
        view.show(at:CGPoint(x:160,y:90),reducedMotion:false)
        let ring = view.layer!.sublayers!.first as! CAShapeLayer
        assert(ring.frame.midX == 160 && ring.frame.midY == 90)
        CATransaction.flush(); wait(0.05)
        let early = ring.presentation()!
        let earlyWidth = early.path!.boundingBox.width, earlyOpacity = early.opacity
        assert(earlyWidth > 12 && earlyWidth < 84 && earlyOpacity > 0)
        func capture(_ name:String) throws {
            let size = view.bounds.size
            let context = CGContext(data:nil,width:Int(size.width*2),height:Int(size.height*2),bitsPerComponent:8,
                bytesPerRow:Int(size.width*2)*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.scaleBy(x:2,y:2)
            view.layer!.presentation()!.render(in:context)
            let bitmap = NSBitmapImageRep(cgImage:context.makeImage()!)
            let destination = URL(fileURLWithPath:".impeccable/review/"+name+".png")
            try FileManager.default.createDirectory(at:destination.deletingLastPathComponent(),withIntermediateDirectories:true)
            try bitmap.representation(using:.png,properties:[:])!.write(to:destination)
        }
        try capture("ripple-early")
        wait(0.12)
        let expanded = ring.presentation()!
        assert(expanded.path!.boundingBox.width > earlyWidth && expanded.opacity < earlyOpacity,
            "Real Core Animation presentation expands and fades the ring")
        try capture("ripple-expanded")
        for _ in 0..<20 { view.show(at:CGPoint(x:160,y:90),reducedMotion:false) }
        assert(view.layer!.sublayers!.count == 8)
        wait(0.6); assert((view.layer!.sublayers?.count ?? 0) == 0)
        view.show(at:CGPoint(x:160,y:90),reducedMotion:false)
        view.setActive(false); assert((view.layer!.sublayers?.count ?? 0) == 0)
        panel.orderOut(nil)
        print("PASS: passive monitor lifecycle, click-through hit testing, real ring expansion/fade, bounds/Reduce Motion, eight-ring cap and cleanup")
    }
}
