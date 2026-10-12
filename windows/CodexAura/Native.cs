using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace CodexAura;

internal static class Native
{
    internal const int ExStyle = -20;
    internal const long Transparent = 0x20, ToolWindow = 0x80, Layered = 0x80000, NoActivate = 0x08000000;
    internal const int HotkeyMessage = 0x0312;
    internal static readonly nint Topmost = new(-1);
    [StructLayout(LayoutKind.Sequential)] internal struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] internal static extern nint GetForegroundWindow();
    [DllImport("user32.dll")] internal static extern uint GetWindowThreadProcessId(nint window, out uint process);
    [DllImport("user32.dll")] internal static extern bool IsWindowVisible(nint window);
    [DllImport("user32.dll")] internal static extern bool IsIconic(nint window);
    [DllImport("user32.dll")] internal static extern bool GetWindowRect(nint window, out Rect rect);
    [DllImport("user32.dll", EntryPoint="GetWindowLongPtrW")] internal static extern nint GetWindowLongPtr(nint window, int index);
    [DllImport("user32.dll", EntryPoint="SetWindowLongPtrW")] internal static extern nint SetWindowLongPtr(nint window, int index, nint value);
    [DllImport("user32.dll")] internal static extern bool SetWindowPos(nint window, nint after, int x, int y, int width, int height, uint flags);
    [DllImport("user32.dll")] internal static extern bool RegisterHotKey(nint window, int id, uint modifiers, uint key);
    [DllImport("user32.dll")] internal static extern bool UnregisterHotKey(nint window, int id);
    [DllImport("dwmapi.dll", EntryPoint="DwmGetWindowAttribute")] private static extern int GetFrame(nint window, int attribute, out Rect rect, int size);
    [DllImport("dwmapi.dll", EntryPoint="DwmGetWindowAttribute")] private static extern int GetCloaked(nint window, int attribute, out int value, int size);
    [DllImport("kernel32.dll")] private static extern nint OpenProcess(uint access, bool inherit, uint process);
    [DllImport("kernel32.dll")] private static extern bool CloseHandle(nint handle);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode)] private static extern bool QueryFullProcessImageName(nint process, uint flags, StringBuilder name, ref int size);

    internal static bool IsTarget(nint window)
    {
        if (window == 0) return false;
        GetWindowThreadProcessId(window, out var pid);
        var process = OpenProcess(0x1000, false, pid);
        if (process == 0) return false;
        try
        {
            var buffer = new StringBuilder(32768); var length = buffer.Capacity;
            return QueryFullProcessImageName(process, 0, buffer, ref length) &&
                WindowPolicy.IsTarget(Path.GetFileName(buffer.ToString()));
        }
        finally { CloseHandle(process); }
    }
    internal static bool TryRect(nint window, out Rect rect)
    {
        rect = default;
        if (window == 0 || !IsWindowVisible(window) || IsIconic(window)) return false;
        if (GetCloaked(window, 14, out var cloaked, sizeof(int)) == 0 && cloaked != 0) return false;
        if (GetFrame(window, 9, out rect, Marshal.SizeOf<Rect>()) != 0 && !GetWindowRect(window, out rect)) return false;
        return rect.Right - rect.Left >= 300 && rect.Bottom - rect.Top >= 200;
    }
}
