import Foundation
@main struct Tests {
    static func main() throws {
        func load(_ text:String) -> AppearanceSettings { AppearanceSettings.load(text.data(using:.utf8)) }
        assert(AppearanceSettings.load(nil) == .defaults)
        let legacy = load("{\"opacity\":0.18,\"lightBackground\":true}")
        assert(abs(legacy.opacity-0.20)<0.00001 && legacy.saturation == 1.3)
        let dark = load("{\"opacity\":0.25,\"lightBackground\":false}")
        assert(dark.opacity == 0.25 && dark.brightness == 1 && dark.contrast == 1 && dark.saturation == 1)
        let edited = load("{\"version\":2,\"opacity\":0.24,\"saturation\":1.44,\"contrast\":1.22,\"brightness\":0.66}")
        assert(edited.opacity == 0.24 && edited.saturation == 1.44 && edited.contrast == 1.22 && edited.brightness == 0.66)
        assert(load(edited.json) == edited, "JSON persistence round trip")
        let bounds = load("{\"version\":2,\"opacity\":-1,\"saturation\":20,\"contrast\":0,\"brightness\":50}")
        assert(bounds.opacity == 0 && bounds.saturation == 2 && bounds.contrast == 0.5 && bounds.brightness == 1.5)
        assert(load("not json") == .defaults)
        print("PASS: appearance migration preserves visual values; direct values persist; invalid inputs bounded")
    }
}
