"""Exercise the actual AppDelegate menu actions without launching the production overlay."""
from pathlib import Path
import plistlib
import shutil
import subprocess

ROOT = Path(__file__).resolve().parent.parent
fixture = ROOT / '.build/menu-check'
app = fixture / 'Effects Menu Test.app'
(app / 'Contents/MacOS').mkdir(parents=True, exist_ok=True)
(app / 'Contents/Resources/Web').mkdir(parents=True, exist_ok=True)
shutil.copyfile(ROOT / 'web/locales.json', app / 'Contents/Resources/Web/locales.json')
(app / 'Contents/Info.plist').write_bytes(plistlib.dumps({
    'CFBundleExecutable': 'MenuTest', 'CFBundleIdentifier': 'local.codex.aura.menu-test',
    'CFBundleName': 'Effects Menu Test', 'CFBundlePackageType': 'APPL', 'LSUIElement': True,
}))
source = (ROOT / 'source/main.swift').read_text()
entry = '\nlet app = NSApplication.shared\n'
assert source.count(entry) == 1
source = source.split(entry)[0] + r'''
extension AppDelegate {
    func verifyEffectsMenu() {
        panel = OverlayPanel(contentRect:NSRect(x:0,y:0,width:320,height:180),
            styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
        clickRipples = ClickRipple(frame:panel.contentView!.bounds)
        makeMenu()
        assert(musicControlsItem.target === self && musicControlsItem.action == #selector(toggleMusicControls))
        assert(ripplesItem.target === self && ripplesItem.action == #selector(toggleRipples))
        for language in ["en","zh-CN","ja"] {
            appearance.language = language; refreshLanguage()
            assert(musicControlsVisible && ripplesEnabled)
            assert(musicControlsItem.title == l["hideMusicControls"] && ripplesItem.title == l["disableRipples"])
            toggleMusicControls(); toggleRipples()
            assert(!musicControlsVisible && !ripplesEnabled && !clickRipples.isMonitoring)
            assert(musicControlsItem.title == l["showMusicControls"] && ripplesItem.title == l["enableRipples"])
            refreshLanguage()
            assert(musicControlsItem.title == l["showMusicControls"] && ripplesItem.title == l["enableRipples"])
            toggleMusicControls(); toggleRipples()
        }
        NSStatusBar.system.removeStatusItem(status)
        panel.orderOut(nil)
        print("PASS: actual menu selectors toggle both directions and preserve state through three-language refresh")
    }
}
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
AppDelegate().verifyEffectsMenu()
'''
(fixture / 'main.swift').write_text(source)
files = [str(file) for file in sorted((ROOT / 'source').glob('*.swift')) if file.name != 'main.swift']
command = ['xcrun', 'swiftc', *files, str(fixture / 'main.swift'),
           '-framework', 'AppKit', '-framework', 'WebKit', '-framework', 'Carbon', '-framework', 'AVFoundation',
           '-o', str(app / 'Contents/MacOS/MenuTest')]
subprocess.run(command, check=True)
subprocess.run([str(app / 'Contents/MacOS/MenuTest')], check=True)
