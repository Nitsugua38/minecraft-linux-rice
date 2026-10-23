#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODULES=(plymouth greeter splash desktop)

ONLY=""
ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --only) ONLY="$2"; shift 2 ;;
        *) ARGS+=("$1"); shift ;;
    esac
done

if [[ " ${ARGS[*]-} " != *" --uninstall "* && -t 0 ]]; then
    echo "Textures, sounds and logos are not included in this repo (they belong to Mojang)."
    echo "They can be automatically copied from your own Minecraft Java installation."
    read -rp "Install the assets from your installed Minecraft? [Y/n] " answer
    if [[ ! "$answer" =~ ^[Nn] ]]; then
        bash "$HERE/helper/asset_installer.sh" || echo "Asset copy failed, continuing without it (you can add them by hand)."
    fi
fi

for m in "${MODULES[@]}"; do
    [[ -n "$ONLY" && "$ONLY" != "$m" ]] && continue
    if [[ -f "$HERE/$m/installer.sh" ]]; then
        echo "=== Module: $m ==="
        bash "$HERE/$m/installer.sh" "${ARGS[@]}"
    fi
done