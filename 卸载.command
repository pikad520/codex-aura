#!/bin/zsh
set -eu
package_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
/usr/bin/python3 "$package_dir/manage.py" uninstall
printf "\n按回车关闭此窗口…"
read -r response
