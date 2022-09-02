<!--
SPDX-FileCopyrightText: 2022 Alexander Kromm <mmaulwurff@gmail.com>
SPDX-License-Identifier: CC0-1.0
-->

# Mod Menu

![screenshot](screenshots/screenshot.png)

This GZDoom add-on puts every mod options menu into the special Mod Menu instead
of cluttering Options Menu.

## Features

- Moves all extra submenus from Options Menu to Mod Menu.
- Adds Mod Menu to simplified Options Menu.
- Has a chance to put Zandronum-style keybind-only-accessible menus to Mod Menu.
- A key to open Mod Menu.
- Removes redundant words like "options" and "settings".
- Extensible: undetected menus can be added in `more-menus.json`.

## Limitations

- mod menu detection expects that the first two MENUDEF lumps in the engine
  package are lumps for the full and the simple option menus.
- Zandronum-style menus are detected by scanning Controls menu for anything
  with a command containing "open" and "menu".

## Mods From the Screenshot

[Autoautosave](https://forum.zdoom.org/viewtopic.php?t=59889),
[Corruption Cards](https://forum.zdoom.org/viewtopic.php?f=43&t=67939),
[Floor Mod](https://forum.zdoom.org/viewtopic.php?t=76193),
[Gearbox](https://forum.zdoom.org/viewtopic.php?f=43&t=71086),
[Immerse](https://forum.zdoom.org/viewtopic.php?f=43&t=61915),
[Laser Sight](https://forum.zdoom.org/viewtopic.php?f=43&t=61079),
[Champions](https://forum.zdoom.org/viewtopic.php?t=60456),
[Rampancy](https://forum.zdoom.org/viewtopic.php?f=43&t=67193),
[Target Spy](https://forum.zdoom.org/viewtopic.php?f=43&t=60784),
[Universal Entropy](https://forum.zdoom.org/viewtopic.php?t=66778),
[Universal Rain and Snow](https://forum.zdoom.org/viewtopic.php?t=70432),
[Universal Weapon Sway](https://forum.zdoom.org/viewtopic.php?t=68255),
[Gun Bonsai](https://forum.zdoom.org/viewtopic.php?f=43&t=76080),
[MariFX Shader Suite](https://forum.zdoom.org/viewtopic.php?t=63394),
[War Trophies](https://forum.zdoom.org/viewtopic.php?t=67054),
[Final Doomer +](https://forum.zdoom.org/viewtopic.php?f=43&t=55061).

## Acknowledgments

- Bug reports: mamaluigisbagel, cosmos10040.
- Brazilian Portuguese translation: generic name guy.
