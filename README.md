# Minecraft Linux Rice

**Turn Linux Mint (Cinnamon, X11) into a Minecraft-style desktop:** 

| Module | script |
|---|---|
| Minecraft Boot logo | plymouth |
| Minecraft title-screen login | TODO |
| Minecraft Generating World loading screen | TODO |
| Minecraft hotbar taskbar | TODO |
| Minecraft inventory app launcher | TODO |

## Installation

1) Clone the repo 
2) Add **YOUR OWN** "Minecraft" logo inside [plymouth/assets/logo.png](plymouth/assets/logo.png) (for legal reasons it is not uploaded to this repo).
3) Run the installer:

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