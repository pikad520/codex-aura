using CodexAura;

static void Check(bool condition, string name) { if (!condition) throw new Exception(name); }
var defaults = new Appearance();
Check(defaults.Language == "system", "First launch follows system");
foreach (var (system, expected) in new[] { ("en-US","en"), ("zh-Hans-CN","zh-CN"), ("zh_TW","zh-CN"), ("ja-JP","ja"), ("fr-FR","en"), ("","en") })
    Check(Localization.Resolve("system", system) == expected, "OS language mapping: " + system);
Check(Localization.Resolve("ja", "en-US") == "ja", "Explicit language wins");
Check(Appearance.Parse("{\"language\":\"bad\"}").Language == "system", "Invalid language follows system");
Check(Appearance.Parse("{\"language\":null}").Language == "system", "Null language follows system");
foreach (var language in Localization.Choices) {
    var selected = new Appearance(.15, 1.15, 2, .8, "blue-hime", language);
    Check(Appearance.Parse(selected.ToJson()) == selected, "Language round trip preserves appearance and character");
}
Check(new Localization("en")["language"] == "Language", "Bundled English catalog");
Check(new Localization("zh-CN")["language"] == "语言", "Bundled Chinese catalog");
Check(new Localization("ja")["language"] == "言語", "Bundled Japanese catalog");
Check(Appearance.Parse("not json") == defaults, "Corrupt settings use defaults");
Check(Appearance.Parse("{}") == defaults, "Missing values use defaults");
Check(Appearance.Parse("null") == defaults, "Null settings use defaults");
Check(Appearance.Parse("{\"opacity\":0}").Opacity == 0, "Zero opacity survives loading");
Check(Appearance.Parse("{\"opacity\":\"bad\"}") == defaults, "Invalid types use defaults");
var values = new Appearance(.24, 1.4, 1.2, .8);
Check(Appearance.Parse("{\"character\":\"unknown\"}").Character == "golden", "Unknown character defaults");
Check(Appearance.Parse("{\"character\":null}").Character == "golden", "Null character defaults");
var blue = values with { Character = "blue-hime" };
Check(Appearance.Parse(blue.ToJson()) == blue, "Blue character and appearance round-trip");
Check(Appearance.Parse(values.ToJson()) == values, "All four values round-trip");
Check(new Appearance(-1, 9, 0, 9).Normalize() == new Appearance(0, 2, .5, 1.5), "Bounds enforced");
Check(new Appearance(double.NaN, double.PositiveInfinity, double.NaN, double.NegativeInfinity).Normalize() == defaults,
    "Non-finite values use defaults");
var directory = Path.Combine(Path.GetTempPath(), "aura-tests-" + Guid.NewGuid());
try
{
    var path = Path.Combine(directory, "settings.json");
    Check(Appearance.Load(path) == defaults, "First launch defaults");
    values.Save(path); Check(Appearance.Load(path) == values, "Save/restart preserves settings");
    blue.Save(path); Check(Appearance.Load(path) == blue, "Save/restart preserves blue selection");
    defaults.Save(path); Check(Appearance.Load(path) == defaults, "Atomic overwrite");
    Check(!File.Exists(path + ".tmp"), "No leftover temporary settings");
}
finally { if (Directory.Exists(directory)) Directory.Delete(directory, true); }
Check(WindowPolicy.IsTarget("Codex.exe") && WindowPolicy.IsTarget("codex.EXE"), "Case-insensitive executable matching");
foreach (var name in new[] { "CodexAura.exe", "ChatGPT.exe", "codex-helper.exe", "notepad.exe", "", "Codex" })
    Check(!WindowPolicy.IsTarget(name), "Do not follow unrelated executable: " + name);
Check(WindowPolicy.ShouldShow(true, true, true, false, true), "Foreground target shows");
Check(WindowPolicy.ShouldShow(true, true, false, true, true), "Own controls preserve target");
Check(!WindowPolicy.ShouldShow(true, true, false, false, true), "Other app hides");
Check(!WindowPolicy.ShouldShow(true, true, true, false, false), "Minimized/closed target hides");
Check(!WindowPolicy.ShouldShow(false, true, true, false, true), "Not ready hides");
Check(!WindowPolicy.ShouldShow(true, false, true, true, true), "Manual hide wins over controls");
Console.WriteLine("PASS: Windows appearance persistence, validation, executable matching and visibility policy");
