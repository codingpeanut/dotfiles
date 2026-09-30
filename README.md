# Niri + Quickshell 現代微透桌面 (Debian Testing)

專為 **Dell Latitude 7420 (Intel Iris Xe / 8GB RAM)** 主力開發機打造的高顏值、物理彈簧動態 Wayland 桌面環境。
結合 **Niri** 的無限橫向視窗流動與 **Quickshell** 流暢的微透毛玻璃 (Glassmorphism) 介面，並完整支援 **Windows 肌肉記憶快捷鍵**。

---

## 🎨 視覺與架構亮點

- **微透毛玻璃 (Glassmorphism)**：全系統採用 12-16px 圓角、背景高斯模糊 (Blur 20px) 與柔和邊框微發光。
- **Catppuccin 日夜雙模無縫切換**：
  - **深色**：Catppuccin Mocha (冷灰紫底色 + 薰衣草紫/冰河藍強調色)。
  - **淺色**：Catppuccin Latte (柔白極簡風格)。
  - 支援在控制中心一鍵無縫過渡。
- **全功能一體化 Quickshell**：
  - 頂部懸浮島狀態列 (Floating Island Bar)
  - 抽屜式控制中心 (Control Center: Wi-Fi, 藍牙, 日夜切換, 護眼模式, 音量與螢幕亮度滑桿)
  - Spotlight 居中應用程式搜尋啟動器 (<kbd>Win</kbd> 鍵喚出)
  - 浮動音量與亮度 OSD
  - 毛玻璃桌面通知彈窗
- **8GB RAM 深度最佳化**：
  - 自動啟用 `zram-tools` + `zstd` 即時記憶體壓縮演算法，提供相當於 14-16GB 的流暢多工體驗，杜絕硬碟 Swap 掉幀。
- **觸控板 1:1 物理手勢**：
  - Dell 筆電精密觸控板支援三指橫向滑動，視窗欄位 1:1 隨手指平滑流動。
- **專業 Dotfiles 管理**：
  - 採用 **Chezmoi** 進行範本化與版本控管，跨機器一鍵同步。

---

## ⌨️ Windows 肌肉記憶快捷鍵矩陣

| 快捷鍵 | 功能說明 | 備註 |
| :--- | :--- | :--- |
| <kbd>Win</kbd> 或 <kbd>Win</kbd> + <kbd>Space</kbd> | 開啟 / 關閉 居中搜尋啟動器 | Spotlight 式毛玻璃搜尋列 |
| <kbd>Win</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | 區域截圖 (Windows 剪取工具) | 自動複製到剪貼簿並彈出通知 |
| <kbd>Win</kbd> + <kbd>L</kbd> | 鎖定電腦螢幕 | 呼叫 PAM 級 Hyprlock |
| <kbd>Win</kbd> + <kbd>E</kbd> | 開啟檔案管理員 (Nautilus) | GNOME Files |
| <kbd>Win</kbd> + <kbd>V</kbd> | 剪貼簿歷史選單 | Cliphist + Fuzzel 快速選取 |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Esc</kbd> | 開啟工作管理員 (btop) | 隨時監控 8GB RAM 負載 |
| <kbd>Alt</kbd> + <kbd>Tab</kbd> | 視窗循環切換 | 焦點輪換 |
| <kbd>Alt</kbd> + <kbd>F4</kbd> 或 <kbd>Win</kbd> + <kbd>Q</kbd> | 關閉當前視窗 | 關閉視窗 |
| <kbd>Win</kbd> + <kbd>Enter</kbd> 或 <kbd>Win</kbd> + <kbd>T</kbd> | 開啟 Kitty 終端機 | GPU 硬體加速與毛玻璃底色 |
| <kbd>Win</kbd> + <kbd>←</kbd> / <kbd>→</kbd> (或 <kbd>H</kbd>/<kbd>L</kbd>) | 焦點左右移動分欄 | 橫向平滑捲動 |
| <kbd>Win</kbd> + <kbd>↑</kbd> (或 <kbd>M</kbd>/<kbd>F</kbd>) | 最大化當前分欄 | 填滿全螢幕 |
| <kbd>Win</kbd> + <kbd>↓</kbd> (或 <kbd>R</kbd>) | 還原視窗尺寸 | 重設高度 |
| <kbd>Win</kbd> + <kbd>Ctrl</kbd> + <kbd>←</kbd> / <kbd>→</kbd> | 切換上下虛擬桌面 | 工作區切換 |
| <kbd>Shift</kbd> (單擊) | 切換中文 / 英文輸入模式 | Fcitx5 新酷音注音 |

---

## 🚀 快速安裝與啟用

### 1. 執行一鍵自動化部署
```bash
git clone https://github.com/codingpeanut/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x setup.sh
./setup.sh
```

### 2. 登入 Niri
1. 儲存工作並登出目前桌面環境。
2. 在登入管理器 (GDM / SDDM / greetd) 右下角設定圖示中，選擇 **Niri**。
3. 輸入密碼登入，即可享受極致絲滑的毛玻璃桌面！

---

## 📂 專案目錄結構

```text
dotfiles/
├── .chezmoi.toml.tmpl         # Chezmoi 主題與硬體變數
├── setup.sh                   # 一鍵編譯、依賴安裝與同步腳本
├── dot_config/
│   ├── niri/
│   │   └── config.kdl         # Niri 視窗管理配置、彈簧物理係數、Windows 快捷鍵
│   ├── quickshell/
│   │   ├── shell.qml          # Quickshell 進入點
│   │   ├── theme/             # Catppuccin Mocha / Latte 雙模主題色彩宣告
│   │   ├── bar/               # 頂部懸浮島式狀態列
│   │   ├── controlcenter/     # 抽屜控制中心 (Wi-Fi, 藍牙, 音量/亮度, 護眼)
│   │   ├── osd/               # 浮動音量與亮度 OSD
│   │   ├── launcher/          # Spotlight 居中應用程式搜尋啟動器
│   │   └── notifications/     # 桌面毛玻璃通知彈窗
│   ├── kitty/
│   │   └── kitty.conf         # Kitty GPU 加速終端機 (Catppuccin + 微透)
│   ├── fcitx5/
│   │   ├── config             # Shift 鍵切換中英文
│   │   └── profile            # 預設新酷音輸入法
│   └── hypr/
│       ├── hyprlock.conf      # 桌面模糊快照鎖定畫面
│       └── hypridle.conf      # 筆電閒置調光與休眠管理
└── install/
    ├── 01_debian_deps.sh      # Debian Testing 依賴安裝
    ├── 02_zram.sh             # 8GB RAM zram 即時壓縮設定
    ├── 03_build_quickshell.sh # Quickshell 原始碼編譯腳本
    └── 04_install_niri.sh     # Niri 安裝與 Wayland Session 註冊
```
