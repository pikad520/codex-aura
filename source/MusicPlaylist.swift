import AppKit

final class MusicPlaylist: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    var onSelect: ((Int) -> Void)?
    private let music: MusicPlayer
    private var l: Localization
    private let heading = NSTextField(labelWithString:"")
    private let table = NSTableView()
    private let scroll = NSScrollView()
    private var scrollHeight: NSLayoutConstraint!

    init(music:MusicPlayer, localization:Localization) {
        self.music = music; l = localization
        super.init(nibName:nil,bundle:nil)
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) not supported") }

    override func loadView() {
        view = NSView(frame:NSRect(x:0,y:0,width:320,height:204))
        heading.font = .systemFont(ofSize:12,weight:.semibold)
        heading.translatesAutoresizingMaskIntoConstraints = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.drawsBackground = false; scroll.hasVerticalScroller = true; scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay; scroll.borderType = .noBorder
        table.headerView = nil; table.rowHeight = 32; table.intercellSpacing = .zero
        table.style = .plain
        table.backgroundColor = .clear; table.selectionHighlightStyle = .regular
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        let column = NSTableColumn(identifier:NSUserInterfaceItemIdentifier("song"))
        column.width = 296; table.addTableColumn(column)
        table.dataSource = self; table.delegate = self; table.target = self; table.action = #selector(selectSong)
        scroll.documentView = table
        view.addSubview(heading); view.addSubview(scroll)
        scrollHeight = scroll.heightAnchor.constraint(equalToConstant:160)
        NSLayoutConstraint.activate([
            heading.leadingAnchor.constraint(equalTo:view.leadingAnchor,constant:12),
            heading.topAnchor.constraint(equalTo:view.topAnchor,constant:10),
            heading.heightAnchor.constraint(equalToConstant:18),
            scroll.leadingAnchor.constraint(equalTo:view.leadingAnchor,constant:8),
            scroll.trailingAnchor.constraint(equalTo:view.trailingAnchor,constant:-8),
            scroll.topAnchor.constraint(equalTo:heading.bottomAnchor,constant:8),
            scroll.bottomAnchor.constraint(equalTo:view.bottomAnchor,constant:-8),scrollHeight
        ])
    }

    func reload(localization:Localization) {
        l = localization; _ = view
        let height = CGFloat(min(5,music.playlist.count))*32
        scrollHeight.constant = height
        preferredContentSize = NSSize(width:320,height:height+44)
        view.setFrameSize(preferredContentSize)
        heading.stringValue = String(format:l["musicPlaylistCount"],music.playlist.count)
        table.setAccessibilityLabel(l["musicPlaylist"])
        table.reloadData()
        if let current = music.currentIndex { table.selectRowIndexes(IndexSet(integer:current),byExtendingSelection:false) }
        view.layoutSubtreeIfNeeded()
    }
    func numberOfRows(in tableView:NSTableView) -> Int { music.playlist.count }
    func tableView(_ tableView:NSTableView, viewFor tableColumn:NSTableColumn?, row:Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("songCell")
        let cell: NSTableCellView
        if let reused = tableView.makeView(withIdentifier:identifier,owner:self) as? NSTableCellView { cell = reused }
        else {
            cell = NSTableCellView(); cell.identifier = identifier
            let image = NSImageView(); image.translatesAutoresizingMaskIntoConstraints = false
            let text = NSTextField(labelWithString:""); text.translatesAutoresizingMaskIntoConstraints = false
            text.lineBreakMode = .byTruncatingMiddle
            cell.addSubview(image); cell.addSubview(text); cell.imageView = image; cell.textField = text
            NSLayoutConstraint.activate([
                image.leadingAnchor.constraint(equalTo:cell.leadingAnchor,constant:8),
                image.centerYAnchor.constraint(equalTo:cell.centerYAnchor),
                image.widthAnchor.constraint(equalToConstant:14),image.heightAnchor.constraint(equalToConstant:14),
                text.leadingAnchor.constraint(equalTo:image.trailingAnchor,constant:9),
                text.trailingAnchor.constraint(equalTo:cell.trailingAnchor,constant:-8),
                text.centerYAnchor.constraint(equalTo:cell.centerYAnchor)
            ])
        }
        let current = music.currentIndex == row
        let url = music.playlist[row]
        cell.textField?.stringValue = url.deletingPathExtension().lastPathComponent
        cell.textField?.font = .systemFont(ofSize:12,weight:current ? .semibold : .regular)
        cell.textField?.textColor = .labelColor; cell.toolTip = url.lastPathComponent
        cell.setAccessibilityLabel(url.lastPathComponent)
        cell.imageView?.image = current ? NSImage(systemSymbolName:music.isPlaying ? "speaker.wave.2.fill" : "checkmark",accessibilityDescription:l["musicCurrent"]):nil
        cell.imageView?.contentTintColor = .controlAccentColor
        return cell
    }
    @objc private func selectSong() {
        guard music.playlist.indices.contains(table.selectedRow) else { return }
        onSelect?(table.selectedRow)
    }
}
