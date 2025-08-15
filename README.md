
# My EWW Rice

My EWW powered Hyprland rice.


## ✨ Features

- Bar
- Dock
- Dashboard
- Notification Daemon
- Widgets
- Lock screen *(\*)*
- Memory and cpu efficient (around 50mb to 120mb max memory usage and max 3% of Ryzen 3200 U processor)
*(\*) Lock screen is currently Hyprlock and not eww.*

## 📸 Screenshots

![Screenshot](https://raw.githubusercontent.com/randomboi404/eww/refs/heads/main/.assets/ss.png)

![creenshot](https://raw.githubusercontent.com/randomboi404/eww/refs/heads/main/.assets/ss2.png)
![Screenshot](https://raw.githubusercontent.com/randomboi404/eww/refs/heads/main/.assets/ss3.png)
![Screenshot](https://raw.githubusercontent.com/randomboi404/eww/refs/heads/main/.assets/ss1.png)
## 📦 Installation

Install the dependencies via any of the AUR helper (Paru example below):

```bash
  git clone https://github.com/randomboi404/eww
  cd eww
  paru -Syu --needed $(cat dependencies.lst)
```
After then, copy and paste the relevant folders to .config/
    
## FAQ

### The alignment is weird and does not look as intended. What to do?

Make sure you are using eww-git from AUR (for Arch linux) and NOT the eww package from repos.

### There are no colors, it's all transparent!

Make sure you have installed pywal and have successfully used it for any of your wallpapers.
```bash
wal -i /path/to/wallpaper/
```

## Acknowledgements

 - [ElKowar's Wacky Widgets (EWW)](https://elkowar.github.io/eww/eww.html)
 - [Various EWW posts in r/unixporn (I used snippets from MANY sources)](https://www.reddit.com/r/unixporn/)
 - [This EWW rice (For Dock)](https://github.com/Tail-R/xmonad_eww_dotfiles/tree/main)
- [End-rs (Notification Daemon for EWW)](https://github.com/Dr-42/end-rs)
- [Hyprlock](https://github.com/hyprwm/hyprlock)
- [Gruvbox Wallpapers](https://gruvbox-wallpapers.pages.dev/)
