# 現代簡約玻璃風 GNOME 桌面 (Fedora)

> **「以 GNU Stow 模組化架構 + Ansible 宣告式自動化 + Justfile 一鍵維護，打造乾淨、低調、有質感的 GNOME 50 桌面。」**
>
> 以 **Fedora Workstation (GNOME 50)** 為基礎，透過 **gext** 宣告式管理 GNOME Shell 擴充、**dconf** 統一桌面設定、**Colloid** 主題與 **Inter / JetBrainsMono Nerd Font** 字型，呈現現代簡約的玻璃 (Glassmorphism) 風格。

---

## 🎨 視覺與架構亮點

- **現代簡約玻璃風**：
  - **Blur My Shell** 為面板、Dash 與 Overview 加上柔和模糊。
  - **Just Perfection** 精簡 Shell 元素。
  - **PaperWM** 提供可捲動的平鋪式視窗管理（scrollable tiling）。
  - **Colloid-Grey-Light（預設淺色；深色為 Colloid-Grey-Dark）** GTK 主題 + **Papirus-Light** 圖示 + **Bibata-Modern-Ice** 游標，`color-scheme=prefer-light`。
- **GDM 登入畫面同步（`just gdm-theme`）**：
  - 外觀與桌面同步：`color-scheme`（深/淺）、accent、GTK/icon 主題、字型、游標以桌面**即時值**為準，寫入 `/etc/dconf/db/gdm.d/50-dotfiles-desktop-sync`（Fedora 官方 `system-db:gdm`）。
  - 桌布同款背景：`picture-uri` / `picture-uri-dark` 兩張都嵌入主題（light/dark 樣式檔各用各的），**切換深淺不需重建**。
  - `sudo just gdm-theme-reset` 可完全還原（gresource、兩份 dconf、系統層游標）。
- **宣告式 GNOME 擴充管理 (gext)**：
  - EGO 擴充集中於 `gnome/extensions.txt`，本 repo 自帶的本地擴充列於 `gnome/extensions-local.txt`，預設停用清單為 `gnome/extensions-disabled.txt`；清單即真相，未宣告的擴充會自動移除。
- **dconf 設定即程式碼**：
  - `gnome/dconf.ini` 保存 `/org/gnome/` 的完整外觀與快捷設定；`just gnome-backup` 固化、`just gnome-apply` 套用。
- **GNU Stow 模組化軟連結管理**：
  - 檔案型設定（GTK CSS、fontconfig、environment.d）收於 `stow/gnome/`，不污染家目錄。
- **Ansible + Justfile 宣告式維護**：
  - `just apply` 一鍵完成 `git pull` → 系統套件 → 軟連結部署 → GNOME 擴充同步 → dconf 套用；
    也可分項執行 `just gnome`、`just stow`、`just fix`。
- **登入反應優化**：
  - 以 systemd user drop-in 調降 `gnome-software` 背景服務的 CPU/IO 優先權，避免它剛進桌面時載入 AppStream／圖示與 GNOME Shell 搶資源；由 `ansible/tasks/user/services.yml` 宣告部署，`just check` 會驗證。

---

## 🧩 核心 GNOME Shell 擴充

| 擴充 | 用途 |
| :--- | :--- |
| Blur My Shell | 面板 / Dash / Overview 玻璃模糊 |
| Just Perfection | 精簡 Shell 元素（隱藏項目、調整位置、縮小 overview dash 圖示） |
| PaperWM | 可捲動平鋪視窗管理（取代 Tiling Assistant） |
| AppIndicator | 系統匣圖示支援 |
| Dash to Dock | 底部 dock，自動隱藏（滑到螢幕底緣顯示）；**預設停用** |
| Caffeine | 防休眠 / 常亮切換 |
| Clipboard History | 剪貼簿歷史 (Super+V 風格) |
| Hide Bluetooth Indicator | 隱藏面板獨立藍牙圖示（本 repo 自帶，非 EGO） |

> EGO 擴充清單定義於 `gnome/extensions.txt`，本 repo 自帶擴充於 `gnome/extensions-local.txt`，預設停用清單為 `gnome/extensions-disabled.txt`；UUID 與 GNOME 50 相容性可於 <https://extensions.gnome.org> 查核。
> **Dash to Dock 預設停用**：UUID 仍保留在 `extensions.txt` 以確保安裝，但列於 `extensions-disabled.txt`；要啟用時請把它從停用清單移除，並同步更新 `gnome/dconf.ini` 的 `enabled-extensions` / `disabled-extensions`，再執行 `just gnome-apply`。
> 藍牙圖示：GNOME 內建指示器（僅裝置連線時出現）由 Hide Bluetooth Indicator 擴充隱藏；藍牙開關與裝置管理統一使用 GNOME Quick Settings / Settings。
> **PaperWM 選取框**：聚焦視窗的選取框在 GNOME 50 預設是強調色藍（`.tile-preview` 背景填充）；本 repo 以 `stow/gnome/.config/paperwm/user.css` 改為中性半透明玻璃框（PaperWM 只在此檔不存在時才會覆寫，故可安全以 stow 管理），尺寸/圓角於 `gnome/dconf.ini`（`selection-border-size=4`、`selection-border-radius-*=16`，同心對齊 GNOME 50 的 12px 視窗圓角）。改完 user.css 後執行 `gnome-extensions disable/enable paperwm@paperwm.github.com` 即時重載，免重登。
> **Dash to Dock 模糊**：dock 本身無模糊，由 Blur My Shell 的 Dash to Dock 元件提供；模糊類型為動態（`static-blur=false`，與 panel 相同的即時模糊層，視窗在 dock 後方也會被模糊；圓角由 `gnome-rounded-blur` helper 提供），`blur`/`override-background`/`style-dash-to-dock=0` 已完整宣告，BMS 以 `.transparent-dash`（`!important`）清掉 dock 背景讓模糊層透出；`settings-version=2` 防止 BMS 一次性遷移在全新安裝時把 dock 改回靜態模糊。若 dock 沒模糊，重新 `just gnome-apply` 後執行 `just gnome-fix-blur`（重新掃描 dock），必要時重新登入。
> **中英切換鍵**：ibus-chewing 的 Chinese/Alphanumeric 切換鍵宣告為 <kbd>Shift</kbd>（`gnome/dconf-desktop.ini` → `chi-eng-mode-toggle`，上游預設為 Caps Lock；改值後 GSettings 綁定即時生效）；fcitx5 側對應設定為 `Shift_L`（`stow/fcitx5`，備用）。

---

## ⌨️ 常用操作

快捷鍵以 **niri 預設鍵位**為藍本（`Mod` = <kbd>Super</kbd>），完整宣告於 `gnome/dconf.ini`。

**視窗 / column**

| 操作 | 功能 |
| :--- | :--- |
| <kbd>Super</kbd>+<kbd>←</kbd>/<kbd>→</kbd> 或 <kbd>H</kbd>/<kbd>L</kbd> | focus 左/右 column |
| <kbd>Super</kbd>+<kbd>↑</kbd>/<kbd>↓</kbd> 或 <kbd>K</kbd>/<kbd>J</kbd> | focus 上/下視窗（column 內） |
| <kbd>Super</kbd>+<kbd>Ctrl</kbd>+方向/HJKL | 移動視窗（column/stack 內） |
| <kbd>Super</kbd>+<kbd>Shift</kbd>+方向/HJKL | focus 其他螢幕 |
| <kbd>Super</kbd>+<kbd>Shift</kbd>+<kbd>Ctrl</kbd>+方向/HJKL | 移動視窗到其他螢幕 |
| <kbd>Super</kbd>+<kbd>Home</kbd>/<kbd>End</kbd> | 第一/最後 column |
| <kbd>Super</kbd>+<kbd>[</kbd>/<kbd>]</kbd> | 視窗推入/拉出相鄰 space（drift） |
| <kbd>Super</kbd>+<kbd>,</kbd>/<kbd>.</kbd> | 吸入/吐出 column（slurp / barf） |
| <kbd>Super</kbd>+<kbd>C</kbd> | column 置中 |
| <kbd>Super</kbd>+<kbd>V</kbd> | 浮動視窗切換（scratch layer） |
| <kbd>Super</kbd>+<kbd>Q</kbd> | 關閉視窗（<kbd>Alt</kbd>+<kbd>F4</kbd> 亦可） |

**寬高 / 最大化**

| 操作 | 功能 |
| :--- | :--- |
| <kbd>Super</kbd>+<kbd>R</kbd> / <kbd>Shift</kbd>+<kbd>R</kbd> | 循環 column 寬度（1/3 ↔ 1/2 ↔ 2/3） |
| <kbd>Super</kbd>+<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd> | 循環視窗高度 |
| <kbd>Super</kbd>+<kbd>−</kbd>/<kbd>=</kbd>（加 <kbd>Shift</kbd> 調高度） | 寬/高 ±10% |
| <kbd>Super</kbd>+<kbd>F</kbd> / <kbd>Shift</kbd>+<kbd>F</kbd> | 最大化 column / 全螢幕 |
| <kbd>Super</kbd>+<kbd>M</kbd> | 最大化到螢幕邊緣 |

**Workspace**

| 操作 | 功能 |
| :--- | :--- |
| <kbd>Super</kbd>+<kbd>Page⇣</kbd>/<kbd>Page⇡</kbd> 或 <kbd>U</kbd>/<kbd>I</kbd> | 切換下/上 workspace |
| <kbd>Super</kbd>+<kbd>Ctrl</kbd>+<kbd>Page⇣</kbd>/<kbd>Page⇡</kbd> 或 <kbd>Ctrl</kbd>+<kbd>U</kbd>/<kbd>I</kbd> | 移動 column 到下/上 workspace |
| <kbd>Super</kbd>+<kbd>1</kbd>…<kbd>4</kbd> | 切換到 workspace 1-4 |
| <kbd>Super</kbd>+<kbd>Ctrl</kbd>+<kbd>1</kbd>…<kbd>4</kbd> | 移動 column 到 workspace 1-4 |

**系統 / 其他**

| 操作 | 功能 |
| :--- | :--- |
| <kbd>Super</kbd> | Overview 總覽 / 搜尋 |
| <kbd>Super</kbd>+<kbd>O</kbd> | 開啟/關閉 Overview |
| <kbd>Super</kbd>+<kbd>S</kbd> | 快速設定（Wi-Fi、藍牙、電源…） |
| <kbd>Super</kbd>+<kbd>A</kbd> | 應用程式格（App Grid） |
| <kbd>Super</kbd>+<kbd>T</kbd> | 開啟終端機（Ptyxis，GNOME 預設） |
| <kbd>Super</kbd>+<kbd>Alt</kbd>+<kbd>L</kbd> | 鎖定螢幕 |
| <kbd>Print</kbd> / <kbd>Super</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> | 截圖 UI（框選區域） |
| <kbd>Ctrl</kbd>+<kbd>Print</kbd> / <kbd>Alt</kbd>+<kbd>Print</kbd> | 直接全螢幕 / 視窗截圖 |
| <kbd>Super</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd> | 剪貼簿歷史 |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Esc</kbd> | 系統監控 |

> **刻意與 GNOME 預設不同**：<kbd>Super</kbd>+<kbd>L</kbd> 改為 focus 右欄（鎖定搬到 <kbd>Super</kbd>+<kbd>Alt</kbd>+<kbd>L</kbd>）；<kbd>Super</kbd>+<kbd>1</kbd>…<kbd>9</kbd> 改切 workspace（原「開釘選 app」已清空）；<kbd>Super</kbd>+<kbd>V</kbd>/<kbd>M</kbd> 改浮動/最大化（原通知清單快捷已清空）。PaperWM 啟用時會**自動暫停**衝突的 GNOME 原生鍵（<kbd>Super</kbd>+<kbd>↑</kbd>/<kbd>↓</kbd>、<kbd>Super</kbd>+<kbd>H</kbd>、<kbd>Super</kbd>+<kbd>Home</kbd>/<kbd>End</kbd>、<kbd>Super</kbd>+<kbd>Shift</kbd>+方向、<kbd>Super</kbd>+<kbd>PageUp</kbd>/<kbd>Down</kbd>），停用時自動還原。
> **Dash to Dock 搶鍵已讓位**：D2D 預設 `hot-keys=true`（<kbd>Super</kbd>+數字開釘選 app）與 `shortcut=['<Super>q']`（顯示 dock），且比 PaperWM 先註冊而贏走按鍵；已宣告 `hot-keys=false` + `shortcut=@as []` 釋放給 PaperWM 關窗（<kbd>Super</kbd>+<kbd>Q</kbd>）與 workspace 數字鍵。
> **未實作（PaperWM/GNOME 無對應）**：niri 的 `Mod+W`（tab 欄）、`Mod+Ctrl+F`（expand）、`Mod+Ctrl+R`（重設高度）、`Mod+Ctrl+Home/End`、`Mod+Shift+U/I`（移動 workspace）、`Mod+D`（啟動器，系統未安裝）、`Mod+Escape`（shortcut inhibitor）、`Mod+Shift+E`（結束 session）、`Mod+Shift+P`（關閉螢幕）。
> `just gnome-backup` 會自動過濾 PaperWM 的 `restore-keybinds` 欄位（衝突還原清單），避免污染 dconf.ini。

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
just gnome-apply      # 快速載入 gnome/dconf.ini + 同步擴充（含預設停用）
just gnome-backup     # 將目前 GNOME 設定 dump 回 gnome/dconf.ini
just gnome-update     # 更新所有已安裝擴充
just gnome-fix-blur   # 修復 Blur My Shell 面板異常（半透明面板，見下方說明）
just gdm-theme        # GDM 登入畫面美化（同步桌面深淺與桌布；需 sudo）
just gdm-theme-reset  # 還原原廠 GDM 登入畫面
just mem              # 診斷記憶體：前 16 大行程、GNOME Shell 佔用、已啟用擴充與 free -h
just stow             # 重新連結所有 dotfiles（衝突自動備份為 *.bak，安全切換 repo）
just stow-dry         # 預覽 stow 會做什麼，不實際變更
just unstow           # 移除所有 dotfiles 軟連結
just fix              # 拉取更新 + 安裝套件 + stow + gnome + 檢查
just check            # 健檢：CLI 相依、宣告 vs 目標擴充狀態、主題/字型/Flatpak
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

> **Blur My Shell 動態模糊圓角（gnome-rounded-blur）**：BMS 動態模糊會另疊
> 一層動態層，缺少圓角 helper 時該層邊角不吻合 popup 卡片（看起來像「多一層
> 背景」）。本 repo 透過 `ublue-os/packages` COPR 安裝 `gnome-rounded-blur`
> （`ansible/tasks/system/rounded_blur.yml`，`just system`），BMS v70+ 啟動時
> 會偵測 `Blur` typelib（`/usr/lib64/girepository-1.0/Blur-1.0.typelib`）
> 並自動為動態層套用圓角，因此 panel 與 popup 維持「動態（Dynamic）」。
> 安裝後需重新登入生效；GNOME/mutter 更新後執行 `just update` 取得 COPR
> 重編版本。此依賴會帶入 Fedora 的 `gnome-shell-extension-blur-my-shell`
> 系統套件，user 層 EGO 版本仍優先，不影響啟用的擴充。

> **GDM 登入畫面（`just gdm-theme`）**：登入畫面**與桌面同步**。`scripts/gdm-theme.sh`
> 以桌面**即時**的 `org.gnome.desktop.interface` 為準（鍵集合固定為腳本內的
> `INTERFACE_KEYS`；讀不到工作階段時才退回 `gnome/dconf.ini` 快照），鏡射 greeter 的
> `color-scheme`、accent、GTK/icon 主題、字型、游標，寫入 Fedora 官方支援的
> `/etc/dconf/db/gdm.d/50-dotfiles-desktop-sync`（`system-db:gdm`，不受套件更新影響）。
> 改完桌面（深淺、accent、字型、桌布）執行 `sudo just gdm-theme` 即同步——**非即時連動**，
> `just check` 會提示尚未同步。
> 注意 GNOME 的 `color-scheme='default'` 對 shell 而言等同深色（`getStyleVariant()`
> 只在 `prefer-light` 時選淺色檔），greeter 比照辦理。
> GNOME 50 依 `color-scheme` 載入 `gnome-shell-{light,dark}.css`（已無舊版 `gdm.css`）；
> 背景是 `#lockDialogGroup` 的純色，故腳本把桌布嵌進主題並重建
> `gnome-shell-theme.gresource`——**light 與 dark 兩個樣式檔都補**（各自嵌
> `picture-uri` / `picture-uri-dark`，讀不到時用 `adwaita-{l,d}.jxl`），所以切換深淺
> **不需要重建**；`high-contrast` 只換背景、不套玻璃感（保留高對比）。
> 也可用 `--image` 指定固定圖。
> 游標另會從 `~/.local` 複製一份到 `/usr/share/icons`（greeter 讀不到家目錄）。此外
> `gnome/gdm-greeter.css` 把頂部面板、使用者清單改成半透明玻璃感（`gdm-theme` 依 CSS 檔的
> sha256 決定是否重建）——覆寫一律限定 greeter 專屬選擇器（`#panel.login-screen`、
> `.login-dialog-*`），**不影響桌面與鎖定畫面**（深色樣式檔三者共用，面板以
> `.login-screen` 區分）。桌面的擴充（如 Blur my Shell）**無法**在登入畫面載入——GNOME 要求
> 擴充宣告 `session-modes: ["gdm"]`，故只能以半透明近似真模糊。
>
> **可逆**：`sudo just gdm-theme-reset` 會還原原廠 gresource、移除兩份 dconf 與系統層游標
> （腳本只在 `gnome-shell` 更新覆蓋 gresource 後才需重跑；`just update` 會自動重套、
> `just check` 會提示未同步）。若手動刪掉狀態目錄 `/var/lib/dotfiles-gdm`，腳本會偵測到
> 「已修補但無狀態」而拒絕重複疊加，並提示先 `sudo dnf reinstall gnome-shell` 還原原廠
> gresource。重啟 GDM 會登出所有工作階段（腳本結尾詢問是否立即執行）。

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
│   ├── extensions.txt          # gext EGO 擴充清單 (安裝 + 啟用)
│   ├── extensions-local.txt    # 本 repo 自帶擴充清單 (僅啟用)
│   ├── extensions-disabled.txt # 已安裝但預設停用的擴充
│   ├── dconf.ini               # /org/gnome/ 設定 dump (gnome-backup 生成)
│   ├── dconf-desktop.ini       # /desktop/ 設定 (ibus-chewing 切換鍵等)
│   ├── gdm-dconf.ini           # greeter 專屬設定 (gdm-theme 安裝成 90-dotfiles)
│   └── gdm-greeter.css         # GDM greeter 視覺覆寫 (僅 greeter 專屬選擇器)
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
├── scripts/                  # bootstrap / uninstall / stow / gdm-theme 腳本
└── stow/                     # 按應用模組化的 GNU Stow 配置
    ├── gnome/                # GTK CSS / fontconfig / environment.d
    ├── bash/                 # Shell 環境與工具腳本
    ├── kitty/                # Kitty 終端機（備用，日常使用 Ptyxis）
    ├── nvim/                 # Neovim / Vim
    ├── starship/             # Starship Prompt
    └── fcitx5/               # Fcitx5 輸入法
```

> **提示**：GNOME 50 為 Wayland 工作階段，Shell 與佈景主題變更需要**登出再登入**才會完全生效；擴充的啟用/停用則可即時套用。
