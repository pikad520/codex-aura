using System;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace CodexAura;

// Explicit CI diagnostic. Exercises only windows created by this test, never Codex UI.
internal static class SmokeTest
{
    internal static async Task RunAsync(Application app, string directory)
    {
        Directory.CreateDirectory(directory);
        var fixture = new Window { Title = "Aura CI fixture", Width = 900, Height = 650,
            Left = 100, Top = 80, Background = Brushes.White };
        var overlay = new OverlayWindow();
        try
        {
            fixture.Show(); fixture.Activate();
            var fixtureHandle = new WindowInteropHelper(fixture).Handle;
            var foreground = Native.GetForegroundWindow();
            var ready = new TaskCompletionSource();
            overlay.BecameReady += () => ready.TrySetResult();
            overlay.Failed += error => ready.TrySetException(new Exception(error));
            overlay.Show();
            await overlay.InitializeAsync(Path.Combine(directory, "profile"));
            await ready.Task.WaitAsync(TimeSpan.FromSeconds(45));
            // Hosted Windows runners disable animation by default. Exercise both modes explicitly.
            await overlay.SetMotionForTestAsync(false);
            Check(Native.TryRect(fixtureHandle, out var rect), "Fixture bounds available");
            await overlay.SetVisibleAsync(true, rect, 0);
            await overlay.SetAppearanceAsync(new Appearance(.24, 1.4, 1.2, .8), true);
            await Task.Delay(1500);
            using var status = JsonDocument.Parse(await overlay.ReadStatusAsync());
            Check(status.RootElement.GetProperty("ready").GetBoolean(), "Real WebGL renderer ready");
            Check(status.RootElement.GetProperty("frames").GetInt32() > 1, "Renderer produced frames");
            Check(!status.RootElement.GetProperty("reduced").GetBoolean() && status.RootElement.GetProperty("time").GetDouble() > .1,
                "Native animation clock advances with motion enabled");
            Check(Math.Abs(status.RootElement.GetProperty("displayOpacity").GetDouble() - .24) < .0001, "Live opacity applied");
            Check(!overlay.IsActive && Native.GetForegroundWindow() == foreground, "Overlay did not steal focus");
            var styles = Native.GetWindowLongPtr(overlay.Handle, Native.ExStyle).ToInt64();
            Check((styles & (Native.Layered | Native.Transparent | Native.NoActivate)) ==
                (Native.Layered | Native.Transparent | Native.NoActivate), "Layered click-through and nonactivating styles");
            Native.GetWindowRect(overlay.Handle, out var actual);
            Check(actual.Left == rect.Left && actual.Top == rect.Top && actual.Right == rect.Right && actual.Bottom == rect.Bottom,
                "Physical window bounds match");
            // Inspect WPF composition pixels, not just the browser's backing canvas.
            await overlay.ScriptAsync("window.aura.setAppearance({opacity:.24}, true); window.aura.setActive(true)");
            await Task.Delay(7500);
            var image = new RenderTargetBitmap((int)overlay.ActualWidth, (int)overlay.ActualHeight, 96, 96, PixelFormats.Pbgra32);
            image.Render(overlay);
            var pixels = new byte[image.PixelWidth * image.PixelHeight * 4];
            image.CopyPixels(pixels, image.PixelWidth * 4, 0);
            var visiblePixels = 0; var translucentPixels = 0;
            for (var i = 3; i < pixels.Length; i += 4)
            { if (pixels[i] > 0) visiblePixels++; if (pixels[i] > 0 && pixels[i] < 240) translucentPixels++; }
            Check(visiblePixels > 1000 && translucentPixels > 1000, "Transparent WPF composition contains rendered character");
            var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(image));
            using (var stream = File.Create(Path.Combine(directory, "overlay.png"))) encoder.Save(stream);
            await overlay.SetAppearanceAsync(new Appearance(.24, 1.4, 1.2, .8, "blue-hime"), true);
            var blueReady = false;
            for (var attempt = 0; attempt < 100; attempt++)
            {
                await Task.Delay(100);
                using var selection = JsonDocument.Parse(await overlay.ReadStatusAsync());
                if (selection.RootElement.GetProperty("character").GetString() == "blue-hime" &&
                    !selection.RootElement.GetProperty("loading").GetBoolean()) { blueReady = true; break; }
            }
            Check(blueReady, "Blue character loads in native WebView2");
            using var blueStatus = JsonDocument.Parse(await overlay.ReadStatusAsync());
            Check(blueStatus.RootElement.GetProperty("time").GetDouble() > 7, "Character switch preserves settled intro");
            await Task.Delay(300);
            var blueImage = new RenderTargetBitmap((int)overlay.ActualWidth, (int)overlay.ActualHeight, 96, 96, PixelFormats.Pbgra32);
            blueImage.Render(overlay);
            var blueEncoder = new PngBitmapEncoder(); blueEncoder.Frames.Add(BitmapFrame.Create(blueImage));
            using (var stream = File.Create(Path.Combine(directory, "blue-overlay.png"))) blueEncoder.Save(stream);
            await overlay.SetVisibleAsync(false, default, 0);
            using var paused = JsonDocument.Parse(await overlay.ReadStatusAsync());
            var time = paused.RootElement.GetProperty("time").GetDouble();
            await Task.Delay(300);
            using var still = JsonDocument.Parse(await overlay.ReadStatusAsync());
            Check(still.RootElement.GetProperty("time").GetDouble() == time, "Hidden renderer stops its clock");
            await overlay.SetMotionForTestAsync(true);
            await overlay.SetVisibleAsync(true, rect, 0);
            await Task.Delay(200);
            using var reduced = JsonDocument.Parse(await overlay.ReadStatusAsync());
            Check(reduced.RootElement.GetProperty("reduced").GetBoolean(), "Native reduced-motion setting applies");
            var reducedTime = reduced.RootElement.GetProperty("time").GetDouble();
            await Task.Delay(200);
            using var staticFrame = JsonDocument.Parse(await overlay.ReadStatusAsync());
            Check(staticFrame.RootElement.GetProperty("time").GetDouble() == reducedTime, "Reduced motion stops animation while visible");
            // Exercise the actual native picker and layout, preserving the existing values.
            var original = new Appearance(.15, 1.15, 2, .8, "blue-hime", "en");
            var controls = new ControlsWindow(original);
            var edited = original;
            controls.Changed += value => edited = value;
            try
            {
                controls.Show();
                var languagePicker = ((StackPanel)controls.Content).Children.OfType<ComboBox>().First();
                foreach (var language in new[] { "ja", "zh-CN", "en" })
                {
                    languagePicker.SelectedIndex = Array.IndexOf(Localization.Choices, language);
                    await Task.Delay(150);
                    Check(edited == original with { Language = language }, "Language picker preserves character and appearance");
                    Check(controls.Title == new Localization(language)["panelTitle"], "Panel title follows language");
                    var panelImage = new RenderTargetBitmap((int)controls.ActualWidth, (int)controls.ActualHeight, 96, 96, PixelFormats.Pbgra32);
                    panelImage.Render(controls);
                    var panelEncoder = new PngBitmapEncoder(); panelEncoder.Frames.Add(BitmapFrame.Create(panelImage));
                    using var stream = File.Create(Path.Combine(directory, "controls-" + language + ".png"));
                    panelEncoder.Save(stream);
                }
            }
            finally { controls.Close(); }
            File.WriteAllText(Path.Combine(directory, "result.json"), JsonSerializer.Serialize(new {
                passed = true, os = Environment.OSVersion.ToString(), runtime = Environment.Version.ToString(), webView2 = overlay.BrowserVersion,
                renderer = status.RootElement.Clone(), blueRenderer = blueStatus.RootElement.Clone(), visiblePixels, translucentPixels,
                localizedControls = new[] { "en", "zh-CN", "ja" },
                scope = "Own fixture only; not real Codex or physical multi-monitor interaction"
            }, new JsonSerializerOptions { WriteIndented = true }));
            app.Shutdown(0);
        }
        catch (Exception error)
        {
            File.WriteAllText(Path.Combine(directory, "failure.txt"), error.ToString());
            app.Shutdown(1);
        }
        finally { overlay.Close(); fixture.Close(); }
    }
    private static void Check(bool condition, string message) { if (!condition) throw new Exception(message); }
}
