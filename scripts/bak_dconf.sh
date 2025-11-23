#!/usr/bin/env bash
set -e

### === 1. 備份 GNOME ===
mkdir -p gnome
dconf dump /org/gnome/desktop/wm/keybindings/ > gnome/keybindings.dconf
dconf dump /org/gnome/shell/ > gnome/shell.dconf
dconf dump /org/gnome/mutter/ > gnome/mutter.dconf
dconf dump /org/gnome/shell/extensions/ > gnome/extensions.dconf
dconf dump /org/gnome/desktop/interface/ > gnome/interface.dconf
dconf dump /org/gnome/desktop/input-sources/ > gnome/input.dconf

### === 2. 備份 ibus ===
mkdir -p ibus
dconf dump /desktop/ibus/ > ibus/ibus.dconf
