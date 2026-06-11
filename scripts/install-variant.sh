#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UUID="$(jq -r '.uuid' "$ROOT_DIR/metadata.json")"
VARIANT="${1:-gnome45-50}"
ZIP="$ROOT_DIR/dist/${UUID}-${VARIANT}.shell-extension.zip"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$UUID"

if [[ ! -f "$ZIP" ]]; then
    echo "ERROR: zip not found: $ZIP" >&2
    echo "Run: make pack-dual" >&2
    exit 1
fi

echo "==> Install variant: $VARIANT"
gnome-extensions disable "$UUID" 2>/dev/null || true
rm -rf "$EXT_DIR"
rm -rf "$HOME/.local/share/gnome-shell/extension-updates/$UUID" 2>/dev/null || true

gnome-extensions install --force "$ZIP"
glib-compile-schemas "$EXT_DIR/schemas/"
mkdir -p "$HOME/.local/share/glib-2.0/schemas"
cp "$EXT_DIR/schemas/org.gnome.shell.extensions.sysmon.gschema.xml" "$HOME/.local/share/glib-2.0/schemas/"
glib-compile-schemas "$HOME/.local/share/glib-2.0/schemas/"

gnome-extensions enable "$UUID"
sleep 2

STATE="$(gnome-extensions info "$UUID" | awk -F': ' '/State:/ {print $2}')"
VERSION="$(jq -r '.version' "$EXT_DIR/metadata.json")"
SHELL="$(jq -r '."shell-version" | join(", ")' "$EXT_DIR/metadata.json")"
echo "==> Done: v${VERSION} | GNOME ${SHELL} | state ${STATE}"
