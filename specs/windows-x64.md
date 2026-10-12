# Windows x64 companion and distribution

## Scope

Keep the macOS AppKit host and shared character animation. Add a Windows 11 x64 (.NET 10/WPF + WebView2CompositionControl) host with a transparent, nonactivating, click-through window that follows the foreground Codex desktop window. Preserve one-shot introduction, ongoing blink/hair motion, pause when hidden, Reduce Motion and the four appearance defaults (20%, 1.30, 1.10, 0.70). Provide native appearance controls and a tray menu. Settings belong only to this app. Both native hosts and the installer support English, Simplified Chinese and Japanese, with system-language defaults and a persistent in-app language selector; see [localization.md](localization.md).

Distribution: macOS is source-only, compiled and ad-hoc signed locally; no macOS ZIP or DMG releases. Windows provides an x64 installer only; no x86 or ARM64 support. The installer must be per-user, include an uninstaller, leave Codex untouched, and state external runtime requirements. Login startup is optional, never enabled by default. Do not claim to track model activity or chat content.

## Implementation decisions

The user selected native .NET + WebView2. Keep AppKit on macOS; share `web/`. Windows matches foreground `Codex.exe` by executable basename, validates visible uncloaked bounds, and keeps the last target while its own controls are foreground. Use layered/transparent/no-activate window styles and physical DWM bounds. The x64 installer includes .NET, checks separately installed WebView2, requires Windows 11 build 22000+, and does not enable startup by default. Settings/cache removal is optional during interactive uninstall and manual after silent uninstall.

## Acceptance

- Existing macOS renderer, appearance, window-policy and installer tests pass.
- Windows code compiles for x64. Automated checks exercise settings, window selection/visibility, renderer bridge and installer packaging where available.
- Capture exact tested OS/tool/app versions and distinguish compilation/CI checks from actual Codex desktop interaction. Do not claim Windows end-to-end verification without evidence.
- Windows installer and shared assets are packaged reproducibly; no signing credentials are stored in source. Unsigned status is explicit.
- All README translations, bundled help, descriptions, asset credits and project specifications reflect the same platform/distribution policy.
- Push the completed source and documentation to the requested GitHub repository and verify the resulting CI run. Preserve existing history.
