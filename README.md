# 現代簡約玻璃風 GNOME 桌面 (Fedora)

> **「以 GNU Stow 模組化架構 + Ansible 宣告式自動化 + Justfile 一鍵維護，打造乾淨、低調、有質感的 GNOME 50 桌面。」**
>
> 以 **Fedora Workstation (GNOME 50)** 為基礎，透過 **gext** 宣告式管理 GNOME Shell 擴充、**dconf** 統一桌面設定、**Colloid** 主題與 **Inter / JetBrainsMono Nerd Font** 字型，呈現現代簡約的玻璃 (Glassmorphism) 風格。

---

## 🎨 視覺與架構亮點

- **現代簡約玻璃風**：
  - **Blur My Shell** 為面板、Dash 與 Overview 加上柔和模糊。
  - **Just Perfection** 精簡 Shell 元素。
  - **GNOME 原生視窗管理** 搭配 **Windows 11 風格鍵位**（半屏貼齊、最大化、工作列 app）；**PaperWM** 仍保留為可選的捲動平鋪模式（預設停用）。
  - **Colloid-Grey-Light（預設淺色；深色為 Colloid-Grey-Dark）** GTK 主題 + **Papirus-Light** 圖示 + **Bibata-Modern-Ice** 游標，`color-scheme=prefer-light`。
- **GDM 登入畫面同步（`just gdm-theme`）**：
  - 外觀與桌面同步：`color-scheme`（深/淺）、accent、GTK/icon 主題、字型、游標以桌面**即時值**為準，寫入 `/etc/dconf/db/gdm.d/50-dotfiles-desktop-sync`（Fedora 官方 `system-db:gdm`）。
  - 桌布同款背景：`picture-uri` / `picture-uri-dark` 兩張都嵌入主題（light/dark 樣式檔各用各的），**切換深淺不需重建**。
  - `sudo just gdm-theme-reset` 可完全還原（gresource、兩份 dconf、系統層游標）。
- **宣告式 GNOME 擴充管理 (gext)**：
  - EGO 擴充集中於 `gnome/extensions.txt`，本 repo 自帶的本地擴充列於 `gnome/extensions-local.txt`，預設停用清單為 `gnome/extensions-disabled.txt`；清單即真相，未宣告的擴充會自動移除。
- **dconf 設定即程式碼**：
  - `gnome/dconf.ini` 保存 `/org/gnome/` 的外觀與快捷設定；`just gnome-backup` 固化、`just gnome-apply` 套用。
  - **桌布不由本 repo 管理**：`just apply` / `just gnome-apply` 不會變更桌面桌布，`just gnome-backup` 也會過濾 `[desktop/background]`；GDM 登入畫面則在執行 `just gdm-theme` 時讀取當下桌布。
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
| PaperWM | 可捲動平鋪視窗管理（**預設停用**；Windows 11 鍵位使用 GNOME 原生視窗管理） |
| AppIndicator | 系統匣圖示支援 |
| Caffeine | 防休眠 / 常亮切換 |
| Clipboard History | 剪貼簿歷史（<kbd>Win</kbd>+<kbd>V</kbd>） |
| Hide Bluetooth Indicator | 隱藏面板獨立藍牙圖示（本 repo 自帶，非 EGO） |

> EGO 擴充清單定義於 `gnome/extensions.txt`，本 repo 自帶擴充於 `gnome/extensions-local.txt`，預設停用清單為 `gnome/extensions-disabled.txt`；UUID 與 GNOME 50 相容性可於 <https://extensions.gnome.org> 查核。
> **PaperWM 預設停用**：UUID 仍保留在 `extensions.txt` 以確保安裝，但列於 `extensions-disabled.txt`；要啟用時請把它從停用清單移除，並同步更新 `gnome/dconf.ini` 的 `enabled-extensions` / `disabled-extensions`，再執行 `just gnome-apply`。PaperWM 的 niri 鍵位仍保留在 `dconf.ini`，但停用時不生效。
> 藍牙圖示：GNOME 內建指示器（僅裝置連線時出現）由 Hide Bluetooth Indicator 擴充隱藏；藍牙開關與裝置管理統一使用 GNOME Quick Settings / Settings。
> **PaperWM 選取框（選用，啟用 PaperWM 時才生效）**：聚焦視窗的選取框在 GNOME 50 預設是強調色藍（`.tile-preview` 背景填充）；本 repo 以 `stow/gnome/.config/paperwm/user.css` 改為中性半透明玻璃框（PaperWM 只在此檔不存在時才會覆寫，故可安全以 stow 管理），尺寸/圓角於 `gnome/dconf.ini`（`selection-border-size=4`、`selection-border-radius-*=16`，同心對齊 GNOME 50 的 12px 視窗圓角）。改完 user.css 後執行 `gnome-extensions disable/enable paperwm@paperwm.github.com` 即時重載，免重登。
> **中英切換鍵**：預設使用 GNOME 原生的 **IBus + ibus-chewing**，Chinese/Alphanumeric 切換鍵宣告為 <kbd>Shift</kbd>（`gnome/dconf-desktop.ini` → `chi-eng-mode-toggle`，上游預設為 Caps Lock；改值後 GSettings 綁定即時生效）。Fcitx5 套件與設定仍保留在 `stow/fcitx5` 作為手動備用，但**不再自動啟動**，環境變數也統一指向 IBus，避免兩套輸入法互相搶佔。

---

## ⌨️ 常用操作

快捷鍵以 **Windows 11** 為藍本（`Win` = <kbd>Super</kbd>），完整宣告於 `gnome/dconf.ini`。PaperWM 預設停用，視窗由 GNOME 原生管理。

**視窗 / 工作區**

| 操作 | 功能 |
| :--- | :--- |
| <kbd>Win</kbd>+<kbd>←</kbd>/<kbd>→</kbd> | 左右半屏貼齊 |
| <kbd>Win</kbd>+<kbd>↑</kbd> / <kbd>↓</kbd> | 最大化 / 還原 |
| <kbd>Win</kbd>+<kbd>D</kbd> | 顯示桌面 |
| <kbd>Win</kbd>+<kbd>Ctrl</kbd>+<kbd>←</kbd>/<kbd>→</kbd> | 切換 workspace |
| <kbd>Win</kbd>+<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>←</kbd>/<kbd>→</kbd> | 移動視窗到 workspace |
| <kbd>Alt</kbd>+<kbd>Tab</kbd> / <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>Tab</kbd> | 切換 app（前/後） |
| <kbd>Alt</kbd>+<kbd>F4</kbd> | 關閉視窗 |
| <kbd>Win</kbd>+<kbd>Tab</kbd> | Overview / 搜尋 |
| <kbd>Win</kbd>+<kbd>1</kbd>…<kbd>9</kbd> | 工作列釘選 app |
| <kbd>Win</kbd>+<kbd>Shift</kbd>+<kbd>1</kbd>…<kbd>9</kbd> | 開新 app instance |

**系統 / 其他**

| 操作 | 功能 |
| :--- | :--- |
| <kbd>Win</kbd> | Overview 總覽 / 搜尋 |
| <kbd>Win</kbd>+<kbd>A</kbd> | App Grid |
| <kbd>Win</kbd>+<kbd>S</kbd> | 快速設定（Wi-Fi、藍牙、電源…） |
| <kbd>Win</kbd>+<kbd>N</kbd> | 通知中心 |
| <kbd>Win</kbd>+<kbd>E</kbd> | 檔案總管（Nautilus） |
| <kbd>Win</kbd>+<kbd>I</kbd> | GNOME 設定 |
| <kbd>Win</kbd>+<kbd>L</kbd> | 鎖定螢幕 |
| <kbd>Win</kbd>+<kbd>R</kbd> | 執行對話框（<kbd>Alt</kbd>+<kbd>F2</kbd> 亦可） |
| <kbd>Win</kbd>+<kbd>V</kbd> | 剪貼簿歷史 |
| <kbd>Win</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd> / <kbd>Print</kbd> | 截圖 UI（框選區域） |
| <kbd>Win</kbd>+<kbd>Print</kbd> / <kbd>Shift</kbd>+<kbd>Print</kbd> | 全螢幕截圖 |
| <kbd>Alt</kbd>+<kbd>Print</kbd> | 視窗截圖 |
| <kbd>Win</kbd>+<kbd>Space</kbd> | 輸入法切換 |
| <kbd>Win</kbd>+<kbd>P</kbd> | 投影模式 |
| <kbd>Super</kbd>+<kbd>T</kbd> | 終端機（Ptyxis；額外保留） |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Esc</kbd> | 系統監控（額外保留） |

> **與 Windows 11 的差異**：<kbd>Win</kbd>+<kbd>Ctrl</kbd>+<kbd>D</kbd> / <kbd>F4</kbd>（新增/關閉虛擬桌面）GNOME 沒有原生快捷鍵，先用 Overview 操作；<kbd>Win</kbd>+<kbd>.</kbd>（emoji）與 <kbd>Win</kbd>+<kbd>X</kbd>（快速選單）沒有直接對應。未最大化時按 <kbd>Win</kbd>+<kbd>↓</kbd> 只會還原、不會最小化；最小化使用 GNOME 預設的 <kbd>Super</kbd>+<kbd>H</kbd>。最大化統一用 <kbd>Win</kbd>+<kbd>↑</kbd>。目前 `favorite-apps` 只有 5 個項目，<kbd>Win</kbd>+<kbd>6</kbd>…<kbd>9</kbd> 暫時沒有對應 app。
> **PaperWM 選用模式**：PaperWM 仍安裝但列於 `extensions-disabled.txt`；niri 鍵位保留在 `gnome/dconf.ini`，停用時不生效。目前尚未提供 `just paperwm` 一鍵切換；手動啟用時仍需自行避開 Windows 原生鍵（例如 `Win+Ctrl+方向`、`Win+H`）與 PaperWM 的衝突，之後可再加雙 profile 切換。
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
just im-reset         # 終端注音輸入異常時，重新啟動 IBus
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
