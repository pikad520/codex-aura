#!/bin/zsh
set -eu
package_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
app_dir="$package_dir/Codex Aura.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources/Web"
xcrun swiftc -O -target "$(uname -m)-apple-macosx12.0" \
  "$package_dir/source/WindowPolicy.swift" "$package_dir/source/AppearanceSettings.swift" \
  "$package_dir/source/ControlsWindow.swift" "$package_dir/source/main.swift" \
  -framework AppKit -framework WebKit -framework Carbon \
  -o "$app_dir/Contents/MacOS/CodexAura"
cp -R "$package_dir/web/." "$app_dir/Contents/Resources/Web/"
mkdir -p "$app_dir/Contents/Resources/docs" "$app_dir/Contents/Resources/specs" "$app_dir/Contents/Resources/web"
cp "$package_dir/docs/"*.md "$app_dir/Contents/Resources/docs/"
cp "$package_dir/specs/"*.md "$app_dir/Contents/Resources/specs/"
cp "$package_dir/DESCRIPTION.md" "$app_dir/Contents/Resources/"
cp "$package_dir/web/CREDITS.html" "$package_dir/web/PROMPTS.txt" "$app_dir/Contents/Resources/web/"
cp "$package_dir/README.txt" "$app_dir/Contents/Resources/README.txt"
# Keep documentation and license notices with redistributable app bundles.
for document in README.md README.zh-CN.md README.ja.md LICENSE LICENSE.zh-CN.md LICENSE.ja.md; do
  cp "$package_dir/$document" "$app_dir/Contents/Resources/$document"
done
cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.codex.aura</string>
<key>CFBundleName</key><string>Codex Aura</string>
<key>CFBundleDisplayName</key><string>曦光浮层</string>
<key>CFBundleExecutable</key><string>CodexAura</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>8</string>
<key>CFBundleShortVersionString</key><string>1.4.0</string>
<key>LSMinimumSystemVersion</key><string>12.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app_dir"
printf '已构建：%s\n' "$app_dir"
