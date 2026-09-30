#!/usr/bin/env bash
# =============================================================================
# 02_zram.sh: 8GB RAM 記憶體最佳化設定 (zram-tools + zstd 演算法)
# =============================================================================
set -euo pipefail

echo "=========================================================="
echo " [2/4] 配置 8GB RAM zram 記憶體即時壓縮"
echo "=========================================================="

sudo apt install -y zram-tools

# 設定 zramswap 參數：使用高壓縮率且極速的 zstd
sudo tee /etc/default/zramswap > /dev/null << 'EOF'
# zramswap configuration for 8GB RAM workstation
ALGO=zstd
PERCENT=100
PRIORITY=100
EOF

# 重新載入並啟動服務
sudo systemctl restart zramswap.service
sudo systemctl enable zramswap.service

echo "[-] zram 設定完成！目前 Swap 狀態如下："
zramctl || true
swapon --show || true
