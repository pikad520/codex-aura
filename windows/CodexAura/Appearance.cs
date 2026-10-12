using System;
using System.IO;
using System.Text.Json;

namespace CodexAura;

internal sealed record Appearance(double Opacity = .20, double Saturation = 1.30,
    double Contrast = 1.10, double Brightness = .70, string Character = "golden")
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
    public Appearance Normalize() => new(Bound(Opacity, 0, 1, .20), Bound(Saturation, 0, 2, 1.30),
        Bound(Contrast, .5, 2, 1.10), Bound(Brightness, .2, 1.5, .70), Character == "blue-hime" ? "blue-hime" : "golden");
    private static double Bound(double value, double min, double max, double fallback) =>
        double.IsFinite(value) ? Math.Clamp(value, min, max) : fallback;
    public string ToJson() => JsonSerializer.Serialize(Normalize(), JsonOptions);
    public static Appearance Parse(string json)
    {
        try { return (JsonSerializer.Deserialize<Appearance>(json, JsonOptions) ?? new()).Normalize(); }
        catch (JsonException) { return new(); }
    }
    public static Appearance Load(string path)
    {
        try { return Parse(File.ReadAllText(path)); }
        catch (IOException) { return new(); }
        catch (UnauthorizedAccessException) { return new(); }
    }
    public void Save(string path)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        var temporary = path + ".tmp";
        File.WriteAllText(temporary, ToJson());
        File.Move(temporary, path, true);
    }
}
