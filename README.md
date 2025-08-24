
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
## 📦 Installation and Usage

Install the dependencies via any of the AUR helper (Paru example below):

```bash
  git clone https://github.com/randomboi404/eww --depth 1
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

Generate colors based on your wallpaper as shown below:

```bash
   wal -i /path/to/wallpaper
   matugen image /path/to/wallpaper
```

Open eww.scss file and replace the hardcoded @import as per your username.

Run `eww daemon` to load the daemon and then run the following to open the bar and widgets:

```bash
   eww open eww-bar
   eww open bg-panel
   eww open activate-linux
```

Some Hyprland keybinds worth looking:

```
   bind = $mainMod, T, exec, eww update barrev=$( [ "$(eww get barrev)" = "true" ] && echo false || echo true ) && clear
   bind = $mainMod Shift, R, exec, eww update y=$( [ "$(eww get y)" = "true" ] && echo false || echo true ) && eww update x=$( [ "$(eww get x)" = "true" ] && echo false || echo true )
   bind = $mainMod Shift, W, exec, $HOME/.config/hypr/scripts/dock.sh
```

where, dock.sh is as follows:
```bash
    #!/usr/bin/bash
    pkill -9 -f "$HOME/.config/eww/dock/scripts/toggle-dock.sh" || true
    "$HOME/.config/eww/dock/scripts/toggle-dock.sh"
```
    
## ❓ FAQ

### The alignment looks wrong / broken.

Make sure you are using eww-git from AUR (for Arch linux) and NOT the eww package from repos.

### There are no notifications.
Make sure that the end-rs bin is running in background. It is available either in .config/eww/bin OR see the instructions of the [official repo](https://github.com/Dr-42/end-rs). Also make sure that you have copied end-rs folder to .config/ as well.

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
