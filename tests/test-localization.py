import json
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
from scripts.localization import CATALOG, resolve

class LocalizationTests(unittest.TestCase):
    def test_catalog_covers_all_languages_and_literal_ui_keys(self):
        keys = set(CATALOG['en'])
        self.assertEqual(set(CATALOG), {'en', 'zh-CN', 'ja'})
        for language, messages in CATALOG.items():
            self.assertEqual(set(messages), keys, language)
            self.assertTrue(all(isinstance(v, str) and v.strip() for v in messages.values()))
        for file in [*ROOT.glob('source/*.swift'), *ROOT.glob('windows/CodexAura/*.cs')]:
            for key in re.findall(r'\b[lL]\["([a-zA-Z]+)"\]', file.read_text()):
                self.assertIn(key, keys, str(file))

    def test_system_language_and_explicit_override(self):
        for system, expected in [('en-US','en'), ('zh-Hans-CN','zh-CN'), ('zh_TW','zh-CN'), ('ja-JP','ja'), ('de-DE','en'), ('','en')]:
            self.assertEqual(resolve(system=system), expected)
        self.assertEqual(resolve('ja', 'en-US'), 'ja')
        self.assertEqual(resolve('invalid', 'ja-JP'), 'ja')

    def test_built_mac_catalog(self):
        bundled = ROOT / 'Codex Aura.app/Contents/Resources/Web/locales.json'
        self.assertEqual(json.loads(bundled.read_text()), CATALOG)

if __name__ == '__main__':
    unittest.main()
