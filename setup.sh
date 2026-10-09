#!/usr/bin/env bash
# =============================================================================
# setup.sh: 一鍵完成 Niri + Noctalia 桌面環境安裝與 Chezmoi 同步
# =============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo " 開始建置 Niri + Noctalia 現代微透毛玻璃桌面"
echo " 主機目標：Dell Latitude 7420 (8GB RAM / Intel Iris Xe)"
echo "=========================================================="

chmod +x "$DOTFILES_DIR"/install/*.sh

# 執行安裝步驟
"$DOTFILES_DIR/install/01_deps.sh"
"$DOTFILES_DIR/install/02_zram.sh"
"$DOTFILES_DIR/install/03_install_noctalia.sh"
"$DOTFILES_DIR/install/04_install_niri.sh"
if [ -f "$DOTFILES_DIR/install/05_install_keyd.sh" ]; then
    "$DOTFILES_DIR/install/05_install_keyd.sh"
fi

# 透過 Chezmoi 同步配置到使用者目錄
echo "[*] 正在透過 Chezmoi 套用設定檔至 ~/.config..."
chezmoi init --apply --source "$DOTFILES_DIR"

echo "=========================================================="
echo " 恭喜！Niri + Noctalia 環境建置完成！"
echo " 登出系統後，在登入畫面右下角齒輪選擇 'Niri' 即可進入全新桌面。"
echo " 快捷鍵提醒："
echo "   - 搜尋/啟動器：Win 鍵 或 Win + Space (Noctalia Spotlight)"
echo "   - 控制中心：   Win + A (整合電源模式、防睡眠、音量、亮度)"
echo "   - 剪貼簿歷史： Win + V (Noctalia 浮動剪貼簿)"
echo "   - 區域截圖：   Win + Shift + S"
echo "   - 鎖定螢幕：   Win + L"
echo "   - 終端機：     Win + Enter 或 Win + T"
echo "=========================================================="
