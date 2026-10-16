#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="/usr/local/bin"
DATA="/usr/share/minecraft-desktop/desktop"
FONT_DIR="/usr/local/share/fonts/minecraft-desktop"
AUTOSTART="/etc/xdg/autostart/mc-hotbar.desktop"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    exec sudo MC_DESKTOP_SKIP_SETTINGS="${MC_DESKTOP_SKIP_SETTINGS:-}" bash "${BASH_SOURCE[0]}" "$@"
fi

say()  { echo -e "\033[1;32m[desktop]\033[0m $*"; }
warn() { echo -e "\033[1;33m[desktop]\033[0m $*" >&2; }
die()  { echo -e "\033[1;31m[desktop]\033[0m $*" >&2; exit 1; }

# Run mc-world-setup as the person who called sudo (settings are per user and need their session bus)
run_setup() {
    local mode="$1" user="${SUDO_USER:-}"
    if [[ -z "$user" || "$user" == "root" ]]; then
        warn "Could not tell which user to configure. Run this yourself as that user:  mc-world-setup ${mode}"
        return 0
    fi
    local uid; uid="$(id -u "$user")"
    if [[ ! -S "/run/user/${uid}/bus" ]]; then
        warn "${user} has no running desktop session, so settings were not changed. Log in, then run:  mc-world-setup ${mode}"
        return 0
    fi
    sudo -u "$user" env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${uid}/bus" XDG_RUNTIME_DIR="/run/user/${uid}" \
        "${BIN_DIR}/mc-world-setup" "${mode}" || warn "mc-world-setup ${mode} reported a problem (see above)."
}

if [[ "${1:-}" == "--uninstall" ]]; then
    say "Removing the Minecraft desktop..."
    if [[ -x "${BIN_DIR}/mc-world-setup" && -z "${MC_DESKTOP_SKIP_SETTINGS:-}" ]]; then run_setup --restore; fi
    pkill -u "${SUDO_USER:-nobody}" -x mc-hotbar 2>/dev/null || true
    rm -f "${AUTOSTART}" "${BIN_DIR}/mc-hotbar" "${BIN_DIR}/mc-world-setup"
    rm -rf "${DATA}"
    rmdir --ignore-fail-on-non-empty /usr/share/minecraft-desktop 2>/dev/null || true
    say "Done. Log out and back in."
    exit 0
fi

# 1. dependencies (only installs what is missing)
missing=()
for pkg in python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-wnck-3.0 gir1.2-pango-1.0 gir1.2-gdkpixbuf-2.0 x11-utils pulseaudio-utils python3-xlib; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
if ((${#missing[@]})); then
    say "Installing packages: ${missing[*]}"
    apt-get install -y "${missing[@]}"
fi

# 2. programs
for f in mc-hotbar mc-world-setup; do
    [[ -f "${HERE}/bin/${f}" ]] || die "Missing ${HERE}/bin/${f}"
    install -Dm755 "${HERE}/bin/${f}" "${BIN_DIR}/${f}"
done

# 3. assets
mkdir -p "${DATA}"
rm -f "${DATA}"/world.*
cp -f "${HERE}/assets/"*.png "${DATA}/"
cp -f "${HERE}/assets/"click.ogg "${DATA}/"
chmod -R a+rX "${DATA}"

# 4. font
font_src="${HERE}/../greeter/assets/font.ttf"
if [[ -f "$font_src" ]]; then
    install -Dm644 "$font_src" "${FONT_DIR}/Monocraft.ttf"
    fc-cache -f >/dev/null 2>&1 || true
    say "Installed font from ${font_src}"
else
    warn "No Monocraft font found; the percentage will use a fallback font."
fi

# 5. start the hotbar at every login
cat > "${AUTOSTART}" <<EOD
[Desktop Entry]
Type=Application
Name=Minecraft hotbar
Comment=Hotbar taskbar and app launcher
Exec=${BIN_DIR}/mc-hotbar
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOD

# 6. your Cinnamon settings: wallpaper, hidden icons, auto-hidden panel, Super+1..9
if [[ -n "${MC_DESKTOP_SKIP_SETTINGS:-}" ]]; then
    warn "Skipping Cinnamon settings (MC_DESKTOP_SKIP_SETTINGS is set). Apply later with: mc-world-setup --apply"
else
    run_setup --apply
fi

say "✅ Minecraft desktop installed!"