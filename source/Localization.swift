import Foundation

struct Localization {
    static let choices = ["system", "en", "zh-CN", "ja"]
    static func preference(_ value: String) -> String { choices.contains(value) ? value : "system" }
    static func resolve(_ preference: String, system: String = Locale.preferredLanguages.first ?? "en") -> String {
        if choices.dropFirst().contains(preference) { return preference }
        let primary = system.lowercased().replacingOccurrences(of:"_", with:"-").split(separator:"-").first
        return primary == "zh" ? "zh-CN" : primary == "ja" ? "ja" : "en"
    }
    static let catalog: [String:[String:String]] = {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("Web/locales.json"),
              let data = try? Data(contentsOf:url),
              let strings = try? JSONDecoder().decode([String:[String:String]].self, from:data) else { return [:] }
        return strings
    }()
    let language: String
    init(preference: String) { language = Self.resolve(preference) }
    subscript(_ key: String) -> String { Self.catalog[language]?[key] ?? Self.catalog["en"]?[key] ?? key }
    var helpFile: String { language == "zh-CN" ? "README.zh-CN" : language == "ja" ? "README.ja" : "README" }
}
