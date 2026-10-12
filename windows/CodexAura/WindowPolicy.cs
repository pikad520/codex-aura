using System;

namespace CodexAura;

internal static class WindowPolicy
{
    // Match the executable, never a chat title or arbitrary window text.
    public static bool IsTarget(string executable) =>
        string.Equals(executable, "Codex.exe", StringComparison.OrdinalIgnoreCase);
    public static bool ShouldShow(bool ready, bool enabled, bool targetForeground,
        bool controlsForeground, bool targetVisible) =>
        ready && enabled && targetVisible && (targetForeground || controlsForeground);
}
