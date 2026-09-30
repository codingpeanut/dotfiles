#!/usr/bin/env bash
# =============================================================================
# 02_zram.sh: 8GB RAM 記憶體最佳化設定 (支援 Debian / Fedora)
# =============================================================================
set -euo pipefail

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID:-}"
else
    OS_ID="unknown"
fi

echo "=========================================================="
echo " [2/4] 配置 8GB RAM zram 記憶體即時壓縮"
echo "=========================================================="

if [[ "$OS_ID" == "fedora" ]]; then
    # Fedora 預設已內建並啟用 zram-generator
    echo "[*] 檢測到 Fedora 系統，檢查內建 zram 狀態..."
    if ! command -v zramctl >/dev/null 2>&1; then
        sudo dnf install -y zram-generator util-linux
    fi
else
    # Debian 系統
    sudo apt install -y zram-tools
    sudo tee /etc/default/zramswap > /dev/null << 'EOF'
ALGO=zstd
PERCENT=100
PRIORITY=100
EOF
    sudo systemctl restart zramswap.service
    sudo systemctl enable zramswap.service
fi

echo "[-] zram 設定完成！目前狀態："
zramctl || true
swapon --show || true
