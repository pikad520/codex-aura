"""Shared catalog for the existing Python installer and Finder launchers."""
import json
import locale
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
CATALOG = json.loads((ROOT / 'web/locales.json').read_text(encoding='utf-8'))

def resolve(preference='system', system=None):
    if isinstance(preference, str) and preference in CATALOG:
        return preference
    if system is None:
        system = locale.getlocale()[0] or 'en'
        if sys.platform == 'darwin':
            try:
                output = subprocess.check_output(['/usr/bin/defaults', 'read', '-g', 'AppleLanguages'], stderr=subprocess.DEVNULL, text=True)
                languages = re.findall(r'^\s*"?([A-Za-z]{2,3}(?:[-_][A-Za-z0-9]+)*)"?,?\s*$', output, re.MULTILINE)
                if languages:
                    system = languages[0]
            except (OSError, subprocess.CalledProcessError):
                pass
    primary = system.replace('_', '-').lower().split('-')[0]
    return 'zh-CN' if primary == 'zh' else 'ja' if primary == 'ja' else 'en'

def translator(home):
    try:
        settings = json.loads((home / 'Library/Application Support/Codex Aura/settings.json').read_text())
        preference = settings.get('language', 'system') if isinstance(settings, dict) else 'system'
    except (OSError, ValueError):
        preference = 'system'
    language = resolve(preference)
    return lambda key: CATALOG[language].get(key, CATALOG['en'].get(key, key))

if __name__ == '__main__':
    print(translator(Path.home())(sys.argv[1]))
