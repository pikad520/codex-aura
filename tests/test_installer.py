import importlib.util
from pathlib import Path
import plistlib
import tempfile
import unittest

PACKAGE = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('manage', PACKAGE / 'manage.py')
manage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(manage)

class InstallTests(unittest.TestCase):
    def test_install_opt_in_and_uninstall_preserve_unrelated_files(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            unrelated = home / 'Applications/Important.txt'
            unrelated.parent.mkdir(); unrelated.write_text('keep me')
            manage.manage('install', home, PACKAGE, live=False)
            app, agent, data = manage.paths(home)
            self.assertTrue((app / 'Contents/MacOS/CodexAura').is_file())
            self.assertFalse(agent.exists())
            manage.manage('enable-login', home, PACKAGE, live=False)
            with agent.open('rb') as source:
                config = plistlib.load(source)
            self.assertEqual(config['ProgramArguments'], [str(app / 'Contents/MacOS/CodexAura')])
            self.assertNotIn('KeepAlive', config)
            data.mkdir(parents=True); (data / 'settings.json').write_text('{}')
            manage.manage('uninstall', home, PACKAGE, live=False)
            for path in (app, agent, data):
                self.assertFalse(path.exists())
            self.assertEqual(unrelated.read_text(), 'keep me')
            self.assertTrue((PACKAGE / 'Codex Aura.app').is_dir())
            manage.manage('uninstall', home, PACKAGE, live=False)

    def test_refuse_replacing_an_unrelated_app(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            app, _, _ = manage.paths(home)
            (app / 'Contents').mkdir(parents=True)
            with (app / 'Contents/Info.plist').open('wb') as file:
                plistlib.dump({'CFBundleIdentifier':'another.app'}, file)
            with self.assertRaises(RuntimeError):
                manage.manage('uninstall', home, PACKAGE, live=False)
            self.assertTrue(app.exists())

if __name__ == '__main__': unittest.main()
