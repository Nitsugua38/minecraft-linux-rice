#!/usr/bin/env bash
set -euo pipefail

THEME_NAME="minecraft"
THEME_DIR="/usr/share/plymouth/themes/${THEME_NAME}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    exec sudo bash "${BASH_SOURCE[0]}" "$@"
fi

say() { echo -e "\033[1;32m[plymouth]\033[0m $*"; }
warn() { echo -e "\033[1;33m[plymouth]\033[0m $*" >&2; }

uninstall() {
    say "Removing theme and restoring the previous default..."
    update-alternatives --remove default.plymouth "${THEME_DIR}/${THEME_NAME}.plymouth" 2>/dev/null || true
    update-alternatives --auto default.plymouth 2>/dev/null || true
    rm -rf "${THEME_DIR}"
    update-initramfs -u -k all
    say "Done. Reboot to see the old boot screen."
}

if [[ "${1:-}" == "--uninstall" ]]; then
    uninstall
    exit 0
fi

# 1. Packages (only installs what is missing)
missing=()
for pkg in plymouth plymouth-label plymouth-themes; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
if ((${#missing[@]})); then
    say "Installing packages: ${missing[*]}"
    apt-get install -y "${missing[@]}"
fi

# 2. Copy theme + assets (assets-custom/ overrides the placeholder assets/)
say "Copying theme to ${THEME_DIR}"
mkdir -p "${THEME_DIR}"
cp -f "${HERE}/theme/"* "${THEME_DIR}/"
cp -f "${HERE}/assets/"*.png "${THEME_DIR}/"

for f in logo.png progress-box.png progress-bar.png minecraft.plymouth minecraft.script; do
    [[ -f "${THEME_DIR}/${f}" ]] || { warn "Missing ${f}, aborting."; exit 1; }
done

# 3. Make sure GRUB shows the splash
if [[ -f /etc/default/grub ]]; then
    changed=0
    for word in quiet splash; do
        if ! grep -Eq "^GRUB_CMDLINE_LINUX_DEFAULT=.*\b${word}\b" /etc/default/grub; then
            [[ $changed -eq 0 ]] && cp -n /etc/default/grub /etc/default/grub.bak-minecraft
            sed -i -E "s/^(GRUB_CMDLINE_LINUX_DEFAULT=\")(.*)\"/\1\2 ${word}\"/" /etc/default/grub
            changed=1
        fi
    done
    if [[ $changed -eq 1 ]]; then
        say "Updated GRUB (backup: /etc/default/grub.bak-minecraft)"
        update-grub
    fi
fi

# 4. Activate theme and rebuild the initramfs
say "Activating theme"
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
    "${THEME_DIR}/${THEME_NAME}.plymouth" 100
update-alternatives --set default.plymouth "${THEME_DIR}/${THEME_NAME}.plymouth"

say "Rebuilding initramfs (takes a moment)..."
update-initramfs -u -k all

say "✅ Minecraft boot screen installed!"