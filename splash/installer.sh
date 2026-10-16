#!/usr/bin/env bash
set -euo pipefail

BIN="/usr/local/bin/mc-splash"
DATA="/usr/share/minecraft-desktop/splash"
FONT_DIR="/usr/local/share/fonts/minecraft-desktop"
AUTOSTART="/etc/xdg/autostart/mc-splash.desktop"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DURATION="${MC_SPLASH_DURATION:-5}"

if [[ $EUID -ne 0 ]]; then
    exec sudo MC_SPLASH_DURATION="$DURATION" bash "${BASH_SOURCE[0]}" "$@"
fi

say()  { echo -e "\033[1;32m[splash]\033[0m $*"; }
warn() { echo -e "\033[1;33m[splash]\033[0m $*" >&2; }
die()  { echo -e "\033[1;31m[splash]\033[0m $*" >&2; exit 1; }

if [[ "${1:-}" == "--uninstall" ]]; then
    say "Removing the loading screen..."
    rm -f "${AUTOSTART}" "${BIN}"
    rm -rf "${DATA}" "${FONT_DIR}"
    rmdir --ignore-fail-on-non-empty /usr/share/minecraft-desktop 2>/dev/null || true
    fc-cache -f >/dev/null 2>&1 || true
    say "Done."
    exit 0
fi

# 1. dependencies (only installs what is missing)
missing=()
for pkg in python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-pango-1.0 gir1.2-gdkpixbuf-2.0; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
if ((${#missing[@]})); then
    say "Installing packages: ${missing[*]}"
    apt-get install -y "${missing[@]}"
fi

# 2. program
install -Dm755 "${HERE}/bin/mc-splash" "${BIN}"

# 3. assets
mkdir -p "${DATA}"
cp -f "${HERE}/assets/"*.png "${DATA}/"
chmod -R a+rX "${DATA}"

# 4. font: reuse the Monocraft font
font_src="${HERE}/../greeter/assets/font.ttf"
if [[ -f "$font_src" ]]; then
    install -Dm644 "$font_src" "${FONT_DIR}/Monocraft.ttf"
    fc-cache -f >/dev/null 2>&1 || true
    say "Installed font from ${font_src}"
else
    warn "No Monocraft font found; the percentage will use a fallback font."
fi

# 5. autostart for every user at login
cat > "${AUTOSTART}" <<EOD
[Desktop Entry]
Type=Application
Name=Minecraft loading screen
Comment=Fake world-generation screen shown while the desktop loads
Exec=${BIN} --duration ${DURATION} --scale 1.5 --ready-file auto --timeout 5
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Phase=Initialization
EOD

say "✅ Minecraft splash screen installed!"