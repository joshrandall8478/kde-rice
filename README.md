# Pursuit KDE Rice
README.md edited: 07/25/22 19:15
[Link to Video](https://www.youtube.com/watch?v=7tWTagDykiI)

# Information
- Operating System: [Arch Linux](https://archlinux.org/)
- Terminal: [Kitty](https://sw.kovidgoyal.net/kitty/) and yakuake
- Dock and Panel UI: [Latte-Dock](https://store.kde.org/p/1169519/) (*Layout files provided in repository*)
- Background: Provided in repository

![KDE Rice](https://i.imgur.com/DvBh0ZQ.png)

# Installation
Most of what is mentioned here can be installed via the KDE store `discover`. To download the repository, perform the following command and import the `latte-dock` files into the applicaton.

```
git clone https://github.com/joshrandall8478/kde-rice
```

Also to add the icon for the application launcher on the top panels, make sure to do this after cloning:
```
cd kde-rice/home 
cp .arch-application-launcher.png ~
```

# Theming
*The following should be easily accessible through the KDE store*
- Original global theme - Monochrome
- Plasma theme - Layan
- GTK Theme - Breeze
- Color Theme - Layan
- Icon Theme - Telu Dark
- Cursor - Breeze Dark
- Terminal (use `kitty +kitten themes`) - idletoes

# Widgets used
## On desktop
- Minimalist Clock
- NowPlayingRe
## On Panels and Taskbars
### Main Dock
- Applicaton Launcher 
- Latte Tasks
- Recycle Bin
- Show Desktop
### Main Panel
- Application Launcher
- Window Title
- Global Menu
- System Tray
- Better Inline Clock
- Window Buttons
### Secondary Panel(s)
- Application Launcher
- Window Title
- Global Menu
- Better Inline Clock
- Window Buttons


# Wallpaper Engine
KDE Plasma has gained support for wallpaper engine through a plugin installable through the KDE store or github, which can be [installed and compiled from source here](https://github.com/catsout/wallpaper-engine-kde-plugin).

That same source supplies information on correctly installing and utilizing the plugin for KDE. I reccomend reading the [README](https://github.com/catsout/wallpaper-engine-kde-plugin/blob/main/README.md) from that repository whether you install from source or from the KDE store.

It may be better to install the plugin from the github repository, as it ensures that the plugin stays up to date. The KDE store version was out of date for a while. However as of the making of this repository, it is close/mirrored in version with the github version.

If you install from KDE store, I do still reccomend reading the [README](https://github.com/catsout/wallpaper-engine-kde-plugin/blob/main/README.md) (*skip to the* ***[Usage](https://github.com/catsout/wallpaper-engine-kde-plugin/blob/main/README.md#usage)*** *section*).

[Background used with Wallpaper engine](https://steamcommunity.com/sharedfiles/filedetails/?id=2813843465) in [this video](https://www.youtube.com/watch?v=W1qb7m-xs50).
