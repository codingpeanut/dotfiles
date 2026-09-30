#!/usr/bin/env bash
# =============================================================================
# 04_install_niri.sh: 安裝或編譯最新 Niri Wayland 合成器
# =============================================================================
set -euo pipefail

echo "=========================================================="
echo " [4/4] 安裝 Niri 視窗合成器與 Wayland 會話桌面檔"
echo "=========================================================="

# 1. 檢查 Debian 官方倉庫是否已有 niri 套件
if apt-cache show niri >/dev/null 2>&1; then
    echo "[*] 發現 Debian 倉庫內有 niri 套件，正在安裝..."
    sudo apt install -y niri
else
    echo "[*] 透過 Rust / Cargo 安裝最新版 Niri..."
    if ! command -v cargo >/dev/null 2>&1; then
        echo "[*] 安裝 Rust 工具鏈..."
        sudo apt install -y cargo rustc
    fi
    cargo install --locked niri
    sudo cp "$HOME/.cargo/bin/niri" /usr/local/bin/niri
fi

# 2. 建立 Wayland Session Entry (/usr/share/wayland-sessions/niri.desktop)
# 確保 GDM / SDDM / greetd / LightDM 能夠在登入畫面選擇 Niri
sudo mkdir -p /usr/share/wayland-sessions
sudo tee /usr/share/wayland-sessions/niri.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Niri
Comment=Scrollable-tiling Wayland compositor
Exec=niri-session
Type=Application
DesktopNames=niri
EOF

echo "[-] Niri 及其 Wayland Session 設定完成！"
niri --version || true
