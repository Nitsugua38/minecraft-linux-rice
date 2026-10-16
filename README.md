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
- **HUD indicators** above the hotbar: hearts = battery (they hop while charging), armor = Wi-Fi strength, XP bar = volume (click or drag it, the wheel works too), XP number = the clock (click for a calendar), hunger = pending updates (full when up to date, half when updates are waiting). Each one opens the matching system settings when clicked.
- **Chest slot**: hover it to see every open window that is not pinned, click one to bring it to the front.
- **Inventory**: press `Super` alone to open every installed app in the creative-inventory layout. Type to search, `Enter` launches the first result, drag an app onto a hotbar slot to pin it, drag it out of the bar to unpin it.
- **Game Menu**: press `Esc` twice inside the inventory. *Back to Game*, *Lock*, *Sleep*, *Give Feedback*, *Report Bugs*, *Options...* (system settings), *Close to LAN* (log out) and *Save and Quit* (power off or restart).
- **Advancement toasts**: every desktop notification shows up top right as an advancement toast, and clicking one brings the sending app to the front. Cinnamon's own notification popups are turned off for this.
- **Chat terminal**: press `Super+T` to open a chat bar at the bottom left. Type a shell command, the output appears as chat lines. `Ctrl+C` stops a command, `!cmd` opens a real terminal window, `Esc` closes.
- **Sounds**: a click on the hotbar and in the Game Menu, and a sound for each toast.


- The Cinnamon panel is auto-hidden, desktop icons are removed, and your old settings are saved so they can be restored.


---


## Add your own logos!

For legal reasons, copyrighted logos, artworks, textures and music are NOT included, you need to add them yourself.

- "Mojang Studios" logo inside [plymouth/assets/logo.png](plymouth/assets/logo.png)
- "Minecraft" logo inside [greeter/assets/logo.png](greeter/assets/logo.png)
- 6 "panorama" images inside [greeter/assets/1/](greeter/assets/1/) - You can use your own screenshots or download them from https://mcasset.cloud/1.20/assets/minecraft/textures/gui/title/background - You can add multiple sets of images in different folders (naming them "2", "3", etc., one will be randomly picked each time).
- The following icons extracted from Minecraft inside [desktop/assets/](desktop/assets/): `armor_empty.png`, `armor_full.png`, `armor_half.png`, `chest.png`, `food_empty.png`, `food_full.png`, `heart_container.png`, `heart_full.png`, `heart_half.png`, `hotbar_selection.png`, `hotbar.png`, `world.png`, `xp_bg.png`, `xp_fill.png`, `inventory.png`, `scroller.png`, `button.png`, `button_highlighted.png`, `click.ogg`, `toast.png`, `toast.ogg`
- Startup music inside [greeter/assets/music/](greeter/assets/music/)

Any missing desktop texture is simply not drawn, or replaced by a plain placeholder.


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