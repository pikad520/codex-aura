import AppKit
import WebKit
import Carbon

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    private var l: Localization { Localization(preference:appearance.language) }
    private var menuLabels: [String:NSMenuItem] = [:]
    private var failureKey: String?
    private var panel: OverlayPanel!
    private var web: WKWebView!
    private var status: NSStatusItem!
    private var toggleItem: NSMenuItem!
    private var musicControlsItem: NSMenuItem!
    private var ripplesItem: NSMenuItem!
    private var statusLine: NSMenuItem!
    private var timer: Timer?
    private var ready = false
    private var shown = false
    private var enabled = true
    private var musicControlsVisible = true
    private var ripplesEnabled = true
    private var appearance = AppearanceSettings.defaults
    private var controls: ControlsWindow?
    private var musicWindow: MusicWindow?
    private var clickRipples: ClickRipple!
    private var musicLevel = 0.0
    private var musicBridgeBusy = false
    private var lastTargetPID: pid_t?
    private var pendingSave: DispatchWorkItem?
    private var didLoadSettings = false
    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let storage = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Codex Aura")
    private let diagnosticMode = CommandLine.arguments.contains("--diagnostics") || FileManager.default.fileExists(atPath:
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Codex Aura/diagnostics-enabled").path)
    private var lastDiagnostic = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        let duplicates = NSRunningApplication.runningApplications(withBundleIdentifier: "local.codex.aura")
        if duplicates.contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil); return
        }
        let settingsData = try? Data(contentsOf:storage.appendingPathComponent("settings.json"))
        appearance = AppearanceSettings.load(settingsData)
        didLoadSettings = true
        let previous = settingsData.flatMap { try? JSONSerialization.jsonObject(with:$0) as? [String:Any] }
        let showNewControls = (previous?["controlsVersion"] as? Int ?? 0) < 1
        makeMenu()
        DistributedNotificationCenter.default().addObserver(self, selector:#selector(quit),
            name:NSNotification.Name("local.codex.aura.quit"), object:nil)
        panel = OverlayPanel(contentRect: NSRect(x:0, y:0, width:900, height:650),
            styleMask:[.borderless, .nonactivatingPanel], backing:.buffered, defer:false)
        panel.title = l["overlayTitle"]
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.ignoresMouseEvents = true; panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isReleasedWhenClosed = false; panel.isMovable = false
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.userContentController.add(self, name:"aura")
        let root = Bundle.main.resourceURL!.appendingPathComponent("Web")
        // file:// textures are origin-restricted by WebKit. Supply only our bundled images
        // as data URLs, without relaxing file-origin or network security settings.
        var textures: [String:String] = [:]
        for name in ["character.png", "closed-eye.png", "contours.png", "closed-contours.png", "blue-hime/open.png", "blue-hime/closed.png"] {
            if let data = try? Data(contentsOf:root.appendingPathComponent("assets/"+name)) {
                textures[name] = "data:image/png;base64,"+data.base64EncodedString()
            }
        }
        if let data = try? JSONSerialization.data(withJSONObject:textures), let json = String(data:data, encoding:.utf8) {
            config.userContentController.addUserScript(WKUserScript(source:"window.AURA_TEXTURES = \(json);", injectionTime:.atDocumentStart, forMainFrameOnly:true))
        }
        config.userContentController.addUserScript(WKUserScript(source:"window.AURA_INITIAL_APPEARANCE = \(appearance.json);", injectionTime:.atDocumentStart, forMainFrameOnly:true))
        web = WKWebView(frame:panel.contentView!.bounds, configuration:config)
        web.autoresizingMask = [.width, .height]
        web.setValue(false, forKey:"drawsBackground")
        web.underPageBackgroundColor = .clear
        web.navigationDelegate = self
        panel.contentView!.addSubview(web)
        clickRipples = ClickRipple(frame:panel.contentView!.bounds)
        panel.contentView!.addSubview(clickRipples)
        web.loadFileURL(root.appendingPathComponent("index.html"), allowingReadAccessTo:root)
        musicWindow = MusicWindow(language:appearance.language)
        musicWindow?.onLevel = { [weak self] level in
            self?.musicLevel = level; self?.flushMusicLevel()
        }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector:#selector(update),
            name:NSWorkspace.didActivateApplicationNotification, object:nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector:#selector(update),
            name:NSWorkspace.activeSpaceDidChangeNotification, object:nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector:#selector(update),
            name:NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object:nil)
        timer = Timer(timeInterval:0.2, target:self, selector:#selector(update), userInfo:nil, repeats:true)
        RunLoop.main.add(timer!, forMode:.common)
        installHotKey()
        update()
        if showNewControls { showControls() }
    }

    private func item(_ title: String, _ action: Selector?) -> NSMenuItem {
        let item = NSMenuItem(title:l[title], action:action, keyEquivalent:""); item.target = self; menuLabels[title] = item; return item
    }
    private func makeMenu() {
        status = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        status.button?.image = NSImage(systemSymbolName:"sun.max", accessibilityDescription:l["overlayTitle"])
        status.button?.toolTip = l["overlayTitle"]
        let menu = NSMenu()
        statusLine = item("waiting", nil); menu.addItem(statusLine)
        menu.addItem(.separator())
        toggleItem = item("hide", #selector(toggle)); menu.addItem(toggleItem)
        menu.addItem(item("replay", #selector(replay)))
        menu.addItem(item("controls", #selector(showControls)))
        musicControlsItem = item("hideMusicControls", #selector(toggleMusicControls)); menu.addItem(musicControlsItem)
        ripplesItem = item("disableRipples", #selector(toggleRipples)); menu.addItem(ripplesItem)
        menu.addItem(.separator())
        menu.addItem(item("help", #selector(showReadme)))
        menu.addItem(item("quit", #selector(quit)))
        status.menu = menu
    }

    private func refreshLanguage() {
        for (key,item) in menuLabels { item.title = l[key] }
        toggleItem.title = l[enabled ? "hide" : "show"]
        musicControlsItem.title = l[musicControlsVisible ? "hideMusicControls" : "showMusicControls"]
        ripplesItem.title = l[ripplesEnabled ? "disableRipples" : "enableRipples"]
        status.button?.toolTip = l["overlayTitle"]
        status.button?.image?.accessibilityDescription = l["overlayTitle"]
        panel.title = l["overlayTitle"]
        musicWindow?.applyLanguage(appearance.language)
        update()
    }

    private func installHotKey() {
        var spec = EventTypeSpec(eventClass:OSType(kEventClassKeyboard), eventKind:UInt32(kEventHotKeyPressed))
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        let result = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            Unmanaged<AppDelegate>.fromOpaque(context).takeUnretainedValue().toggle()
            return noErr
        }, 1, &spec, pointer, &eventHandler)
        guard result == noErr else { return }
        let id = EventHotKeyID(signature:0x41555241, id:1)
        if RegisterEventHotKey(UInt32(kVK_ANSI_G), UInt32(controlKey|optionKey|cmdKey), id,
            GetApplicationEventTarget(), 0, &hotKey) == noErr {
            toggleItem.keyEquivalent = "g"; toggleItem.keyEquivalentModifierMask = [.control,.option,.command]
        }
    }

    private func targetRect(pid: pid_t) -> CGRect? {
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly,.excludeDesktopElements], kCGNullWindowID) as? [[String:Any]] else { return nil }
        for info in windows {
            guard (info[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == pid,
                  (info[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
                  (info[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1 > 0,
                  let dict = info[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation:dict), rect.width >= 300, rect.height >= 200 else { continue }
            return WindowPolicy.appKitRect(rect, primaryTop:NSScreen.screens.first?.frame.maxY ?? 0)
        }
        return nil
    }

    @objc func update() {
        let front = NSWorkspace.shared.frontmostApplication
        let isTarget = front?.bundleIdentifier == WindowPolicy.targetBundle
        if isTarget { lastTargetPID = front?.processIdentifier }
        let ownUI = controls?.window?.isVisible == true || musicWindow?.presentingDialog == true
        let adjusting = front?.bundleIdentifier == "local.codex.aura" && ownUI
        let targetPID = isTarget ? front?.processIdentifier : adjusting ? lastTargetPID : nil
        let rect = targetPID.flatMap { targetRect(pid:$0) }
        let visible = ready && WindowPolicy.shouldShow(enabled:enabled,
            frontBundle:(isTarget || adjusting) ? WindowPolicy.targetBundle : front?.bundleIdentifier,
            hasWindow:rect != nil)
        if visible, let rect {
            if panel.frame != rect { panel.setFrame(rect, display:true) }
            if !shown { panel.orderFrontRegardless() }
        } else if shown { panel.orderOut(nil) }
        if shown != visible {
            shown = visible
            web.evaluateJavaScript("window.aura?.setActive(\(visible))", completionHandler:nil)
        }
        musicWindow?.follow(rect,visible:visible,controlsVisible:musicControlsVisible)
        clickRipples.setActive(visible && ripplesEnabled && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        statusLine.title = l[failureKey ?? (!ready ? "preparing" : !enabled ? "paused" : visible ? "playing" : "waiting")]
        if diagnosticMode, Date().timeIntervalSince(lastDiagnostic) > 1 {
            lastDiagnostic = Date()
            let musicState: [String:Any] = ["playing":musicWindow?.music.isPlaying ?? false, "time":musicWindow?.music.currentTime ?? 0,
                "duration":musicWindow?.music.duration ?? 0, "volume":musicWindow?.music.volume ?? 0,
                "level":musicLevel, "frame":(musicWindow?.window?.frame).map(NSStringFromRect) ?? "",
                "visible":musicWindow?.window?.isVisible ?? false, "isKey":musicWindow?.window?.isKeyWindow ?? false]
            let base: [String:Any] = ["visible":visible, "enabled":enabled, "ready":ready,
                "frontBundle":front?.bundleIdentifier ?? "", "ignoresMouseEvents":panel.ignoresMouseEvents,
                "canBecomeKey":panel.canBecomeKey, "isKey":panel.isKeyWindow,
                "frame":NSStringFromRect(panel.frame), "targetFrame":rect.map(NSStringFromRect) ?? "", "appearance":appearance.json,
                "music":musicState]
            web.evaluateJavaScript("window.aura?.status()") { value, _ in
                var data = base; data["renderer"] = value; data["timestamp"] = Date().timeIntervalSince1970
                self.writeJSON(data, name:"diagnostics.json")
            }
        }
    }
    private func flushMusicLevel() {
        guard ready && shown && !musicBridgeBusy else { return }
        let level = musicLevel; musicBridgeBusy = true
        // One bridge call at a time; slow WebKit must not accumulate stale audio samples.
        web.evaluateJavaScript("window.aura?.setMusicLevel(\(level))") { [weak self] _, _ in
            guard let self else { return }
            self.musicBridgeBusy = false
            if self.musicLevel != level { self.flushMusicLevel() }
        }
    }
    private func writeJSON(_ value: [String:Any], name:String) {
        try? FileManager.default.createDirectory(at:storage, withIntermediateDirectories:true)
        if let data = try? JSONSerialization.data(withJSONObject:value, options:[.sortedKeys,.prettyPrinted]) {
            try? data.write(to:storage.appendingPathComponent(name), options:.atomic)
        }
    }
    @objc func toggle() { enabled.toggle(); toggleItem.title = l[enabled ? "hide" : "show"]; update() }
    @objc func toggleMusicControls() {
        musicControlsVisible.toggle()
        musicControlsItem.title = l[musicControlsVisible ? "hideMusicControls" : "showMusicControls"]
        update()
    }
    @objc func toggleRipples() {
        ripplesEnabled.toggle()
        ripplesItem.title = l[ripplesEnabled ? "disableRipples" : "enableRipples"]
        update()
    }
    @objc func replay() { web.evaluateJavaScript("window.aura?.replay()", completionHandler:nil) }
    private func saveAppearance() {
        writeJSON(["version":2, "controlsVersion":1, "opacity":appearance.opacity, "saturation":appearance.saturation,
            "contrast":appearance.contrast, "brightness":appearance.brightness, "character":appearance.character, "language":appearance.language], name:"settings.json")
    }
    @objc func showControls() {
        if controls == nil {
            controls = ControlsWindow(appearance:appearance)
            controls?.onChange = { [weak self] value in
                guard let self else { return }
                let languageChanged = self.appearance.language != value.language
                self.appearance = value
                if languageChanged { self.refreshLanguage() }
                else { self.web.evaluateJavaScript("window.aura?.setAppearance(\(value.json), true)", completionHandler:nil) }
                self.pendingSave?.cancel()
                let save = DispatchWorkItem { [weak self] in self?.saveAppearance() }
                self.pendingSave = save
                DispatchQueue.main.asyncAfter(deadline:.now()+0.25, execute:save)
            }
            controls?.onReplay = { [weak self] in self?.replay() }
        }
        // Showing controls must not divert typing from Codex into the first numeric field.
        controls?.window?.orderFrontRegardless()
        controls?.window?.makeMain()
        saveAppearance()
        update()
    }
    func applicationShouldHandleReopen(_ sender:NSApplication, hasVisibleWindows flag:Bool) -> Bool {
        showControls(); return true
    }
    @objc func showReadme() { if let url = Bundle.main.url(forResource:l.helpFile, withExtension:"md") { NSWorkspace.shared.open(url) } }
    @objc func quit() { NSApp.terminate(nil) }
    func userContentController(_ userContentController:WKUserContentController, didReceive message:WKScriptMessage) {
        guard let body = message.body as? [String:Any], let state = body["status"] as? String else { return }
        if state == "ready" {
            ready = true
            web.evaluateJavaScript("window.aura.setAppearance(\(appearance.json))", completionHandler:nil)
            update()
        } else {
            timer?.invalidate(); panel.orderOut(nil); musicWindow?.follow(nil,visible:false)
            clickRipples.setActive(false)
            failureKey = "loadFailed"; statusLine.title = l["loadFailed"]
            if diagnosticMode { writeJSON(body, name:"renderer-error.json") }
            NSLog("Codex Aura renderer failed: %@", String(describing:body["message"]))
        }
    }
    func webView(_ webView:WKWebView, decidePolicyFor navigationAction:WKNavigationAction,
                 decisionHandler:@escaping (WKNavigationActionPolicy)->Void) {
        decisionHandler(navigationAction.request.url?.isFileURL == true ? .allow : .cancel)
    }
    func webViewWebContentProcessDidTerminate(_ webView:WKWebView) {
        ready = false; failureKey = "processStopped"; update()
        if diagnosticMode { writeJSON(["error":"WebContentProcessDidTerminate"], name:"renderer-error.json") }
        timer?.invalidate()
    }
    func applicationWillTerminate(_ notification:Notification) {
        pendingSave?.cancel(); if didLoadSettings { saveAppearance() }
        musicWindow?.stop()
        clickRipples?.setActive(false)
        timer?.invalidate(); if let hotKey { UnregisterEventHotKey(hotKey) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

let app = NSApplication.shared
if CommandLine.arguments.contains("--quit") {
    DistributedNotificationCenter.default().postNotificationName(NSNotification.Name("local.codex.aura.quit"), object:nil, userInfo:nil, deliverImmediately:true)
    exit(0)
}
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
