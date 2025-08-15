
# My EWW Rice

My EWW powered Hyprland rice.


## ✨ Features

- Bar *(\*)*
- Dock
- Dashboard
- Notification Daemon
- Widgets
- Lock screen *(\*)*
- OSD *(\*)*
- Memory and cpu efficient (around 50mb to 120mb max memory usage and max 3% of Ryzen 3200 U processor)

*(\*) Bar is written in eww. However, ditto waybar alternative is available as well!*

*(\*)* OSD is written in swayosd.

*(\*) Lock screen is currently Hyprlock and not eww.*

## 📸 Screenshots

![Screenshot](https://raw.githubusercontent.com/randomboi404/eww/refs/heads/main/.assets/ss.png)

![Screenshot](https://raw.githubusercontent.com/randomboi404/eww/refs/heads/main/.assets/ss2.png)
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

Also, create env.json in ~/.env/ and its contents must be as follows:

```bash
   {
        "WEATHER_API_KEY": "Your weather api key",
        "LOCATION": "Your city name"
   }
```
    
## ❓ FAQ

### The alignment looks wrong / broken.

Make sure you are using eww-git from AUR (for Arch linux) and NOT the eww package from repos.

### Everything is transparent, no colors.

Ensure Pywal is installed and applied to your wallpaper:
```bash
wal -i /path/to/wallpaper/
```

## 🙏 Acknowledgements

 - [ElKowar's Wacky Widgets (EWW)](https://elkowar.github.io/eww/eww.html)
 - [Various EWW posts in r/unixporn (I used snippets from MANY sources)](https://www.reddit.com/r/unixporn/)
 - [This EWW rice (For Dock)](https://github.com/Tail-R/xmonad_eww_dotfiles/tree/main)
- [End-rs (Notification Daemon for EWW)](https://github.com/Dr-42/end-rs)
- [Swayosd and other motivation](https://github.com/tr1xem)
- [Gruvbox Wallpapers](https://gruvbox-wallpapers.pages.dev/)
- [Hyprlock](https://github.com/hyprwm/hyprlock)
