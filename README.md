# Minecraft Linux Rice

**Turn Linux Mint (Cinnamon, X11) into a Minecraft-style desktop:** from the boot logo to the login screen, the loading screen, the hotbar taskbar and the inventory app launcher.

| Module | script |
|---|---|
| Minecraft Boot logo | plymouth |
| Minecraft title-screen login | greeter |
| Minecraft Generating World loading screen | splash |
| Minecraft HUD taskbar + app drawer | desktop |


Requirements: Linux Mint with Cinnamon on X11, LightDM (Mint's default), and a compositor (Cinnamon's default) for transparency. Everything is installed in userspace and system config files.

---

## What it does

**Boot (`plymouth`)**: replaces the boot screen with the Mojang Studios logo on the classic red background and a loading bar.

**Login (`greeter`)**: a Minecraft title screen as your login screen, built on [nody-greeter](https://github.com/JezerM/nody-greeter):
- Rotating panorama background (random set each boot), the Minecraft logo and a random yellow splash text.
- *Play* logs in, *Switch Player* picks another user, *Session* cycles desktop sessions, *Restart* and *Quit Game* reboot and shut down.
- The password prompt is the "Direct Connection" screen.
- A random track from `greeter/assets/music/` plays and fades out when the session starts.

**Loading screen (`splash`)**: a "Generating world" loading screen shown right after login, until the desktop is ready.

**Desktop (`desktop`)**: replaces the taskbar with the custom `mc-hotbar`:
- **Hotbar**: pinned apps are the slots. Click or press `Super+1` ... `Super+9`.
- **HUD indicators** above the hotbar: hearts = battery (they hop while charging), armor = Wi-Fi strength, XP bar = volume (click or drag it, the wheel works too), an offhand slot left of the hotbar holds a clock (its dial follows the real time, `HH:MM` next to it, click for a calendar; it stays visible over apps), hunger = free disk space in your home (1 drumstick = 10 %, it empties from the left like in the game; click opens the disk usage analyzer). Each one opens the matching system settings when clicked.
- **Chest slot**: hover it to see every open window that is not pinned, click one to bring it to the front.
- **Inventory**: press `Super` alone to open every installed app in the creative-inventory layout. Type to search, `Enter` launches the first result, drag an app onto a hotbar slot to pin it, drag it out of the bar to unpin it.
- **Game Menu**: press `Esc` twice inside the inventory. *Back to Game*, *Lock*, *Sleep*, *Give Feedback*, *Report Bugs*, *Options...* (system settings), *Close to LAN* (log out) and *Save and Quit* (power off or restart).
- **Advancement toasts**: every desktop notification shows up top right as an advancement toast, and clicking one brings the sending app to the front. Cinnamon's own notification popups are turned off for this.
- **Chat terminal**: press `Super+T` to open a chat bar at the bottom left. Type a shell command, the output appears as chat lines. `Ctrl+C` stops a command, `!cmd` opens a real terminal window, `Esc` closes.
- **Sounds**: a click on the hotbar and in the Game Menu, and a sound for each toast.


- The Cinnamon panel is auto-hidden, desktop icons are removed, and your old settings are saved so they can be restored.


---


## Assets (textures, sounds, logos)

For legal reasons, Mojang's logos, textures, sounds and music are **not included** in this repo.


**The install script offers to copy them for you** from your own Minecraft Java installation: it takes the newest version in `~/.minecraft` and the sounds the launcher already downloaded; nothing is fetched from the internet and files you added yourself are kept.


You can also run it on its own: `helper/asset_installer.sh [--minecraft-dir DIR] [--jar FILE] [--force]`.

Every asset is optional: anything missing is simply not drawn or replaced by a plain placeholder.

✅ = copied by the install script  ·  📦 = already in this repo  ·  ✋ = not in the game files, add it yourself

| File | Folder | Used for | From the game files | |
|---|---|---|---|:-:|
| **Boot & login** | | | | |
| `logo.png` | [plymouth/assets/](plymouth/assets/) | Mojang Studios logo on the boot screen | `gui/title/mojangstudios.png` (both halves joined) | ✅ |
| `logo.png` | [greeter/assets/](greeter/assets/) | "Minecraft" logo on the login screen | `gui/title/minecraft.png` | ✅ |
| `language.png` | [greeter/assets/](greeter/assets/) | icon of the keyboard-layout button | `gui/sprites/icon/language.png` | ✅ |
| `accessibility.png` | [greeter/assets/](greeter/assets/) | icon of the credits button | `gui/sprites/icon/accessibility.png` | ✅ |
| `dirt.png` | [greeter/assets/](greeter/assets/), [splash/assets/](splash/assets/) | dirt background (login, "Generating world", "Saving world") | `block/dirt.png` | ✅ |
| **Desktop textures** | | | | |
| `hotbar.png`, `hotbar_selection.png` | [desktop/assets/](desktop/assets/) | the hotbar and its selection frame | `gui/sprites/hud/` | ✅ |
| `hotbar_offhand_left.png` | [desktop/assets/](desktop/assets/) | offhand slot holding the clock | `gui/sprites/hud/` | ✅ |
| `clock_00.png` … `clock_63.png` (or one `clock.png`) | [desktop/assets/](desktop/assets/) | clock item (its dial follows the real time) | `item/clock_*.png` | ✅ |
| `heart_container.png`, `heart_full.png`, `heart_half.png` | [desktop/assets/](desktop/assets/) | hearts = battery | `gui/sprites/hud/heart/` | ✅ |
| `armor_empty.png`, `armor_half.png`, `armor_full.png` | [desktop/assets/](desktop/assets/) | armor = Wi-Fi | `gui/sprites/hud/` | ✅ |
| `food_empty.png`, `food_half.png`, `food_full.png` | [desktop/assets/](desktop/assets/) | hunger = free disk space | `gui/sprites/hud/` | ✅ |
| `xp_bg.png`, `xp_fill.png` | [desktop/assets/](desktop/assets/) | XP bar = volume | `gui/sprites/hud/experience_bar_*.png` | ✅ |
| `inventory.png`, `scroller.png` | [desktop/assets/](desktop/assets/) | inventory (app drawer) | `gui/container/creative_inventory/tab_items.png`, `.../scroller.png` | ✅ |
| `button.png`, `button_highlighted.png` | [desktop/assets/](desktop/assets/) | Game Menu buttons | `gui/sprites/widget/` | ✅ |
| `toast.png` | [desktop/assets/](desktop/assets/) | notification toasts (no texture: plain dark plate) | `gui/sprites/toast/advancement.png` | ✅ |
| **Sounds & music** | | | | |
| `click.ogg` (or `.wav` / `.mp3` / `.flac`) | [desktop/assets/](desktop/assets/) | click sound on the hotbar, inventory and menus | `sounds/random/click.ogg` | ✅ |
| `toast.ogg` (or `.wav` / `.mp3` / `.flac`) | [desktop/assets/](desktop/assets/) | sound when a notification toast slides in | `sounds/ui/toast/in.ogg` | ✅ |
| any `.ogg` / `.mp3` / `.flac` / `.wav` / `.m4a` | [greeter/assets/music/](greeter/assets/music/) | login screen music, a random track at a time | menu music: `music/menu/*.ogg` (Mutation, Moog City 2, Beginning 2, Floating Trees) | ✅ |
| **Already included** | | | | |
| `font.ttf` | [greeter/assets/](greeter/assets/) | [Monocraft](https://github.com/IdreesInc/Monocraft) font (open source), also installed for the desktop and splash | | 📦 |
| `progress-box.png`, `progress-bar.png` | [plymouth/assets/](plymouth/assets/) | boot screen loading bar | | 📦 |
| `chest.png` | [desktop/assets/](desktop/assets/) | chest slot icon (other open windows) | a rendered chest icon | 📦 |
| `world.png` (or `.jpg` / `.webp`) | [desktop/assets/](desktop/assets/) | desktop wallpaper | your own screenshot | 📦 |
| **Not in the game files** | | | | |
| `1/panorama_0.png` … `panorama_5.png` | [greeter/assets/](greeter/assets/) | rotating login background; add more sets in `2/`, `3/`… (one is picked at random) | only older versions ship them (recent ones render it live): use your own screenshots | ✋ |

Texture paths are relative to `assets/minecraft/textures/` inside the version `.jar`; sounds come from the launcher's `assets/objects`.


## Installation

```bash
sudo ./install.sh
```

To install only one module:

```bash
sudo ./install.sh --only [module]
```

The install scripts will create backup files in case you want to restore things. They will also try to install all the required dependencies.
Reboot your computer to apply changes.

## Rollback

To restore everything to default:

```bash
sudo ./install.sh --uninstall
```


## Credits to third-party tools used

* [nody-greeter](https://github.com/JezerM/nody-greeter)
* [Monocraft font](https://github.com/IdreesInc/Monocraft)


## Disclaimer

This project is not affiliated with, endorsed by, or associated with Mojang Studios or Microsoft.