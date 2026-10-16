# 現代簡約玻璃風 GNOME 桌面 (Fedora)

> **「以 GNU Stow 模組化架構 + Ansible 宣告式自動化 + Justfile 一鍵維護，打造乾淨、低調、有質感的 GNOME 50 桌面。」**
>
> 以 **Fedora Workstation (GNOME 50)** 為基礎，透過 **gext** 宣告式管理 GNOME Shell 擴充、**dconf** 統一桌面設定、**Colloid** 主題與 **Inter / JetBrainsMono Nerd Font** 字型，呈現現代簡約的玻璃 (Glassmorphism) 風格。

---

## 🎨 視覺與架構亮點

- **現代簡約玻璃風**：
  - **Blur My Shell** 為面板、Dash 與 Overview 加上柔和模糊。
  - **Just Perfection** 精簡 Shell 元素，**Rounded Window Corners Reborn** 帶來圓角視窗。
  - **PaperWM** 提供可捲動的平鋪式視窗管理（scrollable tiling）。
  - **Colloid-Dark (grey / rimless)** GTK 主題 + **Papirus-Dark** 圖示 + **Bibata-Modern-Ice** 游標。
- **宣告式 GNOME 擴充管理 (gext)**：
  - EGO 擴充集中於 `gnome/extensions.txt`，本 repo 自帶的本地擴充列於 `gnome/extensions-local.txt`；清單即真相，未宣告的擴充會自動移除。
- **dconf 設定即程式碼**：
  - `gnome/dconf.ini` 保存 `/org/gnome/` 的完整外觀與快捷設定；`just gnome-backup` 固化、`just gnome-apply` 套用。
- **GNU Stow 模組化軟連結管理**：
  - 檔案型設定（GTK CSS、fontconfig、environment.d）收於 `stow/gnome/`，不污染家目錄。
- **Ansible + Justfile 宣告式維護**：
  - `just apply` 一鍵完成 `git pull` → 系統套件 → 軟連結部署 → GNOME 擴充同步 → dconf 套用；
    也可分項執行 `just gnome`、`just stow`、`just fix`。

---

## 🧩 核心 GNOME Shell 擴充

| 擴充 | 用途 |
| :--- | :--- |
| Blur My Shell | 面板 / Dash / Overview 玻璃模糊 |
| Just Perfection | 精簡 Shell 元素（隱藏項目、調整位置） |
| Rounded Window Corners Reborn | 視窗圓角 |
| PaperWM | 可捲動平鋪視窗管理（取代 Tiling Assistant） |
| AppIndicator | 系統匣圖示支援 |
| Date Menu Formatter | 時鐘日期格式自訂 |
| Caffeine | 防休眠 / 常亮切換 |
| Clipboard History | 剪貼簿歷史 (Super+V 風格) |
| Hide Bluetooth Indicator | 隱藏面板獨立藍牙圖示（本 repo 自帶，非 EGO） |

> EGO 擴充清單定義於 `gnome/extensions.txt`，本 repo 自帶擴充於 `gnome/extensions-local.txt`；UUID 與 GNOME 50 相容性可於 <https://extensions.gnome.org> 查核。
> 注意：PaperWM 與 Rounded Window Corners 有已知相容性問題（[PaperWM#763](https://github.com/paperwm/PaperWM/issues/763)），若出現視覺異常可考慮停用其一。

---

## ⌨️ 常用操作

| 操作 | 功能說明 |
| :--- | :--- |
| <kbd>Super</kbd> | 開啟 Overview 總覽 / 搜尋 |
| <kbd>Super</kbd> + <kbd>A</kbd> | 快速設定（Wi-Fi、藍牙、電源、音量、亮度） |
| <kbd>Super</kbd> + <kbd>V</kbd> | 剪貼簿歷史（Clipboard History 擴充） |
| <kbd>Print</kbd> / <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | 截圖 / 區域截圖 |
| <kbd>Super</kbd> + <kbd>←</kbd> / <kbd>→</kbd> | 切換左右視窗（PaperWM） |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>←</kbd> / <kbd>→</kbd> | 移動視窗（PaperWM） |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Esc</kbd> | 開啟系統監控 |

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
just apply            # 一鍵搞定：git pull + 完整套用（系統套件 + stow + GNOME 擴充/主題 + dconf）
just gnome            # 安裝擴充、主題、圖示、游標、字型並套用設定 (Ansible)
just gnome-apply      # 快速載入 gnome/dconf.ini + 啟用擴充（不經 Ansible）
just gnome-backup     # 將目前 GNOME 設定 dump 回 gnome/dconf.ini
just gnome-update     # 更新所有已安裝擴充
just gnome-fix-blur   # 修復 Blur My Shell 面板異常（半透明面板，見下方說明）
just stow             # 重新連結所有 dotfiles（衝突自動備份為 *.bak，安全切換 repo）
just stow-dry         # 預覽 stow 會做什麼，不實際變更
just unstow           # 移除所有 dotfiles 軟連結
just fix              # 拉取更新 + 安裝套件 + stow + gnome + 檢查
just push             # 提交並推送修改至 GitHub
```

> `just stow` 由 `scripts/stow.sh` 安全包裝：部署前會掃描衝突，既有實體檔案或
> 指向其他位置（例如舊 clone）的殘留軟連結都會先備份成 `*.bak`，且絕不會透過
> 軟連結去更動其他 repo 的檔案。所有連結皆使用 `--no-folding`，目錄保持實體，
> 避免其他程式（如 gext）寫入時誤改 repo。

> **已知問題 — Blur My Shell 面板異常**：在 GNOME 50 / Fedora 44 上，Blur My
> Shell 於登入後可能出現「面板一半透明／模糊未正確初始化」（多螢幕環境尤其
> 常見），上游 issue
> [aunetx/blur-my-shell#882](https://github.com/aunetx/blur-my-shell/issues/882)
> 仍開啟中。暫時解法：執行 `just gnome-fix-blur`（等同停用再啟用擴充）。
> 此問題與 Just Perfection 無關。

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
│   ├── extensions.txt        # gext EGO 擴充清單 (安裝 + 啟用)
│   ├── extensions-local.txt  # 本 repo 自帶擴充清單 (僅啟用)
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
