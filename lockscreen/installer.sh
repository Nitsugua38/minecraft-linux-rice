#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="/usr/local/bin"
DATA="/usr/share/minecraft-desktop/lockscreen"
FONT_DIR="/usr/local/share/fonts/minecraft-lockscreen"
AUTOSTART="/etc/xdg/autostart/mc-sleep-lock.desktop"
GREETER_THEME="/usr/share/web-greeter/themes/minecraft"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    exec sudo bash "${BASH_SOURCE[0]}" "$@"
fi

say()  { echo -e "\033[1;32m[lockscreen]\033[0m $*"; }
warn() { echo -e "\033[1;33m[lockscreen]\033[0m $*" >&2; }
die()  { echo -e "\033[1;31m[lockscreen]\033[0m $*" >&2; exit 1; }

# Run mc-lock-setup as the person who called sudo (per-user settings, needs their session bus)
run_setup() {
    local mode="$1" user="${SUDO_USER:-}"
    if [[ -z "$user" || "$user" == "root" ]]; then
        warn "Could not tell which user to configure. Run this yourself as that user:  mc-lock-setup ${mode}"
        return 0
    fi
    local uid; uid="$(id -u "$user")"
    if [[ ! -S "/run/user/${uid}/bus" ]]; then
        warn "${user} has no running desktop session, so nothing was changed. Log in, then run:  mc-lock-setup ${mode}"
        return 0
    fi
    sudo -u "$user" -H env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${uid}/bus" XDG_RUNTIME_DIR="/run/user/${uid}" \
        "${BIN_DIR}/mc-lock-setup" "${mode}" || warn "mc-lock-setup ${mode} reported a problem (see above)."
}

if [[ "${1:-}" == "--uninstall" ]]; then
    say "Removing the Minecraft lock screen..."
    if [[ -x "${BIN_DIR}/mc-lock-setup" ]]; then run_setup --restore; fi
    pkill -u "${SUDO_USER:-nobody}" -f "${BIN_DIR}/mc-sleep-lock" 2>/dev/null || true
    rm -f "${BIN_DIR}/mc-lock-setup" "${BIN_DIR}/mc-sleep-lock" "${AUTOSTART}"
    rm -rf "${DATA}" "${FONT_DIR}"
    rmdir --ignore-fail-on-non-empty /usr/share/minecraft-desktop 2>/dev/null || true
    fc-cache -f >/dev/null 2>&1 || true
    say "Done. Cinnamon's own lock screen is back (log out and in to stop the sleep lock)."
    exit 0
fi

command -v cinnamon-screensaver >/dev/null || die "cinnamon-screensaver not found (Lock uses Cinnamon's lock screen)."
command -v dm-tool >/dev/null || warn "dm-tool not found: Sleep will not show the in-bed screen (needs LightDM)."
[[ -d "${GREETER_THEME}" ]] || warn "The Minecraft greeter is not installed, so waking from sleep shows the plain greeter. Install it with: sudo ./install.sh --only greeter"

# 1. programs
for f in mc-lock-setup mc-sleep-lock; do
    [[ -f "${HERE}/bin/${f}" ]] || die "Missing ${HERE}/bin/${f}"
    install -Dm755 "${HERE}/bin/${f}" "${BIN_DIR}/${f}"
done

# 2. "You Died!" style and its images (all optional)
rm -rf "${DATA}"
mkdir -p "${DATA}"
install -m644 "${HERE}/died.css" "${DATA}/died.css"
for f in died_title respawn respawn_highlighted title_screen title_screen_highlighted; do
    if [[ -f "${HERE}/assets/${f}.png" ]]; then
        install -m644 "${HERE}/assets/${f}.png" "${DATA}/${f}.png"
    else
        warn "Missing ${HERE}/assets/${f}.png, that part of the lock screen stays plain."
    fi
done
chmod -R a+rX "${DATA}"

# 3. font
font_src="${HERE}/../greeter/assets/font.ttf"
if [[ -f "$font_src" ]]; then
    install -Dm644 "$font_src" "${FONT_DIR}/Monocraft.ttf"
    fc-cache -f >/dev/null 2>&1 || true
else
    warn "No Monocraft font found; the lock screen will use a fallback font."
fi

# 4. lock in bed before sleeping, at every login
cat > "${AUTOSTART}" <<EOD
[Desktop Entry]
Type=Application
Name=Minecraft sleep lock
Comment=Lock through LightDM (in-bed screen) before the computer sleeps
Exec=${BIN_DIR}/mc-sleep-lock
Terminal=false
NoDisplay=true
OnlyShowIn=X-Cinnamon;
X-GNOME-Autostart-enabled=true
EOD

# 5. your settings: style import, fonts, Cinnamon's lock-on-suspend off
run_setup --apply

say "✅ Minecraft lock screen installed! Log out and back in once (starts the sleep lock)."
say "   Lock (Super+L) = You Died!    Sleep = wake up in bed"
