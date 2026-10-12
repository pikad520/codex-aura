using System;
using System.Diagnostics;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Threading;
using Microsoft.Web.WebView2.Core;
using Forms = System.Windows.Forms;

namespace CodexAura;

internal static class Program
{
    private const string QuitEvent = @"Local\CodexAura.Quit";
    [STAThread]
    private static void Main(string[] args)
    {
        if (Array.Exists(args, value => value == "--quit"))
        {
            if (EventWaitHandle.TryOpenExisting(QuitEvent, out var quit)) { using (quit) quit.Set(); }
            return;
        }
        var initial = Appearance.Load(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Codex Aura", "settings.json"));
        var l = new Localization(initial.Language);
        if (RuntimeInformation.OSArchitecture != Architecture.X64 || !OperatingSystem.IsWindowsVersionAtLeast(10, 0, 22000))
        { MessageBox.Show(l["needWindows"], "Codex Aura"); return; }
        if (args.Length == 2 && args[0] == "--smoke-test")
        {
            var testApp = new Application { ShutdownMode = ShutdownMode.OnExplicitShutdown };
            testApp.Startup += async (_, _) => await SmokeTest.RunAsync(testApp, Path.GetFullPath(args[1]));
            Environment.ExitCode = testApp.Run();
            return;
        }
        using var mutex = new Mutex(true, @"Local\CodexAura.Instance", out var first);
        if (!first) return;
        try { CoreWebView2Environment.GetAvailableBrowserVersionString(); }
        catch (WebView2RuntimeNotFoundException)
        {
            if (MessageBox.Show(l["needWebView"],
                "Codex Aura", MessageBoxButton.YesNo, MessageBoxImage.Information) == MessageBoxResult.Yes)
                Process.Start(new ProcessStartInfo("https://developer.microsoft.com/microsoft-edge/webview2/") { UseShellExecute = true });
            return;
        }
        var application = new Application { ShutdownMode = ShutdownMode.OnExplicitShutdown };
        using var signal = new EventWaitHandle(false, EventResetMode.AutoReset, QuitEvent);
        var registration = ThreadPool.RegisterWaitForSingleObject(signal,
            (_, _) => application.Dispatcher.BeginInvoke(application.Shutdown), null, Timeout.Infinite, false);
        Companion? companion = null;
        application.Startup += (_, _) => { companion = new Companion(application); companion.Start(); };
        application.Exit += (_, _) => { registration.Unregister(null); companion?.Dispose(); };
        application.Run();
    }
}

internal sealed class Companion : IDisposable
{
    private readonly Application application;
    private readonly Dictionary<string, Forms.ToolStripItem> menuLabels = new();
    private Localization L => new(appearance.Language);
    private readonly string dataDirectory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Codex Aura");
    private readonly OverlayWindow overlay = new();
    private readonly Forms.NotifyIcon tray;
    private readonly Forms.ToolStripMenuItem state;
    private readonly Forms.ToolStripMenuItem toggle;
    private readonly DispatcherTimer timer = new() { Interval = TimeSpan.FromMilliseconds(200) };
    private readonly DispatcherTimer saveTimer = new() { Interval = TimeSpan.FromMilliseconds(250) };
    private Appearance appearance;
    private ControlsWindow? controls;
    private nint lastTarget;
    private bool enabled = true;
    private bool updating;
    private bool failed;
    private string SettingsPath => Path.Combine(dataDirectory, "settings.json");

    internal Companion(Application application)
    {
        this.application = application;
        appearance = Appearance.Load(SettingsPath);
        var menu = new Forms.ContextMenuStrip();
        state = new Forms.ToolStripMenuItem(L["preparing"]) { Enabled = false };
        toggle = new Forms.ToolStripMenuItem(L["hide"], null, (_, _) => Toggle());
        menu.Items.Add(state); menu.Items.Add(new Forms.ToolStripSeparator()); menu.Items.Add(toggle);
        menuLabels["replay"] = menu.Items.Add(L["replay"], null, async (_, _) => await overlay.ScriptAsync("window.aura.replay()"));
        menuLabels["controls"] = menu.Items.Add(L["controls"], null, (_, _) => ShowControls());
        menu.Items.Add(new Forms.ToolStripSeparator());
        menuLabels["help"] = menu.Items.Add(L["help"], null, (_, _) => Process.Start(new ProcessStartInfo(
            Path.Combine(AppContext.BaseDirectory, "Docs", L.HelpFile)) { UseShellExecute = true }));
        menuLabels["quit"] = menu.Items.Add(L["quit"], null, (_, _) => application.Shutdown());
        tray = new Forms.NotifyIcon { Text = "Codex Aura", Icon = new System.Drawing.Icon(Path.Combine(AppContext.BaseDirectory, "aura.ico")),
            ContextMenuStrip = menu, Visible = true };
        tray.DoubleClick += (_, _) => ShowControls();
        overlay.UILanguage = appearance.Language;
        overlay.ToggleRequested += Toggle;
        overlay.BecameReady += async () => { await overlay.SetAppearanceAsync(appearance); Update(); };
        overlay.Failed += message =>
        {
            failed = true; timer.Stop(); state.Text = L["processStopped"];
            tray.ShowBalloonTip(8000, "Codex Aura", message, Forms.ToolTipIcon.Error);
        };
        timer.Tick += (_, _) => Update();
        saveTimer.Tick += (_, _) => { saveTimer.Stop(); Save(); };
    }
    internal async void Start()
    {
        overlay.Show(); // Transparent and nonactivating; create the composition host before initialization.
        try { await overlay.InitializeAsync(dataDirectory, appearance); timer.Start(); Update(); }
        catch (Exception error) when (error is COMException or InvalidOperationException or IOException or UnauthorizedAccessException)
        {
            overlay.Hide(); failed = true; state.Text = L["initFailed"];
            MessageBox.Show(L["initFailed"] + "\n\n" + error.Message,
                "Codex Aura", MessageBoxButton.OK, MessageBoxImage.Error);
        }
    }
    private void ShowControls()
    {
        if (controls == null)
        {
            controls = new ControlsWindow(appearance);
            controls.Changed += async value =>
            {
                var languageChanged = appearance.Language != value.Language;
                appearance = value; saveTimer.Stop(); saveTimer.Start();
                if (languageChanged) {
                    overlay.UILanguage = value.Language;
                    foreach (var item in menuLabels) item.Value.Text = L[item.Key];
                    toggle.Text = L[enabled ? "hide" : "show"];
                    if (failed) state.Text = L["processStopped"]; else Update();
                }
                else await overlay.SetAppearanceAsync(value, true);
            };
            controls.ReplayRequested += async () => await overlay.ScriptAsync("window.aura.replay()");
            controls.Closed += (_, _) => { controls = null; Update(); };
        }
        controls.Show(); controls.Activate(); Update();
    }
    private void Toggle() { enabled = !enabled; toggle.Text = L[enabled ? "hide" : "show"]; Update(); }
    private async void Update()
    {
        if (updating || failed) return;
        updating = true;
        try
        {
            var front = Native.GetForegroundWindow();
            var targetForeground = Native.IsTarget(front);
            if (targetForeground) lastTarget = front;
            var controlsHandle = controls?.IsVisible == true ? new WindowInteropHelper(controls).Handle : 0;
            var adjusting = controlsHandle != 0 && front == controlsHandle;
            var target = targetForeground ? front : adjusting ? lastTarget : 0;
            var hasRect = Native.TryRect(target, out var rect) && Native.IsTarget(target);
            var visible = WindowPolicy.ShouldShow(overlay.Ready, enabled, targetForeground, adjusting, hasRect);
            await overlay.SetVisibleAsync(visible, rect, adjusting ? controlsHandle : 0);
            state.Text = L[!overlay.Ready ? "preparing" : !enabled ? "paused" : visible ? "playing" : "waiting"];
        }
        finally { updating = false; }
    }
    private void Save()
    {
        try { appearance.Save(SettingsPath); }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException)
        { tray.ShowBalloonTip(5000, "Codex Aura", L["saveFailed"], Forms.ToolTipIcon.Warning); }
    }
    public void Dispose()
    {
        failed = true; timer.Stop(); saveTimer.Stop(); Save(); controls?.Close(); overlay.Close();
        tray.Visible = false; tray.Icon?.Dispose(); tray.ContextMenuStrip?.Dispose(); tray.Dispose();
    }
}
