#!/bin/bash
set -e

echo "=== 安裝與設定 keyd (單擊 Win 鍵功能) ==="

# 檢查是否為 root
if [ "$EUID" -ne 0 ]; then
  echo "請使用 sudo 執行此腳本: sudo bash $0"
  exit 1
fi

# 1. 安裝必要編譯依賴 (針對 Fedora)
echo "[1/4] 安裝編譯依賴..."
dnf install -y make gcc git systemd-devel

# 2. 下載並編譯 keyd
echo "[2/4] 下載並編譯 keyd..."
cd /tmp
if [ -d "keyd" ]; then
    rm -rf keyd
fi
git clone https://github.com/rvaiya/keyd
cd keyd
make
make install

# 3. 寫入設定檔
echo "[3/4] 寫入 keyd 設定檔..."
mkdir -p /etc/keyd
cat << 'EOF' > /etc/keyd/default.conf
[ids]

*

[main]

# overload(長按發送的按鍵, 單點發送的巨集或按鍵)
# 這裡設定長按 Win 鍵為原本的 meta 修飾鍵，單點放開時則發送 M-space (Win+Space) 來喚出 Quickshell。
leftmeta = overload(meta, macro(M-space))
EOF

# 4. 重新載入並啟動服務
echo "[4/4] 重新載入設定與啟動 keyd 服務..."
systemctl daemon-reload
systemctl enable keyd
systemctl restart keyd

echo "=== 安裝完成！ ==="
echo "現在您可以單擊 Win 鍵來喚出 Niri 預設啟動器 (Win+D) 了！"
