#!/usr/bin/env python3
"""Install/remove only this companion's files; never touch Codex itself."""
import argparse
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import time
from scripts.localization import translator

IDENTIFIER = 'local.codex.aura'
T = translator(Path.home())

def paths(home):
    return (home / 'Applications/Codex Aura.app',
            home / 'Library/LaunchAgents/local.codex.aura.plist',
            home / 'Library/Application Support/Codex Aura')

def ensure_owned_app(app):
    if not app.exists() and not app.is_symlink():
        return
    if app.is_symlink():
        raise RuntimeError(f'{T("manageSymlink")} {app}')
    with (app / 'Contents/Info.plist').open('rb') as source:
        if plistlib.load(source).get('CFBundleIdentifier') != IDENTIFIER:
            raise RuntimeError(f'{T("manageForeign")} {app}')

def remove_owned(path):
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.exists():
        shutil.rmtree(path)

def run(command, required=True):
    return subprocess.run(command, check=required, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)

def stop(app, agent):
    # bootout first: do not restart an app while replacing/removing it.
    run(['/bin/launchctl', 'bootout', f'gui/{os.getuid()}/{IDENTIFIER}'], required=False)
    if app.exists():
        ensure_owned_app(app)
        run([str(app / 'Contents/MacOS/CodexAura'), '--quit'], required=False)
        time.sleep(.5)

def manage(action, home, package, live=True, launch=True):
    app, agent, data = paths(home)
    ensure_owned_app(app)
    if action == 'install':
        source = package / 'Codex Aura.app'
        ensure_owned_app(source)
        if not source.is_dir():
            raise RuntimeError(T('manageMissing'))
        if live:
            stop(app, agent)
        remove_owned(app)
        app.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(source, app)
        if live and launch:
            run(['/usr/bin/open', '-g', str(app)])
        # Preserve and reload an existing explicit opt-in after updates.
        if live and agent.exists():
            run(['/bin/launchctl', 'bootstrap', f'gui/{os.getuid()}', str(agent)])
        return f'{T("manageInstalled")} {app}\n{T("manageNoStartup")}'
    if action == 'enable-login':
        if not app.exists():
            raise RuntimeError(T('manageInstallFirst'))
        payload = {'Label': IDENTIFIER, 'ProgramArguments': [str(app / 'Contents/MacOS/CodexAura')],
                   'RunAtLoad': True, 'ProcessType': 'Interactive'}
        agent.parent.mkdir(parents=True, exist_ok=True)
        with agent.open('wb') as target:
            plistlib.dump(payload, target)
        if live:
            run(['/bin/launchctl', 'bootout', f'gui/{os.getuid()}/{IDENTIFIER}'], required=False)
            run(['/bin/launchctl', 'bootstrap', f'gui/{os.getuid()}', str(agent)])
        return T('manageStartup')
    if action == 'uninstall':
        if live:
            stop(app, agent)
        for owned in (agent, app, data):
            remove_owned(owned)
        return T('manageRemoved')
    raise ValueError(action)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=T("manageDescription"))
    parser.add_argument('action', choices=['install', 'enable-login', 'uninstall'])
    parser.add_argument('--no-launch', action='store_true', help=T('manageNoLaunch'))
    args = parser.parse_args()
    try:
        print(manage(args.action, Path.home(), Path(__file__).resolve().parent, launch=not args.no_launch))
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f'{T("manageFailed")} {error}')
        raise SystemExit(1)
