import AVFoundation
import UniformTypeIdentifiers

final class MusicPlayer: NSObject, AVAudioPlayerDelegate {
    var onChange: (() -> Void)?
    var onError: ((Error?) -> Void)?
    private var player: AVAudioPlayer?
    private var finished = false
    private(set) var filename: String?
    private(set) var volume: Float = 0.5
    private(set) var playlist: [URL] = []
    private(set) var currentIndex: Int?
    private(set) var mode = Mode.loop
    private var history: [Int] = []

    enum Mode { case loop, shuffle }
    enum FolderError: Error { case noAudio }
    var canGoBack: Bool { !history.isEmpty }

    var isPlaying: Bool { player?.isPlaying == true }
    var duration: Double { player?.duration ?? 0 }
    var currentTime: Double { finished ? duration : player?.currentTime ?? 0 }

    func load(_ url: URL) throws {
        // Prepare a replacement first: an unreadable/unsupported file must not stop the old track.
        let replacement = try prepare(url)
        playlist = []; currentIndex = nil; history = []
        install(replacement, index:nil)
    }

    private func prepare(_ url: URL) throws -> AVAudioPlayer {
        let replacement = try AVAudioPlayer(contentsOf:url)
        guard replacement.duration > 0, replacement.prepareToPlay() else {
            throw CocoaError(.fileReadCorruptFile)
        }
        replacement.isMeteringEnabled = true
        replacement.volume = volume
        replacement.delegate = self
        return replacement
    }

    private func install(_ replacement: AVAudioPlayer, index: Int?) {
        player?.stop()
        player = replacement; finished = false; filename = replacement.url?.lastPathComponent
        currentIndex = index
        onChange?()
    }

    static func audioFiles(in folder: URL) throws -> [URL] {
        let files = try FileManager.default.contentsOfDirectory(at:folder, includingPropertiesForKeys:[.isRegularFileKey], options:[.skipsHiddenFiles])
        return sorted(files.filter {
            (try? $0.resourceValues(forKeys:[.isRegularFileKey]).isRegularFile) == true &&
                UTType(filenameExtension:$0.pathExtension.lowercased())?.conforms(to:.audio) == true
        })
    }

    static func sorted(_ files: [URL]) -> [URL] {
        let keys = files.map { url -> (url:URL, group:Int, key:String) in
            let name = url.lastPathComponent.folding(options:[.widthInsensitive], locale:Locale(identifier:"en_US_POSIX"))
            let latin = name.folding(options:[.diacriticInsensitive,.caseInsensitive],locale:Locale(identifier:"en_US_POSIX"))
            let first = name.unicodeScalars.first?.value ?? 0
            let ascii = latin.unicodeScalars.first?.value ?? 0
            if (97...122).contains(ascii) { return (url,0,latin) }
            if (0x3400...0x9fff).contains(first) || (0xf900...0xfaff).contains(first) || (0x20000...0x2fa1f).contains(first) {
                let pinyin = name.applyingTransform(.mandarinToLatin,reverse:false) ?? name
                return (url,1,pinyin.folding(options:[.diacriticInsensitive,.caseInsensitive],locale:Locale(identifier:"zh_CN")))
            }
            if (0x3041...0x3096).contains(first) || (0x309d...0x309f).contains(first) ||
                (0x30a1...0x30fa).contains(first) || (0x30fc...0x30ff).contains(first) {
                return (url,2,name.applyingTransform(.hiraganaToKatakana,reverse:true) ?? name)
            }
            return (url,3,name)
        }
        return keys.sorted { a,b in
            if a.group != b.group { return a.group < b.group }
            let order = a.key.compare(b.key,options:[.caseInsensitive,.numeric],locale:Locale(identifier:a.group == 2 ? "ja_JP" : "en_US_POSIX"))
            if order != .orderedSame { return order == .orderedAscending }
            return a.url.lastPathComponent < b.url.lastPathComponent
        }.map(\.url)
    }

    func loadPlaylist(_ files: [URL]) throws {
        guard !files.isEmpty else { throw FolderError.noAudio }
        var lastError: Error = FolderError.noAudio
        for index in files.indices {
            do {
                let replacement = try prepare(files[index])
                guard replacement.play() else { throw CocoaError(.fileReadUnknown) }
                playlist = files; history = []
                install(replacement,index:index)
                return
            } catch { lastError = error }
        }
        throw lastError
    }

    func toggleMode() { mode = mode == .loop ? .shuffle : .loop; onChange?() }

    @discardableResult func select(_ index: Int) -> Bool {
        guard playlist.indices.contains(index) else { return false }
        if index == currentIndex { return isPlaying || toggle() }
        return advance([index])
    }

    @discardableResult func next() -> Bool {
        guard let index = currentIndex, !playlist.isEmpty else { return false }
        let indices = mode == .shuffle && playlist.count > 1
            ? playlist.indices.filter { $0 != index }.shuffled() + [index]
            : (1...playlist.count).map { (index+$0)%playlist.count }
        return advance(indices)
    }

    @discardableResult func previous() -> Bool {
        let saved = history
        var candidates: [Int] = []
        while let index = history.popLast() {
            candidates.append(index)
            if advance([index],recordHistory:false,reportError:false) { return true }
        }
        history = saved
        if !candidates.isEmpty { onError?(nil) }
        return false
    }

    private func advance(_ indices: [Int], recordHistory: Bool = true, reportError: Bool = true) -> Bool {
        var lastError: Error?
        for index in indices {
            do {
                let replacement = try prepare(playlist[index])
                guard replacement.play() else { throw CocoaError(.fileReadUnknown) }
                if recordHistory, let currentIndex, currentIndex != index { history.append(currentIndex) }
                install(replacement,index:index)
                return true
            } catch { lastError = error }
        }
        if reportError { onError?(lastError) }
        return false
    }

    @discardableResult func toggle() -> Bool {
        guard let player else { return false }
        if player.isPlaying { player.pause() }
        else {
            if finished || player.currentTime >= player.duration { player.currentTime = 0; finished = false }
            guard player.play() else { onError?(nil); return false }
        }
        onChange?(); return true
    }

    func seek(_ seconds: Double) {
        guard let player, seconds.isFinite else { return }
        let wasPlaying = player.isPlaying
        let position = min(player.duration, max(0, seconds))
        finished = position >= player.duration
        if finished { player.pause() }
        player.currentTime = position
        if wasPlaying && !finished && !player.isPlaying && !player.play() { onError?(nil) }
        onChange?()
    }

    func setVolume(_ value: Double) {
        guard value.isFinite else { return }
        volume = Float(min(1, max(0, value)))
        player?.volume = volume
        onChange?()
    }

    static func strength(decibels: Double, volume: Float) -> Double {
        guard decibels.isFinite, volume.isFinite else { return 0 }
        // A soft noise floor avoids amplifying silence; log-scale mapping retains quiet music.
        let value = min(1, max(0, (decibels+50)/44))
        return value*value*(3-2*value)*sqrt(Double(min(1, max(0, volume))))
    }

    func sampleStrength() -> Double {
        guard let player, player.isPlaying, volume > 0 else { return 0 }
        player.updateMeters()
        let power = (0..<player.numberOfChannels).reduce(0.0) {
            $0 + pow(10, Double(player.averagePower(forChannel:$1))/10)
        } / Double(max(1, player.numberOfChannels))
        return Self.strength(decibels:10*log10(max(power, 1e-16)), volume:volume)
    }

    func stop() {
        player?.stop(); player?.currentTime = 0; finished = false
        onChange?()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard player === self.player else { return }
        finished = flag
        if flag, currentIndex != nil { if !next() { onChange?() }; return }
        onChange?()
        if !flag { onError?(nil) }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        guard player === self.player else { return }
        player.stop(); finished = false
        onChange?(); onError?(error)
    }
}
