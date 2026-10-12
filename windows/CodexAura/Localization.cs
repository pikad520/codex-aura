using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text.Json;

namespace CodexAura;

internal sealed class Localization
{
    internal static readonly string[] Choices = ["system", "en", "zh-CN", "ja"];
    internal static string Preference(string? value) => Array.IndexOf(Choices, value) >= 0 ? value! : "system";
    internal static string Resolve(string? preference, string? system = null)
    {
        if (preference is "en" or "zh-CN" or "ja") return preference;
        var primary = (system ?? CultureInfo.CurrentUICulture.Name).Replace('_', '-').Split('-')[0].ToLowerInvariant();
        return primary == "zh" ? "zh-CN" : primary == "ja" ? "ja" : "en";
    }
    private static readonly Dictionary<string, Dictionary<string, string>> Catalog = LoadCatalog();
    private static Dictionary<string, Dictionary<string, string>> LoadCatalog()
    {
        try { return JsonSerializer.Deserialize<Dictionary<string, Dictionary<string, string>>>(
            File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Web", "locales.json"))) ?? new(); }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException or JsonException) { return new(); }
    }
    internal string Language { get; }
    internal Localization(string? preference) { Language = Resolve(preference); }
    internal string this[string key] => Catalog.TryGetValue(Language, out var strings) && strings.TryGetValue(key, out var value) ? value :
        Catalog.TryGetValue("en", out var english) && english.TryGetValue(key, out var fallback) ? fallback : key;
    internal string HelpFile => Language == "zh-CN" ? "README.zh-CN.md" : Language == "ja" ? "README.ja.md" : "README.md";
}
