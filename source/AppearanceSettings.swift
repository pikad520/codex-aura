import Foundation

struct AppearanceSettings: Codable, Equatable {
    var version = 2
    var opacity = 0.20
    var saturation = 1.30
    var contrast = 1.10
    var brightness = 0.70
    var character = "golden"
    var language = "system"

    static let defaults = AppearanceSettings()

    static func load(_ data: Data?) -> AppearanceSettings {
        guard let data, let values = try? JSONSerialization.jsonObject(with:data) as? [String:Any] else { return .defaults }
        var result = defaults
        result.character = values["character"] as? String ?? "golden"
        result.language = values["language"] as? String ?? "system"
        if (values["version"] as? Int ?? 0) >= 2 {
            result.opacity = values["opacity"] as? Double ?? result.opacity
            result.saturation = values["saturation"] as? Double ?? result.saturation
            result.contrast = values["contrast"] as? Double ?? result.contrast
            result.brightness = values["brightness"] as? Double ?? result.brightness
        } else {
            let base = values["opacity"] as? Double ?? 0.18
            let light = values["lightBackground"] as? Bool ?? true
            result.opacity = light ? min(0.6, base*10/9) : base
            if !light { result.saturation = 1; result.contrast = 1; result.brightness = 1 }
        }
        result.normalize()
        return result
    }

    mutating func normalize() {
        if character != "blue-hime" { character = "golden" }
        language = Localization.preference(language)
        func bounded(_ value: Double, _ lower: Double, _ upper: Double, _ fallback: Double) -> Double {
            value.isFinite ? min(upper, max(lower,value)) : fallback
        }
        opacity = bounded(opacity, 0, 1, Self.defaults.opacity)
        saturation = bounded(saturation, 0, 2, Self.defaults.saturation)
        contrast = bounded(contrast, 0.5, 2, Self.defaults.contrast)
        brightness = bounded(brightness, 0.2, 1.5, Self.defaults.brightness)
    }

    var json: String { String(data:try! JSONEncoder().encode(self), encoding:.utf8)! }
}
