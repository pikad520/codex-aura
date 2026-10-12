import AppKit

private final class ControlsPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class ControlsWindow: NSWindowController, NSTextFieldDelegate {
    var onChange: ((AppearanceSettings)->Void)?
    var onReplay: (()->Void)?
    private var appearance: AppearanceSettings
    private var sliders: [NSSlider] = []
    private var fields: [NSTextField] = []
    private let characterPicker = NSPopUpButton()
    private let names = ["实际不透明度", "饱和度", "对比度", "亮度"]
    private let limits: [(Double,Double)] = [(0,100),(0,2),(0.5,2),(0.2,1.5)]

    init(appearance: AppearanceSettings) {
        self.appearance = appearance
        let panel = ControlsPanel(contentRect:NSRect(x:0,y:0,width:400,height:465),
            styleMask:[.titled,.closable,.utilityWindow,.nonactivatingPanel], backing:.buffered, defer:false)
        panel.title = "曦光 · 调色控制面板"
        panel.level = NSWindow.Level(rawValue:NSWindow.Level.floating.rawValue+1)
        panel.collectionBehavior = [.moveToActiveSpace,.fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false
        super.init(window:panel)

        let root = NSStackView(); root.orientation = .vertical; root.alignment = .leading; root.spacing = 20
        root.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView!.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo:panel.contentView!.leadingAnchor,constant:24),
            root.trailingAnchor.constraint(equalTo:panel.contentView!.trailingAnchor,constant:-24),
            root.topAnchor.constraint(equalTo:panel.contentView!.topAnchor,constant:22)
        ])
        let note = NSTextField(wrappingLabelWithString:"拖动滑块或输入数值，实时生效并自动保存。")
        note.font = .systemFont(ofSize:12); note.textColor = .secondaryLabelColor
        root.addArrangedSubview(note)
        let characters = NSStackView(); characters.orientation = .horizontal; characters.spacing = 12
        characters.addArrangedSubview(NSTextField(labelWithString:"角色"))
        characterPicker.addItems(withTitles:["金发 · 大波浪", "蓝发 · 公主切"])
        characterPicker.target = self; characterPicker.action = #selector(characterChanged)
        characterPicker.setAccessibilityLabel("角色")
        characters.addArrangedSubview(characterPicker); root.addArrangedSubview(characters)
        for index in 0..<4 {
            let group = NSStackView(); group.orientation = .vertical; group.alignment = .leading; group.spacing = 7
            let row = NSStackView(); row.orientation = .horizontal; row.spacing = 8
            let label = NSTextField(labelWithString:names[index]); label.font = .systemFont(ofSize:13,weight:.medium)
            let space = NSView(); space.setContentHuggingPriority(.defaultLow,for:.horizontal)
            let field = NSTextField(); field.tag = index; field.delegate = self
            field.alignment = .right; field.font = .monospacedDigitSystemFont(ofSize:13,weight:.regular)
            field.target = self; field.action = #selector(fieldCommitted(_:))
            field.setAccessibilityLabel(names[index]+"数值")
            field.widthAnchor.constraint(equalToConstant:66).isActive = true
            let unit = NSTextField(labelWithString:index == 0 ? "%" : "倍")
            unit.textColor = .secondaryLabelColor; unit.widthAnchor.constraint(equalToConstant:18).isActive = true
            [label,space,field,unit].forEach { row.addArrangedSubview($0) }
            let slider = NSSlider(value:0,minValue:limits[index].0,maxValue:limits[index].1,target:self,action:#selector(sliderChanged(_:)))
            slider.tag = index; slider.isContinuous = true; slider.setAccessibilityLabel(names[index])
            row.translatesAutoresizingMaskIntoConstraints = false; slider.translatesAutoresizingMaskIntoConstraints = false
            group.addArrangedSubview(row); group.addArrangedSubview(slider); root.addArrangedSubview(group)
            group.widthAnchor.constraint(equalTo:root.widthAnchor).isActive = true
            row.widthAnchor.constraint(equalTo:group.widthAnchor).isActive = true
            slider.widthAnchor.constraint(equalTo:group.widthAnchor).isActive = true
            fields.append(field); sliders.append(slider)
        }
        let actions = NSStackView(); actions.orientation = .horizontal; actions.spacing = 10
        let reset = NSButton(title:"恢复默认",target:self,action:#selector(resetAppearance))
        let replay = NSButton(title:"重播开场",target:self,action:#selector(replay))
        reset.bezelStyle = .rounded; replay.bezelStyle = .rounded
        actions.addArrangedSubview(reset); actions.addArrangedSubview(replay); root.addArrangedSubview(actions)
        sync(); panel.initialFirstResponder = reset; panel.center()
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) not supported") }
    private func sync() {
        characterPicker.selectItem(at:appearance.character == "blue-hime" ? 1 : 0)
        let values = [appearance.opacity*100,appearance.saturation,appearance.contrast,appearance.brightness]
        for index in 0..<4 {
            sliders[index].doubleValue = values[index]
            fields[index].stringValue = String(format:index == 0 ? "%.0f" : "%.2f",values[index])
        }
    }
    private func commit(_ value:Double, index:Int) {
        guard value.isFinite else { sync(); return }
        let rounded = index == 0 ? value.rounded() : (value*100).rounded()/100
        switch index {
        case 0: appearance.opacity = rounded/100
        case 1: appearance.saturation = rounded
        case 2: appearance.contrast = rounded
        default: appearance.brightness = rounded
        }
        appearance.normalize(); sync(); onChange?(appearance)
    }
    @objc private func sliderChanged(_ sender:NSSlider) { commit(sender.doubleValue,index:sender.tag) }
    @objc private func fieldCommitted(_ sender:NSTextField) {
        let text = sender.stringValue.trimmingCharacters(in:.whitespacesAndNewlines)
        guard let value = Double(text) else { sync(); return }
        commit(value,index:sender.tag)
    }
    func controlTextDidEndEditing(_ notification:Notification) {
        if let field = notification.object as? NSTextField { fieldCommitted(field) }
    }
    @objc private func characterChanged() {
        appearance.character = characterPicker.indexOfSelectedItem == 1 ? "blue-hime" : "golden"
        onChange?(appearance)
    }
    @objc private func resetAppearance() {
        let character = appearance.character
        appearance = .defaults; appearance.character = character; sync(); onChange?(appearance)
    }
    @objc private func replay() { onReplay?() }
}
