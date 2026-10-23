#!/usr/bin/env bash
# Copies the Minecraft textures and sounds this rice uses from YOUR Minecraft Java installation
# (the newest version jar in .minecraft, plus the launcher's downloaded sounds) into the repo's asset folders.
# Nothing is downloaded. Existing files are kept unless --force.
#
#   helper/asset_installer.sh [--minecraft-dir DIR] [--jar FILE] [--force]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$HERE")"

say() { echo -e "\033[1;32m[assets]\033[0m $*"; }
warn() { echo -e "\033[1;33m[assets]\033[0m $*" >&2; }

MC_DIR=""
JAR=""
FORCE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --minecraft-dir) MC_DIR="$2"; shift 2 ;;
        --jar) JAR="$2"; shift 2 ;;
        --force) FORCE=1; shift ;;
        -h|--help) sed -n '2,6p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) warn "Unknown option: $1"; exit 1 ;;
    esac
done

command -v python3 >/dev/null || { warn "python3 is required."; exit 1; }

# When run through sudo, look in the real user's home and give them the files
USER_HOME="$HOME"
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
fi

if [[ -z "$MC_DIR" ]]; then
    for d in "$USER_HOME/.minecraft" "$USER_HOME/.var/app/com.mojang.Minecraft/.minecraft"; do
        if [[ -d "$d/versions" ]]; then MC_DIR="$d"; break; fi
    done
fi
if [[ -z "$MC_DIR" && -z "$JAR" ]]; then
    warn "No .minecraft folder found. Launch Minecraft Java once, or pass --minecraft-dir / --jar."
    exit 1
fi

say "Minecraft folder: ${MC_DIR:-none}"
python3 - "$REPO" "$MC_DIR" "$JAR" "$FORCE" <<'PY'
import json, os, shutil, struct, sys, zipfile

repo, mc_dir, jar_path, force = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
T = "assets/minecraft/textures/"
HUD = T + "gui/sprites/hud/"

# destination (relative to the repo) -> path inside the jar
TEXTURES = {
    "desktop/assets/hotbar.png": HUD + "hotbar.png",
    "desktop/assets/hotbar_selection.png": HUD + "hotbar_selection.png",
    "desktop/assets/hotbar_offhand_left.png": HUD + "hotbar_offhand_left.png",
    "desktop/assets/heart_container.png": HUD + "heart/container.png",
    "desktop/assets/heart_full.png": HUD + "heart/full.png",
    "desktop/assets/heart_half.png": HUD + "heart/half.png",
    "desktop/assets/armor_empty.png": HUD + "armor_empty.png",
    "desktop/assets/armor_half.png": HUD + "armor_half.png",
    "desktop/assets/armor_full.png": HUD + "armor_full.png",
    "desktop/assets/food_empty.png": HUD + "food_empty.png",
    "desktop/assets/food_half.png": HUD + "food_half.png",
    "desktop/assets/food_full.png": HUD + "food_full.png",
    "desktop/assets/xp_bg.png": HUD + "experience_bar_background.png",
    "desktop/assets/xp_fill.png": HUD + "experience_bar_progress.png",
    "desktop/assets/inventory.png": T + "gui/container/creative_inventory/tab_items.png",
    "desktop/assets/scroller.png": T + "gui/sprites/container/creative_inventory/scroller.png",
    "desktop/assets/button.png": T + "gui/sprites/widget/button.png",
    "desktop/assets/button_highlighted.png": T + "gui/sprites/widget/button_highlighted.png",
    "desktop/assets/toast.png": T + "gui/sprites/toast/advancement.png",
    "splash/assets/dirt.png": T + "block/dirt.png",
    "greeter/assets/dirt.png": T + "block/dirt.png",
    "greeter/assets/logo.png": T + "gui/title/minecraft.png",
}
for i in range(64):
    TEXTURES["desktop/assets/clock_%02d.png" % i] = T + "item/clock_%02d.png" % i

# destination -> key in the launcher's asset index
SOUNDS = {
    "desktop/assets/click.ogg": "minecraft/sounds/random/click.ogg",
    "desktop/assets/toast.ogg": "minecraft/sounds/ui/toast/in.ogg",
}
MENU_MUSIC = "minecraft/sounds/music/menu/"

uid, gid = os.environ.get("SUDO_UID"), os.environ.get("SUDO_GID")
stats = {"copied": 0, "kept": 0, "missing": []}


def give_to_user(path):
    if uid and gid:
        try:
            os.chown(path, int(uid), int(gid))
        except OSError:
            pass


def write(rel, data):
    dest = os.path.join(repo, rel)
    if os.path.exists(dest) and not force:
        stats["kept"] += 1
        return
    d = os.path.dirname(dest)
    if not os.path.isdir(d):
        os.makedirs(d, exist_ok=True)
        give_to_user(d)
    with open(dest, "wb") as f:
        f.write(data)
    give_to_user(dest)
    stats["copied"] += 1


def png_size(data):
    return struct.unpack(">II", data[16:24]) if data[:8] == b"\x89PNG\r\n\x1a\n" else (0, 0)


# ---- pick the jar: newest release that has a jar (snapshots only if there is no release)
version = None
if not jar_path:
    found = []
    vdir = os.path.join(mc_dir, "versions")
    for v in os.listdir(vdir):
        j, js = os.path.join(vdir, v, v + ".jar"), os.path.join(vdir, v, v + ".json")
        if not (os.path.isfile(j) and os.path.getsize(j) > 0 and os.path.isfile(js)):
            continue
        try:
            meta = json.load(open(js))
        except (OSError, ValueError):
            continue
        found.append((meta.get("type") == "release", meta.get("releaseTime", ""), v, j, meta))
    if not found:
        sys.exit("[assets] No installed version with a .jar in %s/versions. Play any version once." % mc_dir)
    found.sort()
    _, _, version, jar_path, meta = found[-1]
else:
    meta = {}
print("[assets] Using %s" % (("version " + version) if version else jar_path))

try:
    jar = zipfile.ZipFile(jar_path)
except (OSError, zipfile.BadZipFile) as e:
    sys.exit("[assets] Cannot open %s: %s" % (jar_path, e))
names = set(jar.namelist())

# ---- textures
for rel, src in TEXTURES.items():
    if src in names:
        write(rel, jar.read(src))
    else:
        stats["missing"].append(rel)

# Mojang Studios logo for the boot screen: the jar stores it as two halves stacked (left part on top);
# put them side by side. Needs GdkPixbuf; skipped otherwise.
src = T + "gui/title/mojangstudios.png"
if src in names:
    try:
        import gi
        gi.require_version("GdkPixbuf", "2.0")
        from gi.repository import GdkPixbuf
        loader = GdkPixbuf.PixbufLoader.new_with_type("png")
        loader.write(jar.read(src)); loader.close()
        pb = loader.get_pixbuf()
        w, h = pb.get_width(), pb.get_height() // 2
        out = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, 2 * w, h)
        out.fill(0)
        pb.copy_area(0, 0, w, h, out, 0, 0)
        pb.copy_area(0, h, w, h, out, w, 0)
        ok, data = out.save_to_bufferv("png", [], [])
        if ok:
            write("plymouth/assets/logo.png", bytes(data))
    except Exception as e:
        print("[assets] Could not build the Mojang logo (%s), skipped" % e)
        stats["missing"].append("plymouth/assets/logo.png")
else:
    stats["missing"].append("plymouth/assets/logo.png")

# Title-screen panorama: recent versions ship a 1x1 placeholder (the panorama is rendered live), so
# only take it when it is a real image. Goes into the first free numbered folder, unless already there.
pano = [T + "gui/title/background/panorama_%d.png" % i for i in range(6)]
if all(p in names for p in pano) and png_size(jar.read(pano[0]))[0] >= 64:
    first = jar.read(pano[0])
    base = os.path.join(repo, "greeter/assets")
    n, dup = 1, False
    while os.path.isdir(os.path.join(base, str(n))):
        p0 = os.path.join(base, str(n), "panorama_0.png")
        if os.path.isfile(p0) and open(p0, "rb").read() == first:
            dup = True
            break
        if not os.path.isfile(p0):
            break                                      # empty folder: fill it
        n += 1
    if dup:
        stats["kept"] += 6
    else:
        for i, p in enumerate(pano):
            write("greeter/assets/%d/panorama_%d.png" % (n, i), jar.read(p))
else:
    print("[assets] This version has no panorama images (only a placeholder): add your own in greeter/assets/<N>/")

# ---- sounds and menu music, from the launcher's downloaded objects
index = None
aid = (meta.get("assetIndex") or {}).get("id")
if mc_dir and aid:
    try:
        index = json.load(open(os.path.join(mc_dir, "assets", "indexes", aid + ".json")))["objects"]
    except (OSError, ValueError, KeyError):
        index = None
if index is None:
    print("[assets] No sound index found (sounds are only available from a launcher install), skipped")
    stats["missing"] += list(SOUNDS)
else:
    def obj(key):
        h = (index.get(key) or {}).get("hash")
        p = os.path.join(mc_dir, "assets", "objects", h[:2], h) if h else None
        return open(p, "rb").read() if p and os.path.isfile(p) else None
    for rel, key in SOUNDS.items():
        data = obj(key)
        if data is not None:
            write(rel, data)
        else:
            stats["missing"].append(rel)
    for key in sorted(k for k in index if k.startswith(MENU_MUSIC) and k.endswith(".ogg")):
        data = obj(key)
        if data is not None:
            write("greeter/assets/music/" + key[len(MENU_MUSIC):], data)

print("[assets] %d file(s) copied, %d already there (kept; use --force to replace)" % (stats["copied"], stats["kept"]))
if stats["missing"]:
    print("[assets] Not found in this version: " + ", ".join(sorted(set(stats["missing"]))))
print("[assets] Still to add by hand (not in the game files): desktop/assets/chest.png, desktop/assets/world.png")
PY
