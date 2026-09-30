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
    sudo dnf install -y \
        gcc \
        gcc-c++ \
        cmake \
        ninja-build \
        git \
        curl \
        wget \
        pkgconf-pkg-config \
        clang-devel \
        qt6-qtbase-devel \
        qt6-qtdeclarative-devel \
        qt6-qtwayland-devel \
        qt6-qtsvg-devel \
        wayland-devel \
        wayland-protocols-devel \
        libxkbcommon-devel \
        pam-devel \
        mesa-libgbm-devel \
        libinput-devel \
        libseat-devel \
        pipewire-devel \
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
        google-noto-cjk-fonts \
        jetbrains-mono-fonts \
        chezmoi
else
    # 預設為 Debian / Ubuntu 體系
    sudo apt update
    sudo apt install -y \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        git \
        curl \
        wget \
        libclang-dev \
        qt6-base-dev \
        qt6-declarative-dev \
        qt6-wayland-dev \
        libqt6svg6-dev \
        libwayland-dev \
        wayland-protocols \
        libxkbcommon-dev \
        libpam0g-dev \
        libgbm-dev \
        libinput-dev \
        libseat-dev \
        libpipewire-0.3-dev \
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
        swaybg \
        wlsunset \
        hyprlock \
        hypridle \
        fonts-noto-cjk \
        fonts-jetbrains-mono \
        chezmoi
fi

echo "[-] 基礎相依套件安裝完成！"
