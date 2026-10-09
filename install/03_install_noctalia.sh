#!/usr/bin/env bash
# =============================================================================
# 03_install_noctalia.sh: 安裝或編譯最新 Noctalia (Wayland Desktop Shell)
# =============================================================================
set -euo pipefail

echo "=========================================================="
echo " [3/4] 檢查 / 安裝 Noctalia (現代 Wayland Desktop Shell)"
echo "=========================================================="

# 1. 檢查系統是否已安裝 noctalia
if command -v noctalia >/dev/null 2>&1; then
    echo "[-] 系統已成功安裝 Noctalia，跳過安裝！"
    noctalia --version 2>/dev/null || echo "Noctalia binary found at $(which noctalia)"
    exit 0
fi

# 2. 判斷系統發行版嘗試透過套件庫安裝
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID:-}"
else
    OS_ID="unknown"
fi

if [[ "$OS_ID" == "fedora" ]]; then
    echo "[*] 嘗試透過 Fedora 套件庫或 COPR 安裝 noctalia..."
    if sudo dnf install -y noctalia 2>/dev/null; then
        echo "[-] 成功透過 DNF 安裝 Noctalia！"
        exit 0
    fi
fi

# 3. 若套件庫尚未收錄，自原始碼透過 Meson 與 Ninja 編譯安裝
echo "[*] 套件庫未收錄預編譯套件，正在自原始碼編譯安裝 Noctalia..."
BUILD_DIR="/tmp/noctalia_build"
rm -rf "$BUILD_DIR"

echo "[*] 複製 Noctalia 原始碼倉庫..."
git clone --recursive https://github.com/noctalia-dev/noctalia.git "$BUILD_DIR"
cd "$BUILD_DIR"

echo "[*] 正在透過 Meson 配置專案..."
meson setup build --buildtype=release -Dprefix=/usr/local

echo "[*] 正在透過 Ninja 編譯..."
ninja -C build

echo "[*] 安裝 Noctalia 至 /usr/local/bin..."
sudo ninja -C build install

echo "[-] Noctalia 安裝成功！"
noctalia --version 2>/dev/null || echo "Noctalia binary ready at $(which noctalia)"

# 清理暫存檔
rm -rf "$BUILD_DIR"
