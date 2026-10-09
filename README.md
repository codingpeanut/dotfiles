# Niri + Noctalia 現代微透桌面 (Debian / Fedora)

> **「採用 GNU Stow 模組化架構與 Justfile 自動化管理，統一 Tokyo Night (東京之夜) 視覺美學」**
>
> 結合 **Niri** 的無限橫向視窗捲軸流動與 **Noctalia (v5+)** 現代一體化微透毛玻璃 (Glassmorphism) 桌面外殼，並完整支援 **Windows 肌肉記憶快捷鍵**。

---

## 🎨 視覺與架構亮點

- **Tokyo Night (東京之夜) 統一美學**：
  - 全系統貫徹 Tokyo Night 深色調（底色 `#1a1b26`、表面卡片 `#24283b`、強調藍 `#7aa2f7`、紫羅蘭 `#bb9af7`、文字 `#c0caf5`）。
  - Niri 聚焦環 (`#7aa2f7`)、Noctalia 面板邊框微發光、Kitty 終端機與 Hyprlock 鎖定畫面色彩全面統一。
- **全功能一體化 Noctalia Desktop Shell (v5+)**：
  - **頂部懸浮島狀態列 (Floating Island Bar)**：整合工作區指示器、視窗標題、系統狀態與時鐘。
  - **抽屜式控制中心 (Control Center)**：一指展開電源模式 ( 效能 / 󰾅 平衡 /  省電)、防睡眠常亮模式 (☕ Caffeine Toggle)、Wi-Fi、藍牙、深淺模式切換、音量與螢幕亮度滑桿。
  - **Spotlight 居中搜尋啟動器**：<kbd>Win</kbd> 或 <kbd>Win + Space</kbd> 喚出，支援即時數學算式計算機 (`/calc`)、Emoji 表情選擇器 (`/emo`)、工作階段關機重開機 (`/session`) 與視窗切換。
  - **浮動剪貼簿管理器**：<kbd>Win + V</kbd> 呼叫，具備歷史紀錄搜尋與複製保護。
  - **系統級區域截圖編輯器**：<kbd>Win + Shift + S</kbd> 呼叫，支援自訂標註與複製至剪貼簿。
  - **3D 景深視窗切換器**：<kbd>Alt + Tab</kbd> 輪播預覽與最近使用視窗排序。
- **GNU Stow 模組化軟連結管理**：
  - 每個軟體獨立收納於 `stow/<app>/`，不污染家目錄，修改隨改隨生效，Git 版本追蹤一清二楚。
- **Justfile 宣告式日常維護**：
  - 透過 `just stow`、`just reload`、`just fix` 一鍵完成相依套件安裝、軟連結部署與桌面熱重載。

---

## ⌨️ Windows 肌肉記憶快捷鍵矩陣

| 快捷鍵 | 功能說明 | 備註 |
| :--- | :--- | :--- |
| <kbd>Win</kbd> 或 <kbd>Win</kbd> + <kbd>Space</kbd> | 開啟 / 關閉 居中搜尋啟動器 | Noctalia Spotlight 搜尋列 |
| <kbd>Win</kbd> + <kbd>A</kbd> | 開啟快速設定 / 控制中心 | 整合電源模式、防睡眠、音量與亮度 |
| <kbd>Win</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | 區域截圖 (Windows 剪取工具風格) | Noctalia 內建標註編輯器與複製 |
| <kbd>Win</kbd> + <kbd>Alt</kbd> + <kbd>L</kbd> | 鎖定電腦螢幕 | 呼叫 Swaylock 安全鎖屏 |
| <kbd>Win</kbd> + <kbd>E</kbd> | 開啟檔案管理員 (Nautilus) | GNOME Files |
| <kbd>Win</kbd> + <kbd>Ctrl</kbd> + <kbd>V</kbd> | 剪貼簿歷史選單 | Noctalia 浮動歷史選單 / cliphist |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Esc</kbd> | 開啟工作管理員 (btop) | 系統負載即時監控 |
| <kbd>Alt</kbd> + <kbd>Tab</kbd> | 視窗 3D 景深循環切換 | 焦點輪換 |
| <kbd>Alt</kbd> + <kbd>F4</kbd> 或 <kbd>Win</kbd> + <kbd>Q</kbd> | 關閉當前視窗 | 關閉視窗 |
| <kbd>Win</kbd> + <kbd>Enter</kbd> 或 <kbd>Win</kbd> + <kbd>T</kbd> | 開啟 Kitty 終端機 | GPU 硬體加速與 Tokyo Night 底色 |
| <kbd>Win</kbd> + <kbd>←</kbd> / <kbd>→</kbd> (或 <kbd>H</kbd>/<kbd>L</kbd>) | 焦點左右移動分欄 | 橫向平滑捲動 |
| <kbd>Win</kbd> + <kbd>↑</kbd> (或 <kbd>M</kbd>/<kbd>F</kbd>) | 最大化當前分欄 | 填滿全螢幕 |
| <kbd>Win</kbd> + <kbd>↓</kbd> (或 <kbd>R</kbd>) | 還原視窗尺寸 | 重設高度 |
| <kbd>Win</kbd> + <kbd>Ctrl</kbd> + <kbd>←</kbd> / <kbd>→</kbd> | 切換上下虛擬桌面 | 工作區切換 |
| <kbd>Shift</kbd> (單擊) | 切換中文 / 英文輸入模式 | Fcitx5 新酷音注音 |

---

## 🚀 快速安裝與維護指令

### 1. 初次安裝或一鍵修復
```bash
git clone https://github.com/codingpeanut/dotfiles.git ~/dotfiles
cd ~/dotfiles
just fix
```

### 2. 日常維護指令
```bash
just stow     # 重新連結所有配置到 ~/.config
just reload   # 熱重載 Niri 與重啟 Noctalia
just deps     # 檢查並安裝系統相依套件
just push     # 提交並推送最新修改至 GitHub
```

---

## 📂 專案目錄結構

```text
dotfiles/
├── Justfile                  # 常用任務界面 (just stow, just reload, just fix...)
├── README.md                 # 說明文件
│
├── ansible/                  # 宣告式系統套件與配置自動化
├── scripts/                  # 系統工具與引導安裝腳本
│
└── stow/                     # 按應用模組化的 GNU Stow 配置
    ├── niri/                 # Niri 視窗管理器 (~/.config/niri/config.kdl)
    ├── noctalia/             # Noctalia 現代桌面外殼 (~/.config/noctalia/config.toml - 模擬 Waybar 外觀)
    ├── waybar/               # Waybar 狀態列 (備用/原生狀態列)
    ├── mako/                 # Mako 桌面通知 (備用)
    ├── kitty/                # Kitty 終端機 (Tokyo Night 深色微透主題)
    ├── fuzzel/               # Fuzzel 輕量 App 啟動器 (備用)
    ├── wlogout/              # Wlogout 圓形按鈕開關機選單
    ├── fcitx5/               # Fcitx5 輸入法與新酷音注音配置
    ├── nvim/                 # Neovim (init.lua) 與 Vim (.vimrc)
    ├── starship/             # Starship 跨 Shell 終端 Prompt
    ├── bash/                 # Shell 環境、alias 與桌面輔助腳本 (~/.local/bin)
    └── xdg-desktop-portal/   # Wayland 桌面入口協議與螢幕分享設定
```
