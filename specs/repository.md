# Repository scope

Codex Aura includes a macOS AppKit host, a Windows x64 WPF/WebView2 host, and shared Canvas/WebGL animation with four original textures. Current development and distribution requirements are in [windows-x64.md](windows-x64.md).

macOS is distributed as source only, locally built and ad-hoc signed without a Developer ID. Windows provides an x64 installer; no x86/ARM64 installer, portable ZIP, or macOS binary releases. Generated binaries, installers, caches, diagnostics and credentials stay out of Git.

English, Simplified Chinese and Japanese README files describe equivalent build, use and uninstall behavior. macOS UI is Chinese; Windows UI is English. The English MIT license names pikad520; Chinese and Japanese licenses are reference translations. Dependencies retain their own licenses and notices.

Verification must distinguish exact tested versions, compilation, automated fixtures, and actual Codex interaction. See [verification](../docs/verification.md). Push changes to the user-specified repository after local checks; use Windows CI for native and installer checks.
