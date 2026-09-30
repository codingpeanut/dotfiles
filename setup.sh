#!/usr/bin/env bash
# =============================================================================
# setup.sh: 一鍵完成 Niri + Quickshell 桌面環境安裝與 Chezmoi 同步
# =============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo " 開始建置 Niri + Quickshell 現代毛玻璃桌面"
echo " 主機目標：Dell Latitude 7420 (8GB RAM / Intel Iris Xe)"
echo "=========================================================="

chmod +x "$DOTFILES_DIR"/install/*.sh

# 執行安裝步驟
"$DOTFILES_DIR/install/01_deps.sh"
"$DOTFILES_DIR/install/02_zram.sh"
"$DOTFILES_DIR/install/03_build_quickshell.sh"
"$DOTFILES_DIR/install/04_install_niri.sh"

# 透過 Chezmoi 同步配置到使用者目錄
echo "[*] 正在透過 Chezmoi 套用設定檔至 ~/.config..."
chezmoi init --apply --source "$DOTFILES_DIR"

echo "=========================================================="
echo " 恭喜！Niri + Quickshell 環境建置完成！"
echo " 登出系統後，在登入畫面右下角齒輪選擇 'Niri' 即可進入全新桌面。"
echo " 快捷鍵提醒："
echo "   - 搜尋/啟動器：Win 鍵 或 Win + Space"
echo "   - 區域截圖：   Win + Shift + S"
echo "   - 鎖定螢幕：   Win + L"
echo "   - 終端機：     Win + Enter 或 Win + T"
echo "=========================================================="
