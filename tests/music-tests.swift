import Foundation
import AVFoundation

@main struct Tests {
    static func wait(_ seconds: Double) { RunLoop.current.run(until:Date().addingTimeInterval(seconds)) }
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:directory) }
        let file = directory.appendingPathComponent("test.wav")
        let format = AVAudioFormat(standardFormatWithSampleRate:44100,channels:2)!
        let buffer = AVAudioPCMBuffer(pcmFormat:format,frameCapacity:44100*3)!
        buffer.frameLength = buffer.frameCapacity
        // Silence, quiet and loud sections exercise real decoding and level metering.
        for i in 0..<Int(buffer.frameLength) {
            let amplitude: Float = i < 22050 ? 0 : i < 66150 ? 0.01 : 0.7
            buffer.floatChannelData![0][i] = amplitude*sin(Float(i)*2*Float.pi*220/44100)
            buffer.floatChannelData![1][i] = buffer.floatChannelData![0][i]
        }
        var settings = format.settings; settings[AVLinearPCMIsNonInterleaved] = false
        do {
            let writer = try AVAudioFile(forWriting:file,settings:settings)
            try writer.write(from:buffer)
        } // Close the writer so the WAV duration/header is finalized before playback.
        let player = MusicPlayer()
        var changes = 0, errors = 0
        player.onChange = { changes += 1 }; player.onError = { _ in errors += 1 }
        assert(!player.toggle() && player.duration == 0 && player.sampleStrength() == 0)
        try player.load(file)
        assert(player.filename == "test.wav" && !player.isPlaying && abs(player.duration-3)<0.01)
        assert(player.volume == 0.5)
        player.setVolume(0.02) // Very quiet during the brief real-output meter check.
        player.seek(0.6); assert(player.toggle()); wait(0.3)
        let quiet = player.sampleStrength()
        assert(player.currentTime > 0.8 && player.isPlaying)
        player.seek(1.8); wait(0.3)
        let loud = player.sampleStrength()
        assert(loud > quiet && loud > 0, "Actual decoded loud audio must drive stronger motion")
        player.setVolume(0); assert(player.sampleStrength() == 0)
        assert(player.toggle()); let paused = player.currentTime; wait(0.12)
        assert(!player.isPlaying && abs(player.currentTime-paused)<0.02 && player.sampleStrength() == 0)
        player.seek(0.9); assert(abs(player.currentTime-0.9)<0.02 && !player.isPlaying)
        player.seek(.nan); assert(abs(player.currentTime-0.9)<0.02)
        do { try player.load(directory.appendingPathComponent("missing.mp3")); assertionFailure("Missing file loaded") }
        catch { assert(player.filename == "test.wav" && abs(player.currentTime-0.9)<0.02) }
        let corrupt = directory.appendingPathComponent("corrupt.mp3")
        try Data("invalid audio".utf8).write(to:corrupt)
        do { try player.load(corrupt); assertionFailure("Corrupt file loaded") }
        catch { assert(player.filename == "test.wav") }
        player.setVolume(-1); assert(player.volume == 0)
        player.setVolume(2); assert(player.volume == 1)
        player.setVolume(.nan); assert(player.volume == 1)
        player.setVolume(0)
        player.seek(player.duration); assert(!player.isPlaying && player.currentTime == player.duration)
        assert(player.toggle()); wait(0.1); assert(player.currentTime < 0.3 && player.isPlaying)
        player.seek(2.85); wait(0.4)
        assert(!player.isPlaying && player.currentTime == player.duration, "Natural EOF retains final progress")
        assert(player.toggle()); wait(0.1); assert(player.isPlaying && player.currentTime < 0.3)
        player.stop(); assert(!player.isPlaying && player.currentTime == 0 && player.sampleStrength() == 0)
        assert(changes > 10 && errors == 0)
        assert(MusicPlayer.strength(decibels:-160,volume:1) == 0)
        assert(MusicPlayer.strength(decibels:0,volume:1) == 1)
        assert(MusicPlayer.strength(decibels:0,volume:0) == 0)
        assert(MusicPlayer.strength(decibels:.nan,volume:1) == 0)
        let names = ["🎵.wav","さくら.wav","Zulu.wav","中.wav","カキ.wav","a10.wav","1.wav","波.wav","あさ.wav","A2.wav","阿尔法.wav"]
        let sortedNames = MusicPlayer.sorted(names.map { directory.appendingPathComponent($0) }).map(\.lastPathComponent)
        assert(Array(sortedNames.prefix(9)) ==
            ["A2.wav","a10.wav","Zulu.wav","阿尔法.wav","波.wav","中.wav","あさ.wav","カキ.wav","さくら.wav"] && Set(sortedNames.suffix(2)) == ["1.wav","🎵.wav"],
            "Latin, pinyin, gojuon and other filenames have the requested group order")
        let folder = directory.appendingPathComponent("playlist")
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        for name in ["あさ.wav","阿尔法.wav","Alpha.WAV",".hidden.wav"] {
            try FileManager.default.copyItem(at:file,to:folder.appendingPathComponent(name))
        }
        let nested = folder.appendingPathComponent("nested")
        try FileManager.default.createDirectory(at:nested,withIntermediateDirectories:true)
        try FileManager.default.copyItem(at:file,to:nested.appendingPathComponent("Nested.wav"))
        try Data("not audio".utf8).write(to:folder.appendingPathComponent("README.txt"))
        let songs = try MusicPlayer.audioFiles(in:folder)
        assert(songs.map(\.lastPathComponent) == ["Alpha.WAV","阿尔法.wav","あさ.wav"], "Scan top-level audio only, including upper-case extensions")
        try player.loadPlaylist(songs)
        assert(player.isPlaying && player.currentIndex == 0 && !player.canGoBack, "Folder autoplays the first ordered song")
        assert(player.next() && player.currentIndex == 1 && player.canGoBack)
        assert(player.next() && player.currentIndex == 2)
        assert(player.next() && player.currentIndex == 0, "Ordered playlist wraps")
        assert(player.previous() && player.currentIndex == 2, "Previous follows actual history")
        player.seek(0.7); let modeTime = player.currentTime, modeIndex = player.currentIndex
        player.toggleMode()
        assert(player.mode == .shuffle && player.isPlaying && player.currentIndex == modeIndex && abs(player.currentTime-modeTime)<0.05)
        var prior = player.currentIndex!
        for _ in 0..<20 { let old = player.currentIndex!; assert(player.next() && player.currentIndex != old); prior = old }
        assert(player.previous() && player.currentIndex == prior, "Shuffle previous uses history, not filename order")
        assert(player.toggle()); player.seek(0.9)
        assert(player.select(player.currentIndex!) && player.isPlaying && player.currentTime>0.85, "Selecting the paused current song resumes")
        assert(player.select(2) && player.currentIndex == 2)
        player.toggleMode(); player.seek(2.85); wait(0.4)
        assert(player.isPlaying && player.currentIndex == 0 && player.currentTime<0.5, "Natural EOF advances and wraps the folder playlist")
        let oldList = player.playlist, oldIndex = player.currentIndex
        do { try player.loadPlaylist([]); assertionFailure("Empty replacement accepted") }
        catch { assert(player.playlist == oldList && player.currentIndex == oldIndex && player.isPlaying) }
        do { try player.loadPlaylist([corrupt]); assertionFailure("Corrupt replacement accepted") }
        catch { assert(player.playlist == oldList && player.currentIndex == oldIndex && player.isPlaying) }
        assert(!player.select(-1) && !player.select(100))
        try player.loadPlaylist([corrupt,songs[0],songs[1]])
        assert(player.currentIndex == 1 && player.isPlaying, "Folder skips an unplayable first candidate")
        try player.loadPlaylist([songs[0],corrupt,songs[1]])
        assert(player.next() && player.currentIndex == 2, "Next skips unplayable audio")
        let beforeFailure = player.currentIndex
        assert(!player.select(1) && player.currentIndex == beforeFailure && player.isPlaying)
        player.toggleMode()
        try player.loadPlaylist(songs)
        assert(player.mode == .shuffle && player.currentIndex == 0, "Folder starts the first ordered song; shuffle governs subsequent songs")
        try player.loadPlaylist([file,corrupt])
        let beforeFallback = errors
        assert(player.next() && player.currentIndex == 0 && errors == beforeFallback,
            "Shuffle repeats the sole playable song when all other candidates fail")
        try player.loadPlaylist([file])
        player.seek(2.85); wait(0.4)
        assert(player.isPlaying && player.currentIndex == 0 && player.currentTime<0.5, "One-song random mode repeats at EOF")
        player.stop()
        print("PASS: folder filtering/sorting/autoplay, ordered and EOF wrap, shuffle/history, selection and invalid replacement preservation")
        print("PASS: native audio load/error preservation, playback/meter strength, pause, seek, volume/mute, EOF/replay and stop")
    }
}
