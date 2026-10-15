#!/usr/bin/env bash
set -euo pipefail

THEME_NAME="minecraft"
NG_VERSION="${NODY_GREETER_VERSION:-1.6.2}"
THEME_DIR="/usr/share/web-greeter/themes/${THEME_NAME}"
CONF="/etc/lightdm/web-greeter.yml"
DROPIN="/etc/lightdm/lightdm.conf.d/99-minecraft-greeter.conf"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    exec sudo bash "${BASH_SOURCE[0]}" "$@"
fi

say()  { echo -e "\033[1;32m[greeter]\033[0m $*"; }
warn() { echo -e "\033[1;33m[greeter]\033[0m $*" >&2; }
die()  { echo -e "\033[1;31m[greeter]\033[0m $*" >&2; exit 1; }

uninstall() {
    say "Removing the Minecraft login screen..."
    rm -f "${DROPIN}"
    rm -rf "${THEME_DIR}"
    if [[ -f "${CONF}.bak-minecraft" ]]; then
        cp -f "${CONF}.bak-minecraft" "${CONF}"
    fi
    dpkg --purge nody-greeter || true
    say "Done. Next login screen will be the default slick-greeter again (reboot or log out)."
}

if [[ "${1:-}" == "--uninstall" ]]; then
    uninstall "$@"
    exit 0
fi



# ---------- 0. sanity checks ----------
command -v lightdm >/dev/null 2>&1 || die "LightDM not found. This module needs LightDM (Linux Mint's default)."
dm="$(cat /etc/X11/default-display-manager 2>/dev/null || true)"
[[ "$dm" == *lightdm* ]] || warn "Default display manager is '${dm:-unknown}', not LightDM. The greeter may not be used."



# ---------- 1. install nody-greeter if missing ----------
if [[ ! -f /usr/share/xgreeters/nody-greeter.desktop ]]; then
    . /etc/os-release
    if [[ "${ID:-}" == "debian" ]]; then variant="debian"; else variant="ubuntu"; fi   # Mint/Ubuntu -> ubuntu build
    deb="nody-greeter-${NG_VERSION}-${variant}.deb"
    url="https://github.com/JezerM/nody-greeter/releases/download/${NG_VERSION}/${deb}"
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    command -v curl >/dev/null 2>&1 || apt-get install -y curl
    say "Downloading ${deb}"
    curl -fL --retry 3 -o "${tmp}/${deb}" "${url}" || die "Download failed: ${url}"
    say "SHA-256: $(sha256sum "${tmp}/${deb}" | cut -d' ' -f1)"
    say "Installing nody-greeter ${NG_VERSION}"
    apt-get install -y "${tmp}/${deb}" || die "apt could not install the package (see message above). Nothing else was changed."
fi
command -v xsetroot >/dev/null 2>&1 || apt-get install -y x11-xserver-utils   # used by the greeter's wrapper script
[[ -f /usr/share/xgreeters/nody-greeter.desktop ]] || die "nody-greeter is not properly installed (/usr/share/xgreeters/nody-greeter.desktop missing). Not switching greeters."




# ---------- 2. install theme + assets ----------
say "Installing theme to ${THEME_DIR}"
rm -rf "${THEME_DIR}"
mkdir -p "${THEME_DIR}/assets"
cp -r "${HERE}/theme/." "${THEME_DIR}/"
cp -r "${HERE}/assets/." "${THEME_DIR}/assets/"
for f in index.html index.yml css/style.css js/main.js assets/logo.png assets/dirt.png assets/font.ttf; do
    [[ -f "${THEME_DIR}/${f}" ]] || die "Missing ${f} in the installed theme."
done
chmod -R a+rX "${THEME_DIR}"     # the 'lightdm' user must be able to read it




# ---------- 3. tell nody-greeter to use the theme (YAML config) ----------
if [[ -f "${CONF}" ]]; then
    [[ -f "${CONF}.bak-minecraft" ]] || cp "${CONF}" "${CONF}.bak-minecraft"
    if grep -Eq '^[[:space:]]+theme:' "${CONF}"; then
        sed -i -E "s/^([[:space:]]+)theme:.*/\1theme: ${THEME_NAME}/" "${CONF}"
    else
        sed -i -E "0,/^greeter:/s//greeter:\n    theme: ${THEME_NAME}/" "${CONF}"
    fi
    grep -Eq "^[[:space:]]+theme: *${THEME_NAME}" "${CONF}" || die "Could not set the theme in ${CONF}."
else
    warn "${CONF} not found, creating a minimal one."
    printf 'greeter:\n    theme: %s\n' "${THEME_NAME}" > "${CONF}"
fi




# ---------- 4. make LightDM use nody-greeter (drop-in overrides Mint's 70-linuxmint.conf) ----------
mkdir -p /etc/lightdm/lightdm.conf.d
printf '[Seat:*]\ngreeter-session=nody-greeter\n' > "${DROPIN}"
if grep -Eq '^\s*greeter-session' /etc/lightdm/lightdm.conf 2>/dev/null; then
    warn "/etc/lightdm/lightdm.conf sets greeter-session and takes priority over the drop-in. Remove or edit that line."
fi

say "✅ Minecraft login screen installed!"