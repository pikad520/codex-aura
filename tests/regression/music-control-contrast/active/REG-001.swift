import AppKit

@main struct Regression {
    static func luminance(_ color:NSColor) -> Double {
        let c = color.usingColorSpace(.sRGB)!
        func linear(_ x:CGFloat) -> Double { x <= 0.04045 ? Double(x)/12.92 : pow((Double(x)+0.055)/1.055,2.4) }
        return 0.2126*linear(c.redComponent)+0.7152*linear(c.greenComponent)+0.0722*linear(c.blueComponent)
    }
    static func contrast(_ a:NSColor, _ b:NSColor) -> Double {
        let first = luminance(a), second = luminance(b)
        return (max(first,second)+0.05)/(min(first,second)+0.05)
    }
    static func main() throws {
        let app = NSApplication.shared; app.setActivationPolicy(.accessory)
        let player = MusicWindow(language:"zh-CN")
        let appearance: NSAppearance.Name = CommandLine.arguments.contains("--dark-companion") ? .darkAqua : .aqua
        let lightBackdrop = CommandLine.arguments.contains("--light-backdrop")
        player.window!.appearance = NSAppearance(named:appearance)
        let playingDemo = CommandLine.arguments.contains("--playing-demo")
        if playingDemo {
            player.music.setVolume(0)
            try player.music.load(URL(fileURLWithPath:".build/music-check/native-demo.wav"))
            player.music.seek(35); assert(player.music.toggle())
        }
        player.follow(CGRect(x:100,y:100,width:1200,height:600),visible:true)
        RunLoop.current.run(until:Date().addingTimeInterval(0.1))
        let surface = player.window!.contentView!
        surface.layoutSubtreeIfNeeded()
        let raw = surface.bitmapImageRepForCachingDisplay(in:surface.bounds)!
        surface.cacheDisplay(in:surface.bounds,to:raw)
        assert(raw.colorAt(x:1,y:1)!.alphaComponent == 0,"Backdrop must remain transparent")
        let level: CGFloat = lightBackdrop ? 243/255 : 30/255
        let background = NSColor(srgbRed:level,green:level,blue:level,alpha:1)
        let image = NSImage(size:surface.bounds.size)
        image.lockFocus()
        background.setFill(); surface.bounds.fill()
        NSImage(cgImage:raw.cgImage!,size:surface.bounds.size).draw(in:surface.bounds)
        image.unlockFocus()
        let rendered = NSBitmapImageRep(data:image.tiffRepresentation!)!
        let evidence = URL(fileURLWithPath:".build/music-contrast")
        try FileManager.default.createDirectory(at:evidence,withIntermediateDirectories:true)
        let name = (lightBackdrop ? "light" : "dark")+(appearance == .aqua ? "-aqua" : "-dark-aqua")+(playingDemo ? "-playing" : "")
        try rendered.representation(using:.png,properties:[:])!.write(to:evidence.appendingPathComponent(name+".png"))
        func labels(_ view:NSView) -> [NSTextField] {
            if let field = view as? NSTextField, field.font?.pointSize == 9 { return [field] }
            return view.subviews.flatMap(labels)
        }
        let clocks = labels(surface)
        assert(clocks.count == 2,"Fixture must render both time labels")
        let scale = CGFloat(rendered.pixelsWide)/surface.bounds.width
        var results: [[String:Any]] = []
        for field in clocks {
            let rect = field.convert(field.bounds,to:surface)
            var readable = 0, maximum = 0.0
            for x in Int(rect.minX*scale)..<Int(rect.maxX*scale) {
                for y in Int((surface.bounds.height-rect.maxY)*scale)..<Int((surface.bounds.height-rect.minY)*scale) {
                    let ratio = contrast(rendered.colorAt(x:x,y:y)!,background)
                    maximum = max(maximum,ratio)
                    if ratio >= 4.5 { readable += 1 }
                }
            }
            results.append(["label":field.stringValue,"pixelsAt4.5":readable,"maximumContrast":maximum])
        }
        let data = try JSONSerialization.data(withJSONObject:results,options:[.prettyPrinted,.sortedKeys])
        try data.write(to:evidence.appendingPathComponent(name+".json"))
        print(String(data:data,encoding:.utf8)!)
        let passed = results.allSatisfy { ($0["pixelsAt4.5"] as! Int) >= 20 }
        player.follow(nil,visible:false); player.stop()
        print(passed ? "PASS REG-001: time labels readable in \(name)" : "FAIL REG-001: transparent time labels lack contrast in \(name)")
        exit(passed ? 0 : 1)
    }
}
