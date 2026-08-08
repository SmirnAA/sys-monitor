#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID="$(jq -r '.KPlugin.Id' "$ROOT_DIR/metadata.json")"
TARGET_DIR="$HOME/.local/share/plasma/plasmoids/$PLUGIN_ID"

echo "Installing $PLUGIN_ID to $TARGET_DIR..."

if command -v kpackagetool6 >/dev/null 2>&1; then
    kpackagetool6 --type Plasma/Applet --upgrade "$ROOT_DIR" >/dev/null 2>&1 || \
        kpackagetool6 --type Plasma/Applet --install "$ROOT_DIR"
else
    rm -rf "$TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    cp -R \
        "$ROOT_DIR/contents" \
        "$ROOT_DIR/icons" \
        "$ROOT_DIR/LICENSE" \
        "$ROOT_DIR/metadata.json" \
        "$TARGET_DIR/"
fi

echo "Installation complete."
echo "Add the widget named 'System Monitor' from KDE Plasma widgets if it is not already on your panel."
echo "If Plasma does not pick up the update immediately, run: kquitapp6 plasmashell && kstart6 plasmashell"
