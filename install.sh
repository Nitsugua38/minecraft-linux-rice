#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Double-clicked from the file manager: there is no terminal to ask questions or type the sudo password
if [[ ! -t 0 || ! -t 1 ]]; then
    msg="Please run the installer from a terminal:\n\ncd \"$HERE\"\nsudo ./install.sh"
    if command -v zenity >/dev/null; then
        zenity --warning --title="Minecraft Linux Rice" --text="$msg" --width=420 2>/dev/null || true
    elif command -v notify-send >/dev/null; then
        notify-send "Minecraft Linux Rice" "$(echo -e "$msg")" || true
    fi
    echo -e "$msg" >&2
    exit 1
fi

MODULES=(plymouth greeter splash desktop lockscreen)

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

if [[ -t 0 ]]; then
    echo
    read -rp "Done. A reboot is needed to see every change. Reboot now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy] ]]; then
        systemctl reboot
    else
        echo "OK, reboot later to apply everything."
    fi
fi
