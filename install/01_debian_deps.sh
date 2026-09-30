#!/usr/bin/env bash
# =============================================================================
# 01_debian_deps.sh: 安裝 Debian Testing 基礎編譯庫與桌面相依套件
# =============================================================================
set -euo pipefail

echo "=========================================================="
echo " [1/4] 安裝 Debian Testing 開發工具與 Wayland 基礎依賴"
echo "=========================================================="

sudo apt update

# 1. 編譯工具鏈與 C++20/C++23
sudo apt install -y \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    git \
    curl \
    wget \
    libclang-dev

# 2. Qt 6.7+ 函式庫與 Wayland 協議開發包 (供 Quickshell 編譯)
sudo apt install -y \
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
    libpipewire-0.3-dev

# 3. 核心工具、輸入法、終端機與系統工具
sudo apt install -y \
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

echo "[-] 基礎相依套件安裝完成！"
