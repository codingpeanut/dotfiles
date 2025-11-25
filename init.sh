#!/usr/bin/env bash
chmod +x scripts/dconf.sh scripts/extension.sh scripts/app.sh 
./scripts/dconf.sh
./scripts/extension.sh
./scripts/app.sh

# --- Update GRUB kernel parameters ---
GRUB_FILE="/etc/default/grub"
PARAM="rhgb quiet plymouth.ignore-udev"

echo "[*] Updating GRUB kernel parameters..."

# Update GRUB_CMDLINE_LINUX safely
sudo sed -i "s/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"${PARAM}\"/" "$GRUB_FILE"

# Apply grub settings
if command -v grub2-mkconfig >/dev/null 2>&1; then
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
elif command -v grub-mkconfig >/dev/null 2>&1; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

