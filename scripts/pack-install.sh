#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UUID="$(jq -r '.uuid' "$ROOT_DIR/metadata.json")"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$UUID"
ZIP="$ROOT_DIR/${UUID}.shell-extension.zip"

echo "==> Pack extension zip"
cd "$ROOT_DIR"
gnome-extensions pack . --force --out-dir . --extra-source=icons
cp "$ZIP" sysmon.shell-extension.zip
echo "    Created: $ZIP"

echo "==> Remove old install"
gnome-extensions disable "$UUID" 2>/dev/null || true
rm -rf "$EXT_DIR"
rm -rf "$HOME/.local/share/gnome-shell/extension-updates/$UUID" 2>/dev/null || true

echo "==> Install new zip"
gnome-extensions install --force "$ZIP"

echo "==> Compile schemas"
glib-compile-schemas "$EXT_DIR/schemas/"
mkdir -p "$HOME/.local/share/glib-2.0/schemas"
cp "$EXT_DIR/schemas/org.gnome.shell.extensions.sysmon.gschema.xml" "$HOME/.local/share/glib-2.0/schemas/"
glib-compile-schemas "$HOME/.local/share/glib-2.0/schemas/"

echo "==> Enable extension"
gnome-extensions enable "$UUID"
sleep 2

STATE="$(gnome-extensions info "$UUID" | awk -F': ' '/State:/ {print $2}')"
VERSION="$(jq -r '.version' "$EXT_DIR/metadata.json")"
echo "==> Done: version $VERSION, state $STATE"

if [[ "$STATE" == "ERROR" ]]; then
    echo "==> Log out and log back in, then run: gnome-extensions enable $UUID"
else
    echo "==> Close the dropdown if open, then click the panel icon again."
fi
