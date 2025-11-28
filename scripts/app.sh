#!/usr/bin/env bash
set -e

echo "[*] Installing applications..."

# Make sure dnf plugins are installed
sudo dnf install -y dnf-plugins-core

# Add Flathub as a Flatpak remote
flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo

# Discord (Flatpak)
if ! flatpak list | grep -qi discord; then
    echo "[*] Installing Discord..."
    flatpak install --user -y flathub com.discordapp.Discord
fi

# Google Chrome
if ! command -v google-chrome >/dev/null 2>&1; then
    echo "[*] Installing Google Chrome..."
    echo "[google-chrome]
name=Google Chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub" | sudo tee /etc/yum.repos.d/google-chrome.repo
    sudo dnf install -y google-chrome-stable
fi

# VSCode
if ! command -v code >/dev/null 2>&1; then
    echo "[*] Installing VSCode..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf install -y code
fi

# CopyQ
if ! command -v copyq >/dev/null 2>&1; then
    echo "[*] Installing CopyQ..."
    sudo dnf install -y copyq
fi

echo "[✓] Application installation completed!"
