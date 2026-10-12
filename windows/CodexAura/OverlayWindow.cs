using System;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Media;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.Wpf;

namespace CodexAura;

internal sealed class OverlayWindow : Window
{
    private const string Origin = "https://aura.local/";
    private readonly WebView2CompositionControl browser = new()
    {
        DefaultBackgroundColor = System.Drawing.Color.Transparent,
        IsHitTestVisible = false, Focusable = false, AllowExternalDrop = false
    };
    private bool active;
    private bool disposed;
    internal bool Ready { get; private set; }
    internal nint Handle { get; private set; }
    internal event Action? BecameReady;
    internal event Action<string>? Failed;
    internal event Action? ToggleRequested;

    internal OverlayWindow()
    {
        Title = "Codex Aura overlay";
        WindowStyle = WindowStyle.None; AllowsTransparency = true; Background = Brushes.Transparent;
        ShowInTaskbar = false; ShowActivated = false; Focusable = false; IsHitTestVisible = false;
        ResizeMode = ResizeMode.NoResize; Width = 900; Height = 650; Opacity = 0;
        Content = browser;
        SourceInitialized += (_, _) =>
        {
            Handle = new WindowInteropHelper(this).Handle;
            var style = Native.GetWindowLongPtr(Handle, Native.ExStyle).ToInt64();
            Native.SetWindowLongPtr(Handle, Native.ExStyle,
                new nint(style | Native.Transparent | Native.ToolWindow | Native.Layered | Native.NoActivate));
            HwndSource.FromHwnd(Handle)?.AddHook(WindowMessage);
            Native.RegisterHotKey(Handle, 1, 0x0001 | 0x0002 | 0x4000, 0x47); // Ctrl+Alt+G, no repeat.
        };
        Closed += (_, _) => { disposed = true; Native.UnregisterHotKey(Handle, 1); browser.Dispose(); };
    }
    private nint WindowMessage(nint hwnd, int message, nint wParam, nint lParam, ref bool handled)
    {
        if (message == Native.HotkeyMessage && wParam == 1) { ToggleRequested?.Invoke(); handled = true; }
        if (message == 0x0021) { handled = true; return new nint(3); } // MA_NOACTIVATE
        return 0;
    }
    internal async Task InitializeAsync(string dataDirectory)
    {
        var environment = await CoreWebView2Environment.CreateAsync(null, Path.Combine(dataDirectory, "WebView2"));
        await browser.EnsureCoreWebView2Async(environment);
        var core = browser.CoreWebView2;
        core.Settings.AreDevToolsEnabled = false;
        core.Settings.AreDefaultContextMenusEnabled = false;
        core.Settings.AreBrowserAcceleratorKeysEnabled = false;
        core.Settings.IsStatusBarEnabled = false;
        core.Settings.IsZoomControlEnabled = false;
        core.SetVirtualHostNameToFolderMapping("aura.local", Path.Combine(AppContext.BaseDirectory, "Web"),
            CoreWebView2HostResourceAccessKind.DenyCors);
        core.NavigationStarting += (_, e) => e.Cancel = e.Uri != Origin + "index.html";
        core.NewWindowRequested += (_, e) => e.Handled = true;
        core.PermissionRequested += (_, e) => e.State = CoreWebView2PermissionState.Deny;
        core.DownloadStarting += (_, e) => e.Cancel = true;
        core.AddWebResourceRequestedFilter("*", CoreWebView2WebResourceContext.All);
        core.WebResourceRequested += (_, e) =>
        {
            if (!e.Request.Uri.StartsWith(Origin, StringComparison.Ordinal))
                e.Response = environment.CreateWebResourceResponse(null, 403, "Blocked", "");
        };
        core.ProcessFailed += (_, e) => Fail("The animation process stopped (" + e.ProcessFailedKind + "). Restart Codex Aura.");
        core.NavigationCompleted += (_, e) => { if (!e.IsSuccess) Fail("Animation page failed to load: " + e.WebErrorStatus); };
        core.WebMessageReceived += (_, e) =>
        {
            if (e.Source != Origin + "index.html") return;
            try
            {
                using var message = JsonDocument.Parse(e.WebMessageAsJson);
                if (message.RootElement.GetProperty("status").GetString() == "ready")
                { Ready = true; BecameReady?.Invoke(); }
                else Fail("Animation failed to load. Restart Codex Aura.");
            }
            catch (JsonException) { Fail("Invalid animation status."); }
            catch (InvalidOperationException) { Fail("Invalid animation status."); }
            catch (System.Collections.Generic.KeyNotFoundException) { Fail("Invalid animation status."); }
        };
        core.Navigate(Origin + "index.html");
    }
    private void Fail(string message)
    {
        Ready = false; active = false; Hide(); Failed?.Invoke(message);
    }
    internal async Task ScriptAsync(string script)
    {
        if (!Ready || disposed) return;
        try { await browser.ExecuteScriptAsync(script); }
        catch (Exception error) when (error is InvalidOperationException or System.Runtime.InteropServices.COMException)
        { if (!disposed) Fail("The animation could not update. Restart Codex Aura."); }
    }
    internal Task<string> SetMotionForTestAsync(bool reduced) => browser.CoreWebView2.CallDevToolsProtocolMethodAsync(
        "Emulation.setEmulatedMedia", JsonSerializer.Serialize(new {
            features = new[] { new { name = "prefers-reduced-motion", value = reduced ? "reduce" : "no-preference" } }
        }));
    internal string BrowserVersion => browser.CoreWebView2.Environment.BrowserVersionString;
    internal Task<string> ReadStatusAsync() => browser.ExecuteScriptAsync("window.aura.status()");
    internal Task SetAppearanceAsync(Appearance value, bool edit = false) =>
        ScriptAsync($"window.aura.setAppearance({value.ToJson()}, {(edit ? "true" : "false")})");
    internal async Task SetVisibleAsync(bool visible, Native.Rect rect, nint controls)
    {
        if (visible)
        {
            if (!IsVisible) Show();
            Opacity = 1;
            // DWM bounds and SetWindowPos use physical pixels in this PerMonitorV2 process.
            Native.SetWindowPos(Handle, controls != 0 ? controls : Native.Topmost,
                rect.Left, rect.Top, rect.Right - rect.Left, rect.Bottom - rect.Top, 0x0010);
        }
        else Hide();
        if (active == visible) return;
        active = visible;
        await ScriptAsync($"window.aura.setActive({(visible ? "true" : "false")})");
    }
}
