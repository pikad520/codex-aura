#!/bin/zsh
set -eu
package_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
/usr/bin/python3 "$package_dir/manage.py" uninstall
/usr/bin/python3 "$package_dir/scripts/localization.py" pressReturn
read -r response
