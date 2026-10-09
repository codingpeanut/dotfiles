#!/usr/bin/env bash
# =============================================================================
# 01_deps.sh: 安裝系統基礎編譯庫與桌面相依套件 (支援 Debian / Fedora)
# =============================================================================
set -euo pipefail

# 判斷發行版
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID:-}"
else
    OS_ID="unknown"
fi

echo "=========================================================="
echo " [1/4] 安裝開發工具與 Wayland 基礎依賴 (系統: ${OS_ID})"
echo "=========================================================="

if [[ "$OS_ID" == "fedora" ]]; then
    # 啟用 Hyprland 生態 (hyprlock, hypridle) 與 Noctalia 軟體庫
    echo "[*] 正在啟用 Fedora COPR 專用軟體庫..."
    sudo dnf copr enable -y solopasha/hyprland || true
    sudo dnf copr enable -y zhangyi6324/noctalia-shell || true

    sudo dnf install -y --skip-unavailable \
        gcc \
        gcc-c++ \
        meson \
        ninja-build \
        cmake \
        git \
        curl \
        wget \
        pkgconf-pkg-config \
        wayland-devel \
        wayland-protocols-devel \
        libxkbcommon-devel \
        pam-devel \
        mesa-libgbm-devel \
        libinput-devel \
        libseat-devel \
        pipewire-devel \
        wireplumber-devel \
        sdbus-cpp-devel \
        tomlplusplus-devel \
        libsecret-devel \
        libsodium-devel \
        kitty \
        fcitx5 \
        fcitx5-chewing \
        fcitx5-autostart \
        pipewire \
        wireplumber \
        brightnessctl \
        grim \
        slurp \
        wl-clipboard \
        cliphist \
        nautilus \
        btop \
        fuzzel \
        swaybg \
        wlsunset \
        hyprlock \
        hypridle \
        keyd \
        network-manager-applet \
        blueman \
        pavucontrol \
        google-noto-sans-cjk-vf-fonts \
        google-noto-cjk-fonts \
        jetbrains-mono-fonts \
        chezmoi
else
    # 預設為 Debian / Ubuntu 體系
    sudo apt update
    sudo apt install -y \
        build-essential \
        meson \
        ninja-build \
        cmake \
        pkg-config \
        git \
        curl \
        wget \
        libwayland-dev \
        wayland-protocols \
        libxkbcommon-dev \
        libpam0g-dev \
        libgbm-dev \
        libinput-dev \
        libseat-dev \
        libpipewire-0.3-dev \
        libwireplumber-0.5-dev \
        libsdbus-c++-dev \
        libtomlplusplus-dev \
        libsecret-1-dev \
        libsodium-dev \
        kitty \
        fcitx5 \
        fcitx5-chewing \
        pipewire \
        wireplumber \
        pipewire-audio \
        brightnessctl \
        grim \
        slurp \
        wl-clipboard \
        cliphist \
        nautilus \
        btop \
        fuzzel \
        network-manager-gnome \
        blueman \
        pavucontrol \
        swaybg \
        wlsunset \
        hyprlock \
        hypridle \
        fonts-noto-cjk \
        fonts-jetbrains-mono \
        chezmoi
fi

echo "[-] 基礎相依套件安裝完成！"
