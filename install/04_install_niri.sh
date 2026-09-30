#!/usr/bin/env bash
# =============================================================================
# 04_install_niri.sh: 安裝 Niri 視窗合成器 (支援 Debian / Fedora)
# =============================================================================
set -euo pipefail

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID:-}"
else
    OS_ID="unknown"
fi

echo "=========================================================="
echo " [4/4] 安裝 Niri 視窗合成器與 Wayland 會話桌面檔"
echo "=========================================================="

if [[ "$OS_ID" == "fedora" ]]; then
    echo "[*] 正在透過 Fedora COPR 倉庫安裝官方最新版 Niri..."
    sudo dnf copr enable -y yalter/niri || true
    sudo dnf install -y niri
else
    # Debian 體系
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
fi

# 確保 Wayland Session Entry 存在
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
