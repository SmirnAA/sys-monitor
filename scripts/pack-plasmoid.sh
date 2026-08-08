#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-${ROOT_DIR}/dist}"
PLUGIN_ID="$(jq -r '.KPlugin.Id' "${ROOT_DIR}/metadata.json")"

mkdir -p "$OUT_DIR"
ARCHIVE_PATH="${OUT_DIR}/${PLUGIN_ID}.plasmoid"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cp -R \
    "${ROOT_DIR}/contents" \
    "${ROOT_DIR}/icons" \
    "${ROOT_DIR}/LICENSE" \
    "${ROOT_DIR}/metadata.json" \
    "$TMP_DIR/"

find "$TMP_DIR/contents" -type d -name '__pycache__' -prune -exec rm -rf {} +
find "$TMP_DIR/contents" -type f -name '*.pyc' -delete

(
    cd "$TMP_DIR"
    zip -qr "$ARCHIVE_PATH" metadata.json contents icons LICENSE
)

echo "Created ${ARCHIVE_PATH}"
