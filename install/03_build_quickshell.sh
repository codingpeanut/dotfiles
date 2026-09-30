#!/usr/bin/env bash
# =============================================================================
# 03_build_quickshell.sh: 由原始碼編譯並安裝最新 Quickshell
# =============================================================================
set -euo pipefail

echo "=========================================================="
echo " [3/4] 編譯並安裝 Quickshell (QtQuick / QML Desktop Shell)"
echo "=========================================================="

BUILD_DIR="/tmp/quickshell_build"
rm -rf "$BUILD_DIR"

echo "[*] 複製 Quickshell 原始碼倉庫..."
git clone --recursive https://github.com/outfoxxed/quickshell.git "$BUILD_DIR"
cd "$BUILD_DIR"

echo "[*] 正在透過 CMake 與 Ninja 進行編譯..."
cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local

ninja -C build

echo "[*] 安裝 Quickshell 到 /usr/local/bin..."
sudo ninja -C build install

echo "[-] Quickshell 安裝成功！版本資訊："
quickshell --version || true

# 清理編譯暫存
rm -rf "$BUILD_DIR"
