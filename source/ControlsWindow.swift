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
    private let names = ["opacity", "saturation", "contrast", "brightness"]
    private let languagePicker = NSPopUpButton()
    private let note = NSTextField(wrappingLabelWithString:"")
    private let characterLabel = NSTextField(labelWithString:"")
    private let languageLabel = NSTextField(labelWithString:"")
    private var labels: [NSTextField] = []
    private var resetButton: NSButton!
    private var replayButton: NSButton!
    private var l: Localization { Localization(preference:appearance.language) }
    private let limits: [(Double,Double)] = [(0,100),(0,2),(0.5,2),(0.2,1.5)]

    init(appearance: AppearanceSettings) {
        self.appearance = appearance
        let panel = ControlsPanel(contentRect:NSRect(x:0,y:0,width:440,height:520),
            styleMask:[.titled,.closable,.utilityWindow,.nonactivatingPanel], backing:.buffered, defer:false)
        panel.title = Localization(preference:appearance.language)["panelTitle"]
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
        note.stringValue = l["note"]
        note.font = .systemFont(ofSize:12); note.textColor = .secondaryLabelColor
        root.addArrangedSubview(note)
        let languages = NSStackView(); languages.orientation = .horizontal; languages.spacing = 12
        languages.addArrangedSubview(languageLabel)
        languagePicker.addItems(withTitles:[l["system"], "English", "简体中文", "日本語"])
        languagePicker.target = self; languagePicker.action = #selector(languageChanged)
        languages.addArrangedSubview(languagePicker); root.addArrangedSubview(languages)
        let characters = NSStackView(); characters.orientation = .horizontal; characters.spacing = 12
        characters.addArrangedSubview(characterLabel)
        characterPicker.addItems(withTitles:[l["golden"], l["blue"]])
        characterPicker.target = self; characterPicker.action = #selector(characterChanged)
        characterPicker.setAccessibilityLabel(l["character"])
        characters.addArrangedSubview(characterPicker); root.addArrangedSubview(characters)
        for index in 0..<4 {
            let group = NSStackView(); group.orientation = .vertical; group.alignment = .leading; group.spacing = 7
            let row = NSStackView(); row.orientation = .horizontal; row.spacing = 8
            let label = NSTextField(labelWithString:l[names[index]]); label.font = .systemFont(ofSize:13,weight:.medium)
            let space = NSView(); space.setContentHuggingPriority(.defaultLow,for:.horizontal)
            let field = NSTextField(); field.tag = index; field.delegate = self
            field.alignment = .right; field.font = .monospacedDigitSystemFont(ofSize:13,weight:.regular)
            field.target = self; field.action = #selector(fieldCommitted(_:))
            field.setAccessibilityLabel(l[names[index]]+" · "+l["value"])
            field.widthAnchor.constraint(equalToConstant:66).isActive = true
            let unit = NSTextField(labelWithString:index == 0 ? "%" : "×")
            unit.textColor = .secondaryLabelColor; unit.widthAnchor.constraint(equalToConstant:18).isActive = true
            [label,space,field,unit].forEach { row.addArrangedSubview($0) }
            let slider = NSSlider(value:0,minValue:limits[index].0,maxValue:limits[index].1,target:self,action:#selector(sliderChanged(_:)))
            slider.tag = index; slider.isContinuous = true; slider.setAccessibilityLabel(l[names[index]])
            row.translatesAutoresizingMaskIntoConstraints = false; slider.translatesAutoresizingMaskIntoConstraints = false
            group.addArrangedSubview(row); group.addArrangedSubview(slider); root.addArrangedSubview(group)
            group.widthAnchor.constraint(equalTo:root.widthAnchor).isActive = true
            row.widthAnchor.constraint(equalTo:group.widthAnchor).isActive = true
            slider.widthAnchor.constraint(equalTo:group.widthAnchor).isActive = true
            fields.append(field); sliders.append(slider); labels.append(label)
        }
        let actions = NSStackView(); actions.orientation = .horizontal; actions.spacing = 10
        let reset = NSButton(title:l["reset"],target:self,action:#selector(resetAppearance))
        let replay = NSButton(title:l["replay"],target:self,action:#selector(replay))
        resetButton = reset; replayButton = replay
        reset.bezelStyle = .rounded; replay.bezelStyle = .rounded
        actions.addArrangedSubview(reset); actions.addArrangedSubview(replay); root.addArrangedSubview(actions)
        applyLanguage(); sync(); panel.initialFirstResponder = reset; panel.center()
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) not supported") }
    private func applyLanguage() {
        window?.title = l["panelTitle"]; note.stringValue = l["note"]
        characterLabel.stringValue = l["character"]; languageLabel.stringValue = l["language"]
        languagePicker.item(at:0)?.title = l["system"]
        languagePicker.setAccessibilityLabel(l["language"])
        characterPicker.item(at:0)?.title = l["golden"]; characterPicker.item(at:1)?.title = l["blue"]
        characterPicker.setAccessibilityLabel(l["character"])
        for index in 0..<4 {
            labels[index].stringValue = l[names[index]]
            fields[index].setAccessibilityLabel(l[names[index]]+" · "+l["value"])
            sliders[index].setAccessibilityLabel(l[names[index]])
        }
        resetButton.title = l["reset"]; replayButton.title = l["replay"]
    }
    @objc private func languageChanged() {
        appearance.language = Localization.choices[languagePicker.indexOfSelectedItem]
        applyLanguage(); sync(); onChange?(appearance)
    }
    private func sync() {
        languagePicker.selectItem(at:Localization.choices.firstIndex(of:appearance.language) ?? 0)
        characterPicker.selectItem(at:appearance.character == "blue-hime" ? 1 : 0)
        let values = [appearance.opacity*100,appearance.saturation,appearance.contrast,appearance.brightness]
        for index in 0..<4 {
            sliders[index].doubleValue = values[index]
            fields[index].stringValue = String(format:index == 0 ? "%.0f" : "%.2f",locale:Locale.current,values[index])
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
        let formatter = NumberFormatter(); formatter.locale = .current; formatter.numberStyle = .decimal
        guard let value = formatter.number(from:text)?.doubleValue else { sync(); return }
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
        let character = appearance.character, language = appearance.language
        appearance = .defaults; appearance.character = character; appearance.language = language; sync(); onChange?(appearance)
    }
    @objc private func replay() { onReplay?() }
}
