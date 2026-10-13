// Optional native UI fixture. Build with Localization, WindowPolicy, MusicPlayer, MusicPlaylist and MusicWindow.
import AppKit
import AVFoundation

@main struct Fixture {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let language = CommandLine.arguments.first(where: { $0.hasPrefix("--language=") })?.dropFirst(11) ?? "zh-CN"
        let player = MusicWindow(language:String(language))
        let evidence = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("music-check")
        if CommandLine.arguments.contains("--verify") {
            for language in ["en","zh-CN","ja"] {
                for width: CGFloat in [1200,350,300] {
                    player.applyLanguage(language)
                    player.follow(CGRect(x:100,y:100,width:width,height:600),visible:true)
                    RunLoop.current.run(until:Date().addingTimeInterval(0.1))
                    let surface = player.window!.contentView!
                    surface.layoutSubtreeIfNeeded()
                    var controls = 0
                    func check(_ view: NSView) {
                        guard !view.isHidden else { return }
                        if view is NSControl {
                            controls += 1
                            let rect = view.convert(view.bounds,to:surface)
                            assert(rect.width > 0 && rect.height > 0,"Unlaid-out control")
                            assert(surface.bounds.insetBy(dx:-1,dy:-1).contains(rect), "Clipped control: \(language), \(width), \(rect)")
                        }
                        view.subviews.forEach(check)
                    }
                    check(surface)
                    assert(controls >= 11, "Transparent toolbar must retain all controls")
                    assert(!player.window!.isKeyWindow && !player.window!.canBecomeKey)
                    assert(!player.window!.ignoresMouseEvents)
                    assert(player.window!.styleMask.contains(.nonactivatingPanel))
                    assert(!player.window!.isOpaque && !player.window!.hasShadow && player.window!.backgroundColor == .clear)
                    assert(player.window!.level.rawValue < NSWindow.Level.floating.rawValue)
                    assert(!(surface is NSVisualEffectView))
                    #if compiler(>=6.2)
                    if #available(macOS 26.0,*) { assert(!(surface is NSGlassEffectView)) }
                    #endif
                    if width != 300, let bitmap = surface.bitmapImageRepForCachingDisplay(in:surface.bounds) {
                        surface.cacheDisplay(in:surface.bounds,to:bitmap)
                        assert(bitmap.colorAt(x:1,y:1)!.alphaComponent == 0, "Player corner must not paint a backdrop")
                        try! bitmap.representation(using:.png,properties:[:])!.write(to:evidence.appendingPathComponent("native-\(language)-\(Int(width)).png"))
                        if (language == "zh-CN" && width == 1200) || (language == "ja" && width == 350) {
                            let preview = NSImage(size:surface.bounds.size)
                            preview.lockFocus()
                            NSColor.windowBackgroundColor.setFill(); surface.bounds.fill()
                            NSImage(cgImage:bitmap.cgImage!,size:surface.bounds.size).draw(in:surface.bounds)
                            preview.unlockFocus()
                            let png = NSBitmapImageRep(data:preview.tiffRepresentation!)!.representation(using:.png,properties:[:])!
                            let name = width == 1200 ? "player-transparent-wide" : "player-transparent-compact"
                            try! png.write(to:URL(fileURLWithPath:".impeccable/review/"+name+".png"))
                        }
                    }
                }
            }
            let audio = evidence.appendingPathComponent("native-demo.wav")
            if FileManager.default.fileExists(atPath:audio.path) {
                player.follow(CGRect(x:100,y:100,width:1200,height:600),visible:true)
                let files = try! MusicPlayer.audioFiles(in:evidence.appendingPathComponent("playlist-demo"))
                for language in ["en","zh-CN","ja"] {
                    for count in [1,5,11] {
                        try! player.music.loadPlaylist(Array(files.prefix(count)))
                        player.music.setVolume(0); player.music.toggle()
                        let list = MusicPlaylist(music:player.music,localization:Localization(preference:language))
                        list.reload(localization:Localization(preference:language))
                        let popover = NSPopover(); popover.animates = false
                        popover.contentViewController = list; popover.contentSize = list.preferredContentSize
                        let anchor = player.window!.contentView!
                        popover.show(relativeTo:NSRect(x:40,y:0,width:24,height:26),of:anchor,preferredEdge:.minY)
                        RunLoop.current.run(until:Date().addingTimeInterval(0.05))
                        let root = list.view
                        let scroll = root.subviews.compactMap { $0 as? NSScrollView }.first!
                        let table = scroll.documentView as! NSTableView
                        let heading = root.subviews.compactMap { $0 as? NSTextField }.first!
                        let rows = min(5,count)
                        assert(scroll.contentView.bounds.height == CGFloat(rows)*table.rowHeight)
                        for row in 0..<rows {
                            assert(table.visibleRect.contains(table.rect(ofRow:row)), "Playlist clips initial row \(row): \(language)")
                        }
                        let initialHeading = heading.frame
                        assert(root.bounds.contains(initialHeading) && root.bounds.maxY-initialHeading.maxY >= 10,
                            "Playlist heading lacks top padding")
                        table.scrollRowToVisible(count-1)
                        player.music.select(count-1); player.music.toggle()
                        list.reload(localization:Localization(preference:language))
                        RunLoop.current.run(until:Date().addingTimeInterval(0.05))
                        for row in (count-rows)..<count {
                            assert(table.visibleRect.contains(table.rect(ofRow:row)), "Playlist clips final row \(row): \(language)")
                        }
                        assert(heading.frame == initialHeading && root.frame.size == list.preferredContentSize,
                            "Playback refresh shifts the playlist heading")
                        popover.close()
                    }
                }
                print("PASS: native playlist fits complete first/last rows and a stable heading in three languages at 1/5/11 songs")
                var samples = 0
                player.onLevel = { _ in samples += 1 }
                try! player.music.load(audio); player.music.setVolume(0)
                assert(player.music.toggle())
                RunLoop.current.run(until:Date().addingTimeInterval(0.15))
                assert(samples > 2, "Visible playback samples audio")
                player.follow(CGRect(x:100,y:100,width:1200,height:600),visible:true,controlsVisible:false)
                let hiddenTime = player.music.currentTime, hiddenSamples = samples
                RunLoop.current.run(until:Date().addingTimeInterval(0.15))
                assert(!player.window!.isVisible && player.music.isPlaying && player.music.currentTime > hiddenTime+0.08 && samples > hiddenSamples,
                    "Hiding only the controls preserves playback and hair-level delivery")
                player.follow(nil,visible:false)
                let time = player.music.currentTime, before = samples
                RunLoop.current.run(until:Date().addingTimeInterval(0.15))
                assert(samples == before && player.music.currentTime > time+0.08, "Hidden player stops sampling while audio continues")
                player.follow(CGRect(x:100,y:100,width:1200,height:600),visible:true)
                assert(samples > before)
                let input = try! AVAudioFile(forReading:audio)
                let buffer = AVAudioPCMBuffer(pcmFormat:input.processingFormat,frameCapacity:4410)!
                try! input.read(into:buffer)
                let short = evidence.appendingPathComponent("short.wav")
                do { let output = try! AVAudioFile(forWriting:short,settings:input.fileFormat.settings); try! output.write(from:buffer) }
                try! player.music.load(short)
                func seekSlider(_ view: NSView) -> NSSlider? {
                    if let slider = view as? NSSlider, !slider.isContinuous { return slider }
                    return view.subviews.compactMap(seekSlider).first
                }
                assert(player.music.duration < 1 && seekSlider(player.window!.contentView!)!.maxValue == player.music.duration,
                    "Subsecond clips use the full seek range")
            }
            player.follow(nil,visible:false); player.stop()
            print("PASS: transparent lower-layer controls fit in three languages at 1200/350/300 points; hiding controls retains audio/levels; panel stays non-key")
            return
        }
        if CommandLine.arguments.contains("--playlist") {
            player.music.setVolume(0)
            let folder = evidence.appendingPathComponent("playlist-demo")
            try! player.music.loadPlaylist(MusicPlayer.audioFiles(in:folder))
        }
        let width: CGFloat = CommandLine.arguments.contains("--compact") ? 350 : 1200
        let target = CGRect(x:100,y:100,width:width,height:600)
        player.follow(target,visible:true)
        player.onLevel = { level in
            let state: [String:Any] = ["playing":player.music.isPlaying, "time":player.music.currentTime,
                "duration":player.music.duration, "volume":player.music.volume, "level":level,
                "filename":player.music.filename ?? "", "index":player.music.currentIndex ?? -1,
                "count":player.music.playlist.count, "mode":player.music.mode == .loop ? "loop" : "shuffle",
                "frame":NSStringFromRect(player.window!.frame), "isKey":player.window!.isKeyWindow,
                "frontBundle":NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""]
            var evidenceState = state
            if CommandLine.arguments.contains("--layout") {
                var layout: [[String:Any]] = []
                func inspect(_ view:NSView) {
                    if let table = view as? NSTableView, let scroll = table.enclosingScrollView {
                        layout.append(["style":table.effectiveStyle.rawValue,
                            "root":NSStringFromRect(scroll.superview!.frame),"scroll":NSStringFromRect(scroll.frame),
                            "clip":NSStringFromRect(scroll.contentView.bounds),"visible":NSStringFromRect(table.visibleRect),
                            "table":NSStringFromRect(table.frame),"first":NSStringFromRect(table.rect(ofRow:0)),
                            "fifth":NSStringFromRect(table.rect(ofRow:4)),"last":NSStringFromRect(table.rect(ofRow:table.numberOfRows-1)),
                            "insets":String(describing:scroll.contentInsets),
                            "heading":scroll.superview!.subviews.compactMap { $0 as? NSTextField }.map { NSStringFromRect($0.frame) }])
                    }
                    view.subviews.forEach(inspect)
                }
                NSApp.windows.filter { $0.isVisible }.compactMap { $0.contentView }.forEach(inspect)
                evidenceState["playlistLayout"] = layout
            }
            if let data = try? JSONSerialization.data(withJSONObject:evidenceState,options:[.prettyPrinted,.sortedKeys]) {
                try? data.write(to:evidence.appendingPathComponent("native.json"))
            }
        }
        app.run()
        player.stop()
    }
}
