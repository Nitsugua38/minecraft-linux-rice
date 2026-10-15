# Minecraft Linux Rice

**Turn Linux Mint (Cinnamon, X11) into a Minecraft-style desktop:** 

| Module | script |
|---|---|
| Minecraft Boot logo | plymouth |
| Minecraft title-screen login | greeter |
| Minecraft Generating World loading screen | splash |
| Minecraft hotbar taskbar | TODO |
| Minecraft inventory app launcher | TODO |


## Add your own logos!

For legal reasons, copyrighted logos and artworks are NOT included, you need to add them yourself.

- "Mojang Studios" logo inside [plymouth/assets/logo.png](plymouth/assets/logo.png)
- "Minecraft" logo inside [greeter/assets/logo.png](greeter/assets/logo.png)
- 6 "panorama" images inside [greeter/assets/1/](greeter/assets/1/) - You can use your own screenshots or download them from https://mcasset.cloud/1.20/assets/minecraft/textures/gui/title/background - You can add multiple sets of images in different folders (naming them "2", "3", etc., one will be randomly picked each time).


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