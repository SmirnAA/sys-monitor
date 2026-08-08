#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: required command not found: $1" >&2
        exit 1
    fi
}

run_step() {
    local label="$1"
    shift
    echo "==> ${label}"
    "$@"
}

need_cmd jq
need_cmd python3
need_cmd bash
need_cmd zip
need_cmd unzip

run_step "Metadata JSON validation" jq empty "${ROOT_DIR}/metadata.json"
run_step "Installer syntax validation" bash -n "${ROOT_DIR}/install.sh"
run_step "Helper syntax validation" python3 -m py_compile "${ROOT_DIR}/contents/code/monitor.py"
rm -rf "${ROOT_DIR}/contents/code/__pycache__"

if command -v qmllint >/dev/null 2>&1; then
    while IFS= read -r file; do
        run_step "QML lint: $(basename "$file")" qmllint "$file"
    done < <(find "${ROOT_DIR}/contents" -name '*.qml' | sort)
else
    echo "==> QML lint"
    echo "SKIP: qmllint not installed."
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

run_step "Pack plasmoid" "${ROOT_DIR}/scripts/pack-plasmoid.sh" "$TMP_DIR"
PACK_FILE="$(find "$TMP_DIR" -maxdepth 1 -name '*.plasmoid' -print -quit)"

if [[ -z "$PACK_FILE" ]]; then
    echo "ERROR: expected plasmoid archive was not created." >&2
    exit 1
fi

run_step "Packed archive integrity" unzip -t "$PACK_FILE"
echo "==> All checks completed."
