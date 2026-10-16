# 現代簡約玻璃風 GNOME 桌面 (Fedora)

> **「以 GNU Stow 模組化架構 + Ansible 宣告式自動化 + Justfile 一鍵維護，打造乾淨、低調、有質感的 GNOME 50 桌面。」**
>
> 以 **Fedora Workstation (GNOME 50)** 為基礎，透過 **gext** 宣告式管理 GNOME Shell 擴充、**dconf** 統一桌面設定、**Colloid** 主題與 **Inter / JetBrainsMono Nerd Font** 字型，呈現現代簡約的玻璃 (Glassmorphism) 風格。

---

## 🎨 視覺與架構亮點

- **現代簡約玻璃風**：
  - **Blur My Shell** 為面板、Dash 與 Overview 加上柔和模糊。
  - **Just Perfection** 精簡 Shell 元素，**Rounded Window Corners Reborn** 帶來圓角視窗。
  - **Colloid-Dark (grey / rimless)** GTK 主題 + **Papirus-Dark** 圖示 + **Bibata-Modern-Ice** 游標。
- **宣告式 GNOME 擴充管理 (gext)**：
  - 所有擴充 UUID 集中於 `gnome/extensions.txt`，由 `gext` 安裝與啟用，一鍵同步。
- **dconf 設定即程式碼**：
  - `gnome/dconf.ini` 保存 `/org/gnome/` 的完整外觀與快捷設定；`just gnome-backup` 固化、`just gnome-apply` 套用。
- **GNU Stow 模組化軟連結管理**：
  - 檔案型設定（GTK CSS、fontconfig、environment.d）收於 `stow/gnome/`，不污染家目錄。
- **Ansible + Justfile 宣告式維護**：
  - `just gnome`、`just stow`、`just fix` 一鍵完成套件安裝、軟連結部署與設定套用。

---

## 🧩 核心 GNOME Shell 擴充

| 擴充 | 用途 |
| :--- | :--- |
| Blur My Shell | 面板 / Dash / Overview 玻璃模糊 |
| Just Perfection | 精簡 Shell 元素（隱藏項目、調整位置） |
| Space Bar | i3 風格工作區指示器 |
| Rounded Window Corners Reborn | 視窗圓角 |
| AppIndicator | 系統匣圖示支援 |
| Vitals | CPU / 記憶體 / 溫度監控 |
| Date Menu Formatter | 時鐘日期格式自訂 |
| Caffeine | 防休眠 / 常亮切換 |
| Clipboard History | 剪貼簿歷史 (Super+V 風格) |
| Tiling Assistant | Windows 風格視窗貼齊 |

> 擴充清單定義於 `gnome/extensions.txt`；UUID 與 GNOME 50 相容性可於 <https://extensions.gnome.org> 查核。

---

## ⌨️ 常用操作

| 操作 | 功能說明 |
| :--- | :--- |
| <kbd>Super</kbd> | 開啟 Overview 總覽 / 搜尋 |
| <kbd>Super</kbd> + <kbd>A</kbd> | 快速設定（Wi-Fi、藍牙、電源、音量、亮度） |
| <kbd>Super</kbd> + <kbd>V</kbd> | 剪貼簿歷史（Clipboard History 擴充） |
| <kbd>Print</kbd> / <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | 截圖 / 區域截圖 |
| <kbd>Super</kbd> + <kbd>←</kbd> / <kbd>→</kbd> | 視窗左右貼齊（Tiling Assistant） |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Esc</kbd> | 開啟系統監控（可搭配 Vitals） |

---

## 🚀 快速安裝與維護指令

### 1. 初次安裝
```bash
git clone https://github.com/codingpeanut/dotfiles.git ~/dotfiles
cd ~/dotfiles
just bootstrap        # 或 scripts/bootstrap.sh，安裝 git/ansible/just/stow 並執行 just apply
```

### 2. 日常維護指令
```bash
just gnome            # 安裝擴充、主題、圖示、游標、字型並套用設定 (Ansible)
just gnome-apply      # 快速載入 gnome/dconf.ini + 啟用擴充（不經 Ansible）
just gnome-backup     # 將目前 GNOME 設定 dump 回 gnome/dconf.ini
just gnome-update     # 更新所有已安裝擴充
just stow             # 重新連結所有 dotfiles 到 ~/.config
just fix              # 拉取更新 + 安裝套件 + stow + gnome + 檢查
just push             # 提交並推送修改至 GitHub
```

### 3. 完全解除安裝 (Uninstall)
```bash
just uninstall          # 解除軟連結、還原備份、重置 GNOME 設定並移除擴充
just uninstall-dry      # 預覽即將清理的項目 (dry-run)
just uninstall-system   # 僅移除本專案安裝的 GNOME 美化系統套件
just -f uninstall.just  # 亦可透過獨立 Justfile 操作

# 系統尚未安裝 just 時可直接執行腳本：
./scripts/uninstall.sh --dry-run
./scripts/uninstall.sh
./scripts/uninstall.sh --all
```

---

## 📂 專案目錄結構

```text
dotfiles/
├── Justfile                  # 常用任務界面 (just gnome / stow / fix ...)
├── uninstall.just            # 獨立解除安裝任務
├── README.md
│
├── gnome/                    # GNOME 宣告式 payload (非軟連結)
│   ├── extensions.txt        # gext 擴充清單 (UUID)
│   └── dconf.ini             # /org/gnome/ 設定 dump (gnome-backup 生成)
│
├── ansible/                  # 宣告式系統套件與配置自動化
│   ├── playbook.yml
│   ├── vars/default.yml
│   └── tasks/
│       ├── system/           # DNF 套件、COPR、systemd
│       └── user/
│           ├── gnome_extensions.yml   # gext 安裝 / 啟用擴充
│           ├── gnome_themes.yml       # Colloid / Nerd Font 安裝
│           ├── gnome_settings.yml     # dconf load + gsettings
│           ├── dotfiles.yml           # GNU Stow 軟連結
│           └── ...
│
├── scripts/                  # bootstrap / uninstall 腳本
└── stow/                     # 按應用模組化的 GNU Stow 配置
    ├── gnome/                # GTK CSS / fontconfig / environment.d
    ├── bash/                 # Shell 環境與工具腳本
    ├── kitty/                # Kitty 終端機
    ├── nvim/                 # Neovim / Vim
    ├── starship/             # Starship Prompt
    └── fcitx5/               # Fcitx5 輸入法
```

> **提示**：GNOME 50 為 Wayland 工作階段，Shell 與佈景主題變更需要**登出再登入**才會完全生效；擴充的啟用/停用則可即時套用。
