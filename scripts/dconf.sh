#!/usr/bin/env bash
set -e

# 搜尋 gnome 與 ibus 資料夾
GNOME_DIR=$(find . -maxdepth 1 -type d -name "gnome" | head -n 1)
IBUS_DIR=$(find . -maxdepth 1 -type d -name "ibus" | head -n 1)

if [ -z "$GNOME_DIR" ]; then
    echo "[!] Backup directory 'gnome' not found!"
    exit 1
fi

if [ -z "$IBUS_DIR" ]; then
    echo "[!] Backup directory 'ibus' not found!"
fi

# 還原 GNOME dconf
for file in keybindings shell mutter extensions interface input pop-shell; do
    FILE_PATH="$GNOME_DIR/$file.dconf"
    if [ -f "$FILE_PATH" ]; then
        echo "[*] Restoring $file..."
        case $file in
            keybindings) dconf load /org/gnome/desktop/wm/keybindings/ < "$FILE_PATH" ;;
            shell)       dconf load /org/gnome/shell/ < "$FILE_PATH" ;;
            mutter)      dconf load /org/gnome/mutter/ < "$FILE_PATH" ;;
            extensions)  dconf load /org/gnome/shell/extensions/ < "$FILE_PATH" ;;
            interface)   dconf load /org/gnome/desktop/interface/ < "$FILE_PATH" ;;
            input)       dconf load /org/gnome/desktop/input-sources/ < "$FILE_PATH" ;;
            pop-shell)   dconf load /org/gnome/shell/extensions/pop-shell/ < "$FILE_PATH" ;;
        esac
        echo "[✓] Restored $file"
    fi
done

# 還原 IBus dconf
if [ -n "$IBUS_DIR" ]; then
    for file in "$IBUS_DIR"/*.dconf; do
        [ -f "$file" ] || continue
        BASENAME=$(basename "$file" .dconf)
        echo "[*] Restoring IBus: $BASENAME..."
        dconf load /desktop/ibus/ < "$file"
        echo "[✓] Restored $BASENAME"
    done
fi

echo "[✓] GNOME + IBus settings restore completed!"
echo "Please log out or restart GNOME Shell for changes to take effect."

