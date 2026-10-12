using CodexAura;

static void Check(bool condition, string name) { if (!condition) throw new Exception(name); }
var defaults = new Appearance();
Check(Appearance.Parse("not json") == defaults, "Corrupt settings use defaults");
Check(Appearance.Parse("{}") == defaults, "Missing values use defaults");
Check(Appearance.Parse("null") == defaults, "Null settings use defaults");
Check(Appearance.Parse("{\"opacity\":0}").Opacity == 0, "Zero opacity survives loading");
Check(Appearance.Parse("{\"opacity\":\"bad\"}") == defaults, "Invalid types use defaults");
var values = new Appearance(.24, 1.4, 1.2, .8);
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
