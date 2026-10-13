import AppKit

private final class MusicPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class ToolbarButton: NSButton {
    var symbol = ""
    private var hover: NSTrackingArea?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hover { removeTrackingArea(hover) }
        hover = NSTrackingArea(rect:bounds,options:[.mouseEnteredAndExited,.activeAlways,.inVisibleRect],owner:self)
        addTrackingArea(hover!)
    }
    override func mouseEntered(with event: NSEvent) {
        guard isEnabled else { return }
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        layer?.borderColor = NSColor.black.withAlphaComponent(0.35).cgColor; layer?.borderWidth = 0.5
    }
    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = NSColor.clear.cgColor; layer?.borderWidth = 0
    }
}

private final class MusicSliderCell: NSSliderCell {
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let bar = NSRect(x:rect.minX,y:rect.midY-1,width:rect.width,height:2)
        let path = NSBezierPath(roundedRect:bar,xRadius:1,yRadius:1)
        NSColor.white.withAlphaComponent(isEnabled ? 0.42 : 0.16).setFill(); path.fill()
        NSColor.black.withAlphaComponent(isEnabled ? 0.75 : 0.3).setStroke()
        path.lineWidth = 1; path.stroke()
        let value = maxValue > minValue ? min(1,max(0,(doubleValue-minValue)/(maxValue-minValue))) : 0
        NSColor.controlAccentColor.withAlphaComponent(isEnabled ? 0.8 : 0.2).setFill()
        NSBezierPath(roundedRect:NSRect(x:bar.minX,y:bar.minY,width:bar.width*value,height:2),xRadius:1,yRadius:1).fill()
    }
    override func drawKnob(_ rect: NSRect) {
        let knob = NSRect(x:rect.midX-3,y:rect.midY-3,width:6,height:6)
        let path = NSBezierPath(ovalIn:knob)
        NSColor.white.withAlphaComponent(isEnabled ? 1 : 0.4).setFill(); path.fill()
        NSColor.black.withAlphaComponent(isEnabled ? 1 : 0.4).setStroke()
        path.lineWidth = 1; path.stroke()
    }
}

private final class MusicSlider: NSSlider {
    var isSeeking = false
    override init(frame: NSRect) { super.init(frame:frame); cell = MusicSliderCell() }
    required init?(coder:NSCoder) { fatalError("init(coder:) not supported") }
    override func mouseDown(with event:NSEvent) {
        isSeeking = true; defer { isSeeking = false }
        super.mouseDown(with:event)
    }
}

final class MusicWindow: NSWindowController {
    let music = MusicPlayer()
    var onLevel: ((Double) -> Void)?
    var presentingDialog: Bool { showingDialog || popover.isShown }
    private var showingDialog = false
    private var loadingFolder = false
    private var visible = false
    private var timer: Timer?
    private var l: Localization
    private var lastVolume = 0.5
    private let openButton = ToolbarButton()
    private let listButton = ToolbarButton()
    private let modeButton = ToolbarButton()
    private let previousButton = ToolbarButton()
    private let playButton = ToolbarButton()
    private let nextButton = ToolbarButton()
    private let speaker = ToolbarButton()
    private let progress = MusicSlider(frame:.zero)
    private let volume = MusicSlider(frame:.zero)
    private let elapsed = NSTextField(labelWithString:"")
    private let total = NSTextField(labelWithString:"")
    private let popover = NSPopover()
    private var playlistView: MusicPlaylist!

    init(language:String) {
        l = Localization(preference:language)
        let panel = MusicPanel(contentRect:NSRect(x:0,y:0,width:356,height:44),
            styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue:NSWindow.Level.floating.rawValue-1)
        panel.collectionBehavior = [.canJoinAllSpaces,.fullScreenAuxiliary,.ignoresCycle]
        panel.hidesOnDeactivate = false; panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false; panel.isMovable = false
        super.init(window:panel)

        let content = NSView(frame:panel.contentView!.bounds)
        content.autoresizingMask = [.width,.height]
        panel.contentView = content
        let root = NSStackView(); root.orientation = .vertical; root.spacing = 0
        root.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo:content.leadingAnchor,constant:8),
            root.trailingAnchor.constraint(equalTo:content.trailingAnchor,constant:-8),
            root.topAnchor.constraint(equalTo:content.topAnchor,constant:3),
            root.bottomAnchor.constraint(equalTo:content.bottomAnchor,constant:-3)
        ])
        let controls = NSStackView(); controls.orientation = .horizontal
        controls.alignment = .centerY; controls.distribution = .equalSpacing; controls.spacing = 4
        controls.heightAnchor.constraint(equalToConstant:26).isActive = true
        for button in [openButton,listButton,modeButton,previousButton,playButton,nextButton,speaker] {
            button.isBordered = false; button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown; button.target = self
            button.wantsLayer = true; button.layer?.cornerRadius = 5
            button.widthAnchor.constraint(equalToConstant:button === playButton ? 28 : button === speaker ? 18 : 24).isActive = true
            button.heightAnchor.constraint(equalToConstant:26).isActive = true
        }
        openButton.action = #selector(chooseFolder); listButton.action = #selector(showPlaylist)
        modeButton.action = #selector(togglePlaybackMode); previousButton.action = #selector(previous)
        playButton.action = #selector(togglePlayback); nextButton.action = #selector(next)
        speaker.action = #selector(mute)
        let sound = NSStackView(); sound.orientation = .horizontal; sound.alignment = .centerY; sound.spacing = 4
        sound.addArrangedSubview(speaker); sound.addArrangedSubview(volume)
        volume.minValue = 0; volume.maxValue = 1; volume.doubleValue = 0.5
        volume.target = self; volume.action = #selector(changeVolume); volume.isContinuous = true
        volume.controlSize = .mini; volume.widthAnchor.constraint(equalToConstant:56).isActive = true
        volume.heightAnchor.constraint(equalToConstant:16).isActive = true
        [openButton,listButton,modeButton,previousButton,playButton,nextButton,sound].forEach { controls.addArrangedSubview($0) }
        root.addArrangedSubview(controls)
        controls.widthAnchor.constraint(equalTo:root.widthAnchor).isActive = true

        let timeline = NSStackView(); timeline.orientation = .horizontal; timeline.alignment = .centerY; timeline.spacing = 6
        timeline.heightAnchor.constraint(equalToConstant:12).isActive = true
        for field in [elapsed,total] {
            field.font = .monospacedDigitSystemFont(ofSize:9,weight:.medium)
            field.textColor = .white; field.alignment = .center
            field.setContentHuggingPriority(.required,for:.horizontal)
            field.setContentCompressionResistancePriority(.required,for:.horizontal)
            field.widthAnchor.constraint(greaterThanOrEqualToConstant:28).isActive = true
        }
        progress.minValue = 0; progress.maxValue = 1
        progress.target = self; progress.action = #selector(seek); progress.isContinuous = false
        progress.controlSize = .mini
        progress.setContentHuggingPriority(.defaultLow,for:.horizontal)
        progress.widthAnchor.constraint(greaterThanOrEqualToConstant:70).isActive = true
        progress.heightAnchor.constraint(equalToConstant:12).isActive = true
        [elapsed,progress,total].forEach { timeline.addArrangedSubview($0) }
        root.addArrangedSubview(timeline)
        timeline.widthAnchor.constraint(equalTo:root.widthAnchor).isActive = true

        playlistView = MusicPlaylist(music:music,localization:l)
        playlistView.onSelect = { [weak self] index in
            guard let self else { return }
            if self.music.select(index) { self.popover.close() }
        }
        popover.contentViewController = playlistView; popover.behavior = .transient
        music.onChange = { [weak self] in
            guard let self else { return }
            self.refresh(); self.updateTimer()
            if self.popover.isShown { self.playlistView.reload(localization:self.l) }
        }
        music.onError = { [weak self] error in self?.showError("musicPlayFailed",error:error) }
        applyLanguage(language)
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) not supported") }

    func applyLanguage(_ language:String) {
        l = Localization(preference:language)
        window?.title = l["musicTitle"]
        progress.setAccessibilityLabel(l["musicSeek"])
        volume.setAccessibilityLabel(l["musicVolume"])
        elapsed.setAccessibilityLabel(l["musicElapsed"]); total.setAccessibilityLabel(l["musicDuration"])
        playlistView.reload(localization:l)
        refresh()
    }

    private func icon(_ button:ToolbarButton, _ symbol:String, _ label:String, size:CGFloat = 12) {
        button.toolTip = label; button.setAccessibilityLabel(label)
        if button.symbol != symbol {
            button.symbol = symbol
            if let image = NSImage(systemSymbolName:symbol,accessibilityDescription:label)?
                .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize:size,weight:.medium)) {
                button.image = Self.outlinedSymbol(image)
            }
        }
    }

    private static func outlinedSymbol(_ image:NSImage) -> NSImage {
        // Codex and this companion can have different themes; preserve both contrasting edges.
        func tinted(_ color:NSColor) -> NSImage {
            let result = NSImage(size:image.size)
            result.lockFocus()
            image.draw(in:NSRect(origin:.zero,size:image.size))
            color.setFill(); NSRect(origin:.zero,size:image.size).fill(using:.sourceIn)
            result.unlockFocus(); result.isTemplate = false
            return result
        }
        let white = tinted(.white), black = tinted(.black)
        let result = NSImage(size:NSSize(width:image.size.width+2,height:image.size.height+2))
        result.lockFocus()
        for x:CGFloat in [-0.7,0,0.7] { for y:CGFloat in [-0.7,0,0.7] {
            black.draw(at:NSPoint(x:1+x,y:1+y),from:.zero,operation:.sourceOver,fraction:1)
        } }
        white.draw(at:NSPoint(x:1,y:1),from:.zero,operation:.sourceOver,fraction:1)
        result.unlockFocus(); result.isTemplate = false
        result.accessibilityDescription = image.accessibilityDescription
        return result
    }

    func follow(_ target:CGRect?, visible:Bool, controlsVisible:Bool = true) {
        self.visible = visible
        if visible && controlsVisible, let target {
            let frame = WindowPolicy.musicRect(target)
            if window?.frame != frame { window?.setFrame(frame,display:true) }
            if window?.isVisible != true { window?.orderFrontRegardless() }
        } else { popover.close(); window?.orderOut(nil) }
        updateTimer()
    }

    private func updateTimer() {
        if visible && music.isPlaying {
            if timer == nil {
                let tick = Timer(timeInterval:1/30.0,repeats:true) { [weak self] _ in self?.sample() }
                timer = tick; RunLoop.main.add(tick,forMode:.common); sample()
            }
        } else { timer?.invalidate(); timer = nil; onLevel?(0) }
    }
    private func sample() {
        if window?.isVisible == true { refresh() }
        onLevel?(music.sampleStrength())
    }

    private func refresh() {
        openButton.isEnabled = !loadingFolder
        listButton.isEnabled = !music.playlist.isEmpty
        previousButton.isEnabled = music.canGoBack
        playButton.isEnabled = music.filename != nil
        nextButton.isEnabled = !music.playlist.isEmpty
        icon(openButton,loadingFolder ? "hourglass" : "folder",l[loadingFolder ? "musicScanning" : "musicOpen"])
        icon(listButton,"list.bullet",l["musicPlaylist"])
        listButton.toolTip = String(format:l["musicPlaylistCount"],music.playlist.count)+" · "+(music.filename ?? l["musicEmpty"])
        icon(modeButton,music.mode == .loop ? "repeat" : "shuffle",l[music.mode == .loop ? "musicLoop" : "musicShuffle"])
        modeButton.setAccessibilityValue(l[music.mode == .loop ? "musicLoop" : "musicShuffle"])
        icon(previousButton,"backward.end.fill",l["musicPrevious"])
        icon(playButton,music.isPlaying ? "pause.fill" : "play.fill",l[music.isPlaying ? "musicPause" : "musicPlay"],size:14)
        icon(nextButton,"forward.end.fill",l["musicNext"])
        icon(speaker,music.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill",l[music.volume == 0 ? "musicUnmute" : "musicMute"])
        progress.isEnabled = music.duration > 0
        progress.maxValue = music.duration > 0 ? music.duration : 1
        if !progress.isSeeking { progress.doubleValue = music.currentTime }
        updateTime(elapsed,seconds:music.currentTime); updateTime(total,seconds:music.duration)
        progress.toolTip = (music.filename ?? l["musicEmpty"])+" · "+elapsed.stringValue+" / "+total.stringValue
        if !volume.isSeeking { volume.doubleValue = Double(music.volume) }
        volume.toolTip = l["musicVolume"]+" · "+String(format:"%.0f%%",Double(music.volume)*100)
    }
    private func updateTime(_ field:NSTextField, seconds:Double) {
        let value = Self.timestamp(seconds)
        guard field.stringValue != value else { return }
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
        field.attributedStringValue = NSAttributedString(string:value,attributes:[
            .font:field.font!, .foregroundColor:NSColor.white, .strokeColor:NSColor.black,
            .strokeWidth:-3, .paragraphStyle:paragraph])
    }
    private static func timestamp(_ seconds:Double) -> String {
        let value = max(0,Int(seconds)); return String(format:"%d:%02d",value/60,value%60)
    }

    @objc private func chooseFolder() {
        guard !showingDialog && !loadingFolder, let window else { return }
        popover.close()
        let chooser = NSOpenPanel(); chooser.canChooseDirectories = true; chooser.canChooseFiles = false
        chooser.allowsMultipleSelection = false; chooser.title = l["musicOpen"]
        showingDialog = true
        chooser.beginSheetModal(for:window) { [weak self] response in
            guard let self else { return }
            self.showingDialog = false
            guard response == .OK, let folder = chooser.url else { return }
            self.loadingFolder = true; self.refresh()
            DispatchQueue.global(qos:.userInitiated).async {
                let result = Result { try MusicPlayer.audioFiles(in:folder) }
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.loadingFolder = false
                    do { try self.music.loadPlaylist(result.get()) }
                    catch MusicPlayer.FolderError.noAudio { self.showError("musicFolderEmpty",error:nil) }
                    catch { self.showError("musicLoadFailed",error:error) }
                    self.refresh()
                }
            }
        }
    }
    @objc private func showPlaylist() {
        if popover.isShown { popover.close(); return }
        playlistView.reload(localization:l)
        popover.contentSize = playlistView.preferredContentSize
        popover.show(relativeTo:listButton.bounds,of:listButton,preferredEdge:.minY)
    }
    private func showError(_ key:String, error:Error?) {
        guard !showingDialog, let window else { return }
        popover.close(); showingDialog = true
        let alert = NSAlert(); alert.messageText = l[key]
        alert.informativeText = error?.localizedDescription ?? l["musicRetry"]
        alert.addButton(withTitle:l["musicOK"])
        alert.beginSheetModal(for:window) { [weak self] _ in self?.showingDialog = false }
    }
    @objc private func togglePlaybackMode() { music.toggleMode() }
    @objc private func previous() { music.previous() }
    @objc private func next() { music.next() }
    @objc private func togglePlayback() { music.toggle() }
    @objc private func seek() { music.seek(progress.doubleValue) }
    @objc private func changeVolume() {
        if volume.doubleValue > 0 { lastVolume = volume.doubleValue }
        music.setVolume(volume.doubleValue)
    }
    @objc private func mute() {
        if music.volume > 0 { lastVolume = Double(music.volume); music.setVolume(0) }
        else { music.setVolume(lastVolume) }
    }
    func stop() { popover.close(); timer?.invalidate(); timer = nil; visible = false; music.stop() }
}
