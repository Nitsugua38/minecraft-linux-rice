# Minecraft Linux Rice

**Turn Linux Mint (Cinnamon, X11) into a Minecraft-style desktop:** 

| Module | script |
|---|---|
| Minecraft Boot logo | plymouth |
| Minecraft title-screen login | greeter |
| Minecraft Generating World loading screen | splash |
| Minecraft HUD taskbar + app drawer | desktop |


## Add your own logos!

For legal reasons, copyrighted logos and artworks are NOT included, you need to add them yourself.

- "Mojang Studios" logo inside [plymouth/assets/logo.png](plymouth/assets/logo.png)
- "Minecraft" logo inside [greeter/assets/logo.png](greeter/assets/logo.png)
- 6 "panorama" images inside [greeter/assets/1/](greeter/assets/1/) - You can use your own screenshots or download them from https://mcasset.cloud/1.20/assets/minecraft/textures/gui/title/background - You can add multiple sets of images in different folders (naming them "2", "3", etc., one will be randomly picked each time).
- The following icons extracted from Minecraft inside [desktop/assets/icons/](desktop/assets/): `armor_empty.png`, `armor_full.png`, `armor_half.png`, `chest.png`, `food_empty.png`, `food_full.png`, `heart_container.png`, `heart_full.png`, `heart_half.png`, `hotbar_selection.png`, `hotbar.png`, `world.png`, `xp_bg.png`, `xp_fill.png`, `inventory.png`, `scroller.png`, `button.png`, `button_highlighted.png`


## Installation

```bash
sudo ./install.sh
```

To install only one module:

```bash
sudo ./install.sh --only [module]
```

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