#!/usr/bin/env bash
# =============================================================================
# 03_install_dms.sh: 安裝 DankMaterialShell (DMS) 控制工具與 dgop
# =============================================================================
set -euo pipefail

echo "=========================================================="
echo " [3/4] 下載並安裝 DankMaterialShell 工具 (dms, dgop)"
echo "=========================================================="

# 確保 ~/.local/bin 存在
mkdir -p ~/.local/bin

DMS_VER="v1.6.2"

echo "[*] 正在從 GitHub 下載 dms-cli ($DMS_VER)..."
curl -L -o /tmp/dms-cli-amd64.gz "https://github.com/AvengeMedia/DankMaterialShell/releases/download/${DMS_VER}/dms-cli-amd64.gz"
gunzip -f /tmp/dms-cli-amd64.gz
mv /tmp/dms-cli-amd64 ~/.local/bin/dms
chmod +x ~/.local/bin/dms

echo "[*] 正在從 GitHub 下載 dgop ($DMS_VER)..."
curl -L -o /tmp/dgop-linux-amd64.gz "https://github.com/AvengeMedia/dgop/releases/download/${DMS_VER}/dgop-linux-amd64.gz"
gunzip -f /tmp/dgop-linux-amd64.gz
mv /tmp/dgop-linux-amd64 ~/.local/bin/dgop
chmod +x ~/.local/bin/dgop

echo "[-] DMS 工具安裝成功！"
~/.local/bin/dms --version || true
