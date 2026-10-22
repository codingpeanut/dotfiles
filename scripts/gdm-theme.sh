#!/usr/bin/env bash
# ==============================================================================
# gdm-theme.sh - GDM 登入畫面美化：外觀與桌面同步（顏色 / 深淺 / 桌布）
#
# 為什麼需要這個腳本？
#   1. GNOME 的 GDM 登入畫面（greeter）不會顯示桌布：背景是 shell 主題裡
#      #lockDialogGroup 的純色。要換成圖片，唯一乾淨的做法是重建
#      /usr/share/gnome-shell/gnome-shell-theme.gresource（把圖片嵌進去 +
#      覆寫背景樣式），再重啟 GDM。
#      → gnome-shell 套件更新會覆蓋這個檔；更新後重新執行本腳本即可
#        （以 sha256 判斷，未變更時完全 no-op，Justfile 的 just update 會自動重跑）。
#   2. 外觀與桌面同步：greeter 依 gdm profile 的 color-scheme 選樣式檔
#        （GNOME 50：gnome-shell-light.css / gnome-shell-dark.css，已無舊版
#        gdm.css）。本腳本以桌面「即時」的 org.gnome.desktop.interface 值為準
#        （鍵集合固定為 INTERFACE_KEYS；讀不到工作階段時才退回 gnome/dconf.ini
#        快照），衍生出 greeter 的設定（color-scheme、accent、GTK/icon 主題、
#        字型、游標），因此登入畫面自動跟隨桌面。
#        **light 與 dark 兩個樣式檔都會修補**（各自嵌對應深/淺桌布），所以切換
#        深淺時不需要重建 gresource——登入畫面換 variant 就自動正確。
#        改完桌面設定後重跑本腳本即同步（非即時連動；just check 會提示未同步）。
#        light/dark css 也同時是桌面與鎖定畫面用的樣式檔，但我們對面板等只加在
#        greeter 專屬的 `.login-screen` class 上，且 #lockDialogGroup 在鎖定畫面
#        會被 UnlockDialog 自身的背景蓋住、在桌面工作階段不顯示，故不影響兩者。
#   3. 換桌布同步：背景預設自動讀取桌面的 picture-uri（淺）與 picture-uri-dark
#        （深），兩張都嵌進 gresource；換完桌布後重跑即同步。
#   4. greeter 以 gdm 使用者身分執行、只讀得到系統路徑，所以游標主題需要
#      一份系統層拷貝（~/.local 的 Bibata 在登入畫面會 fallback 成預設）。
#   5. 視覺覆寫（頂部面板、使用者清單的半透明玻璃感）抽成版控檔案
#      gnome/gdm-greeter.css，由本腳本附加進各樣式檔；該檔的 sha256
#      也納入重建判斷，改 CSS 後重跑即生效。覆寫一律限定 greeter 專屬選擇器
#      （#panel.login-screen、.login-dialog-*），故不影響桌面與鎖定畫面。
#      GNOME 不讓桌面的擴充（如 Blur my Shell，未宣告 session-modes: ["gdm"]）
#      在登入畫面載入，故以半透明近似真模糊。
#   6. dconf 檔分成兩份（產生檔與手寫檔分離，重跑時可精準比對）：
#        /etc/dconf/db/gdm.d/50-dotfiles-desktop-sync  ← 本腳本產生，鏡射桌面
#        /etc/dconf/db/gdm.d/90-dotfiles               ← gnome/gdm-dconf.ini
#                                                        （greeter 專屬設定）
#      兩份檔的鍵不重疊；dconf update 會把同一目錄的 keyfile 編譯成同一個 db。
#
# 需求：glib2-devel（glib-compile-resources）、glib2（gresource）、dconf。
#
# 用法:
#   sudo scripts/gdm-theme.sh                     # 套用（外觀 = 桌面）
#   sudo scripts/gdm-theme.sh --image /path.png   # 換背景（png/jpg/jxl 等 gdk-pixbuf 支援格式）
#   sudo scripts/gdm-theme.sh --no-restart        # 套用但不詢問重啟 GDM
#   sudo scripts/gdm-theme.sh --reset             # 還原原廠登入畫面
#
# 重啟 GDM 會強制登出所有工作階段；腳本結尾會詢問是否立即重啟。
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LIVE_GRESOURCE="/usr/share/gnome-shell/gnome-shell-theme.gresource"
STATE_DIR="/var/lib/dotfiles-gdm"
ORIG_GRESOURCE="$STATE_DIR/gnome-shell-theme.gresource.orig"
APPLIED_SHA_FILE="$STATE_DIR/applied.sha256"
IMAGE_SHA_FILE="$STATE_DIR/image.sha256"
CSS_SHA_FILE="$STATE_DIR/css.sha256"
WALLPAPER_URI_FILE="$STATE_DIR/source-uri"
CURSOR_MARKER="$STATE_DIR/cursor-installed"
GDM_DCONF_SRC="$REPO_DIR/gnome/gdm-dconf.ini"          # greeter-only extras → 90-dotfiles
DESKTOP_DCONF_SRC="$REPO_DIR/gnome/dconf.ini"          # 無工作階段時的後備值
GDM_DCONF_DEST="/etc/dconf/db/gdm.d/90-dotfiles"
SYNC_DCONF_DEST="/etc/dconf/db/gdm.d/50-dotfiles-desktop-sync"
DEFAULT_IMAGE_LIGHT="/usr/share/backgrounds/gnome/adwaita-l.jxl"
DEFAULT_IMAGE_DARK="/usr/share/backgrounds/gnome/adwaita-d.jxl"
GRESOURCE_PREFIX="/org/gnome/shell/theme"
CURSOR_NAME="Bibata-Modern-Ice"

# 視覺覆寫檔（版控檔案，附加進各樣式檔）
GREETER_CSS_SRC="$REPO_DIR/gnome/gdm-greeter.css"

# greeter 要鏡射桌面的 [org/gnome/desktop/interface] 鍵（固定清單，不由外部檔案決定）
INTERFACE_KEYS=(
    color-scheme
    accent-color
    gtk-theme
    icon-theme
    cursor-theme
    cursor-size
    font-name
    document-font-name
    monospace-font-name
    enable-animations
)

# 桌面即時的 color-scheme（prefer-light 才代表淺色；default 對 shell 等同深色）
COLOR_SCHEME=""
# 桌面工作階段的即時 org.gnome.desktop.interface 轉存（見 live_interface_dump）
LIVE_IFACE=""

MODE="apply"
IMAGE=""
IMAGE_EXPLICIT=false
NO_RESTART=false

usage() {
    echo "用法:"
    echo "  sudo $0                     # 套用（外觀 = 桌面：顏色/深淺/桌布同步）"
    echo "  sudo $0 --image /path.png   # 換登入背景圖（png/jpg/jxl 等）"
    echo "  sudo $0 --no-restart        # 套用但不詢問重啟 GDM"
    echo "  sudo $0 --reset             # 還原原廠登入畫面"
    echo ""
    echo "背景預設: 桌面的 picture-uri（淺）與 picture-uri-dark（深），兩張都嵌入；"
    echo "          讀不到時用 adwaita-l.jxl / adwaita-d.jxl"
}

info() { echo "==> $*"; }
warn() { echo "  [!] $*" >&2; }
die()  { echo "  [✗] $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image)
            [[ $# -ge 2 ]] || die "--image 需要一個路徑參數"
            IMAGE="$2"; IMAGE_EXPLICIT=true; shift 2 ;;
        --no-restart) NO_RESTART=true; shift ;;
        --reset)      MODE="reset"; shift ;;
        --help|-h)    usage; exit 0 ;;
        *)            echo "未知參數: $1" >&2; usage; exit 1 ;;
    esac
done

[[ "$(id -u)" -eq 0 ]] || die "需要 root 權限，請以: sudo $0 執行"

image_sha() { sha256sum "$1" | awk '{print $1}'; }

# 兩張桌布合併指紋（順序固定），用於判斷是否需要重建
image_pair_sha() { { image_sha "$1"; image_sha "$2"; } | sha256sum | awk '{print $1}'; }

decode_file_uri() {
    local uri="$1"
    uri="${uri#\'}"; uri="${uri%\'}"
    [[ "$uri" == file://* ]] || return 1
    if command -v python3 >/dev/null 2>&1; then
        python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1][7:]))' "$uri"
    else
        printf '%s\n' "${uri#file://}"
    fi
}

# 在 SUDO_USER 的工作階段裡執行 gsettings（輸出值；失敗回傳非 0）。
# 偶發的 D-Bus/dconf 喚醒失敗會讓輸出變空，故重試一次。
user_gsettings() {
    local user="${SUDO_USER:-}" uid out attempt
    [[ -n "$user" && "$user" != "root" ]] || return 1
    uid="$(id -u "$user" 2>/dev/null)" || return 1
    [[ -S "/run/user/$uid/bus" ]] || return 1
    for attempt in 1 2; do
        if out="$(sudo -u "$user" env \
                    XDG_RUNTIME_DIR="/run/user/$uid" \
                    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
                    gsettings "$@" 2>/dev/null)" && [[ -n "$out" ]]; then
            printf '%s\n' "$out"
            return 0
        fi
        if [[ "$attempt" == 1 ]]; then
            sleep 1
        fi
    done
    return 1
}

# 讀取桌面工作階段的 org.gnome.desktop.interface 全部鍵值
live_interface_dump() {
    user_gsettings list-recursively org.gnome.desktop.interface
}

# 從即時 dump 取單一鍵的值（含 gsettings 的引號，可直接寫進 dconf）
live_interface_value() {
    local key="$1"
    [[ -n "$LIVE_IFACE" ]] || return 1
    awk -v k="$key" '
        $1 == "org.gnome.desktop.interface" && $2 == k {
            sub(/^[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+/, "")
            print; exit
        }
    ' <<<"$LIVE_IFACE"
}

# 取 repo 快照 gnome/dconf.ini 的單一鍵值 —— 只在讀不到工作階段時當後備
repo_interface_value() {
    local key="$1"
    [[ -f "$DESKTOP_DCONF_SRC" ]] || return 1
    awk -v k="$key" '
        /^\[desktop\/interface\]/ { inside = 1; next }
        /^\[/                      { inside = 0 }
        inside && index($0, k "=") == 1 { sub(/^[^=]+=/, ""); print; exit }
    ' "$DESKTOP_DCONF_SRC"
}

# greeter 要鏡射的 [org/gnome/desktop/interface]：
#   鍵 = INTERFACE_KEYS（固定）；值 = 桌面「即時」值優先，取不到才用 repo 快照。
# 在 GNOME 設定按深/淺色或改 accent 後，重跑本腳本即同步（服務啟用時自動）。
desktop_interface_block() {
    local key val
    for key in "${INTERFACE_KEYS[@]}"; do
        val="$(live_interface_value "$key" || true)"
        if [[ -z "$val" ]]; then
            val="$(repo_interface_value "$key" || true)"
        fi
        if [[ -n "$val" ]]; then
            printf '%s=%s\n' "$key" "$val"
        fi
    done
}

# 桌面即時的 color-scheme（去掉引號）
desktop_color_scheme() {
    local v
    v="$(desktop_interface_block | sed -n "s/^color-scheme=//p" | head -n1)"
    v="${v#\'}"; v="${v%\'}"
    printf '%s\n' "$v"
}

# 讀取目標使用者工作階段的桌布（$1 = picture-uri / picture-uri-dark）；
# 成功時輸出兩行：解碼後的檔案路徑、原始 file:// URI
desktop_wallpaper_for() {
    local key="$1" uri path
    uri="$(user_gsettings get org.gnome.desktop.background "$key")" || return 1
    [[ -n "$uri" ]] || return 1
    path="$(decode_file_uri "$uri")" || return 1
    [[ -f "$path" ]] || return 1
    printf '%s\n%s\n' "$path" "$uri"
}

# 產生 50-dotfiles-desktop-sync：只含鏡射桌面的 [org/gnome/desktop/interface]
generate_sync_dconf() {
    local out="$1"
    {
        echo "# Managed by scripts/gdm-theme.sh — do not edit this file."
        echo "# Mirrors the live desktop session (org.gnome.desktop.interface);"
        echo "# greeter-only settings live in 90-dotfiles instead."
        echo "# Update: sudo just gdm-theme"
        echo
        echo "[org/gnome/desktop/interface]"
        desktop_interface_block
    } > "$out"
}

prompt_restart() {
    if [[ "$NO_RESTART" == true ]]; then
        info "變更已就緒，重啟 GDM 後生效: sudo systemctl restart gdm（會登出）"
        return
    fi
    if [[ -t 0 ]]; then
        local ans
        read -r -p "==> 現在重啟 GDM 讓變更生效？（會強制登出所有工作階段）[y/N] " ans
        if [[ "$ans" == [yY] ]]; then
            info "重啟 GDM..."
            systemctl restart gdm
        else
            info "稍後可執行: sudo systemctl restart gdm（或重新開機）"
        fi
    else
        info "非互動模式，請自行重啟 GDM: sudo systemctl restart gdm（會登出）"
    fi
}

install_cursor_theme() {
    local user="${SUDO_USER:-}" user_home=""
    if [[ -n "$user" && "$user" != "root" ]]; then
        user_home="$(getent passwd "$user" | cut -d: -f6)"
    fi
    if [[ -z "$user_home" || ! -d "$user_home/.local/share/icons/$CURSOR_NAME" ]]; then
        warn "找不到使用者層游標 $CURSOR_NAME，登入畫面游標維持預設"
        return 1
    fi
    if [[ -d "/usr/share/icons/$CURSOR_NAME" ]]; then
        # 已存在（舊版套用留下的副本）：內容與使用者層一致就補記號，確保 --reset 能還原
        if cmp -s "$user_home/.local/share/icons/$CURSOR_NAME/index.theme" \
                  "/usr/share/icons/$CURSOR_NAME/index.theme" 2>/dev/null; then
            [[ -f "$CURSOR_MARKER" ]] || touch "$CURSOR_MARKER"
        fi
        return 1
    fi
    info "複製游標 $CURSOR_NAME 到 /usr/share/icons（登入畫面游標與桌面一致）"
    cp -r "$user_home/.local/share/icons/$CURSOR_NAME" /usr/share/icons/
    touch "$CURSOR_MARKER"
    return 0
}

do_apply() {
    for cmd in gresource glib-compile-resources dconf sha256sum; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            if [[ "$cmd" == "glib-compile-resources" ]]; then
                die "缺少 $cmd，請先安裝: sudo dnf install glib2-devel"
            fi
            die "缺少 $cmd，請先安裝 glib2 與 dconf"
        fi
    done

    [[ -f "$LIVE_GRESOURCE" ]] || die "找不到 $LIVE_GRESOURCE"
    [[ -f "$GDM_DCONF_SRC" ]] || die "找不到 $GDM_DCONF_SRC"
    [[ -f "$DESKTOP_DCONF_SRC" ]] || die "找不到 $DESKTOP_DCONF_SRC"
    [[ -f "$GREETER_CSS_SRC" ]] || die "找不到 $GREETER_CSS_SRC"

    # 桌面「即時」外觀 → 決定桌布與 greeter 設定（顏色/深淺與桌面同步）
    LIVE_IFACE="$(live_interface_dump || true)"
    if [[ -z "$LIVE_IFACE" ]]; then
        warn "讀不到桌面工作階段（找不到使用者？），改用 repo 的 gnome/dconf.ini 快照"
    fi
    COLOR_SCHEME="$(desktop_color_scheme)"
    [[ -n "$COLOR_SCHEME" ]] || COLOR_SCHEME="prefer-dark"

    # 兩張桌布：淺色 picture-uri、深色 picture-uri-dark（讀不到就用預設）
    local light_image="$DEFAULT_IMAGE_LIGHT" dark_image="$DEFAULT_IMAGE_DARK"
    local light_uri="" dark_uri="" wall=""
    if [[ "$IMAGE_EXPLICIT" == true ]]; then
        light_image="$IMAGE"; dark_image="$IMAGE"
    else
        if wall="$(desktop_wallpaper_for picture-uri)"; then
            light_image="$(sed -n 1p <<<"$wall")"; light_uri="$(sed -n 2p <<<"$wall")"
        else
            warn "讀不到桌面淺色桌布，改用預設: $light_image"
        fi
        if wall="$(desktop_wallpaper_for picture-uri-dark)"; then
            dark_image="$(sed -n 1p <<<"$wall")"; dark_uri="$(sed -n 2p <<<"$wall")"
        else
            # 桌面沒設深色桌布時，GNOME 也用淺色那張
            dark_image="$light_image"; dark_uri="$light_uri"
        fi
        info "背景 = 桌面桌布（淺: ${light_image##*/} / 深: ${dark_image##*/}）"
    fi
    [[ -f "$light_image" ]] || die "背景圖不存在: $light_image"
    [[ -f "$dark_image" ]] || die "背景圖不存在: $dark_image"
    light_image="$(readlink -f "$light_image")"
    dark_image="$(readlink -f "$dark_image")"

    mkdir -p "$STATE_DIR"

    local changed=false
    local live_sha applied_sha cur_image_sha prev_image_sha cur_css_sha prev_css_sha
    live_sha="$(image_sha "$LIVE_GRESOURCE")"
    applied_sha="$(cat "$APPLIED_SHA_FILE" 2>/dev/null || true)"
    cur_image_sha="$(image_pair_sha "$light_image" "$dark_image")"
    prev_image_sha="$(cat "$IMAGE_SHA_FILE" 2>/dev/null || true)"
    cur_css_sha="$(image_sha "$GREETER_CSS_SRC")"
    prev_css_sha="$(cat "$CSS_SHA_FILE" 2>/dev/null || true)"

    # --- 1. 背景圖 + greeter CSS（重建 gresource；light/dark 兩個 variant 都補） ---
    if [[ "$live_sha" == "$applied_sha" && "$cur_image_sha" == "$prev_image_sha" \
          && "$cur_css_sha" == "$prev_css_sha" ]]; then
        info "登入背景與 greeter CSS 已是最新，略過重建"
        if [[ "$IMAGE_EXPLICIT" == false && -n "$light_uri$dark_uri" ]]; then
            printf '%s\n%s\n' "$light_uri" "$dark_uri" > "$WALLPAPER_URI_FILE"
        else
            rm -f "$WALLPAPER_URI_FILE"
        fi
    else
        if [[ "$live_sha" != "$applied_sha" ]]; then
            if grep -aq 'dotfiles-gdm-theme' "$LIVE_GRESOURCE"; then
                # 已修補但狀態檔不符（舊版狀態或曾中斷）：既有備份仍是原廠時直接以它重建，
                # 只有連備份都不可用才要求還原，避免不必要的重裝。
                if [[ -f "$ORIG_GRESOURCE" ]] && ! grep -aq 'dotfiles-gdm-theme' "$ORIG_GRESOURCE"; then
                    warn "現行 gresource 已修補但狀態檔不符，改用既有原廠備份重建（不重新備份）"
                else
                    die "現行 gresource 已含本腳本的修補記號，且沒有可用的原廠備份（$ORIG_GRESOURCE）；為避免重複疊加，請先還原原廠主題（sudo dnf reinstall -y gnome-shell）再重跑"
                fi
            else
                info "備份現行 gresource 作為重建基準（原版或 gnome-shell 更新後的新版）"
                cp -f "$LIVE_GRESOURCE" "$ORIG_GRESOURCE"
            fi
        elif [[ ! -f "$ORIG_GRESOURCE" ]]; then
            die "狀態不一致（缺少重建基準 $ORIG_GRESOURCE），請先還原 gresource 再重跑"
        fi

        local work
        work="$(mktemp -d /tmp/dotfiles-gdm.XXXXXX)"

        info "展開 gresource 基準..."
        local res rel
        while IFS= read -r res; do
            rel="${res#$GRESOURCE_PREFIX/}"
            mkdir -p "$work/theme/$(dirname "$rel")"
            gresource extract "$ORIG_GRESOURCE" "$res" > "$work/theme/$rel"
        done < <(gresource list "$ORIG_GRESOURCE")

        # 要修補的樣式檔：
        #   GNOME ≤ 49: gdm.css（單一樣式檔）
        #   GNOME 50 : gnome-shell-{light,dark,high-contrast}.css
        # light 與 dark 都補（各自嵌對應桌布），所以切換 color-scheme 不需重建。
        # #lockDialogGroup 在鎖定畫面會被 UnlockDialog 自己的背景蓋住、在桌面工作
        # 階段不顯示，故只影響 greeter。
        local css_files=()
        if [[ -f "$work/theme/gdm.css" ]]; then
            css_files=("$work/theme/gdm.css")
        else
            local v
            for v in light dark high-contrast; do
                if [[ -f "$work/theme/gnome-shell-$v.css" ]]; then
                    css_files+=("$work/theme/gnome-shell-$v.css")
                fi
            done
        fi
        if [[ ${#css_files[@]} -eq 0 ]]; then
            local found
            found="$(grep -rl -- '#lockDialogGroup' "$work/theme" | head -n1 || true)"
            [[ -n "$found" ]] || die "#lockDialogGroup 樣式未找到（gnome-shell 主題結構可能已變更）"
            warn "未預期的主題結構，改為修補: ${found#$work/theme/}"
            css_files=("$found")
        fi

        # 桌布資源：兩張相同時只嵌一份
        local bg_light bg_dark
        if [[ "$(image_sha "$light_image")" == "$(image_sha "$dark_image")" ]]; then
            bg_light="gdm-wallpaper.${light_image##*.}"
            bg_dark="$bg_light"
            cp -f "$light_image" "$work/theme/$bg_light"
        else
            bg_light="gdm-wallpaper-light.${light_image##*.}"
            bg_dark="gdm-wallpaper-dark.${dark_image##*.}"
            cp -f "$light_image" "$work/theme/$bg_light"
            cp -f "$dark_image" "$work/theme/$bg_dark"
        fi

        local css bg
        for css in "${css_files[@]}"; do
            case "$(basename "$css")" in
                gnome-shell-light.css) bg="$bg_light" ;;
                gnome-shell-dark.css)  bg="$bg_dark" ;;
                *) if [[ "$COLOR_SCHEME" == "prefer-light" ]]; then bg="$bg_light"; else bg="$bg_dark"; fi ;;
            esac
            cat >> "$css" <<EOF

/* dotfiles-gdm-theme: login background (rebuilt by scripts/gdm-theme.sh) */
#lockDialogGroup {
  background: url("resource://$GRESOURCE_PREFIX/$bg");
  background-size: cover;
  background-position: center;
}
EOF
            # 玻璃質感等視覺覆寫，抽成版控檔案（詳見 gnome/gdm-greeter.css 開頭說明）。
            # high-contrast 主題只換背景：半透明會破壞高對比的可讀性。
            if [[ "$(basename "$css")" != "gnome-shell-high-contrast.css" ]]; then
                cat "$GREETER_CSS_SRC" >> "$css"
            fi
        done

        info "重建 gresource..."
        (
            cd "$work/theme"
            {
                printf '<?xml version="1.0" encoding="UTF-8"?>\n<gresources>\n  <gresource prefix="%s">\n' "$GRESOURCE_PREFIX"
                find . -type f ! -name '*.gresource.xml' -printf '    <file>%P</file>\n' | LC_ALL=C sort
                printf '  </gresource>\n</gresources>\n'
            } > theme.gresource.xml
            glib-compile-resources --target="$work/out.gresource" theme.gresource.xml
        )

        # 覆寫既有檔（保留 inode → 保留 SELinux context 與權限）
        cp -f "$work/out.gresource" "$LIVE_GRESOURCE"
        rm -rf "$work"
        image_sha "$LIVE_GRESOURCE" > "$APPLIED_SHA_FILE"
        echo "$cur_image_sha" > "$IMAGE_SHA_FILE"
        echo "$cur_css_sha" > "$CSS_SHA_FILE"
        rm -f "$STATE_DIR/variant"    # 舊版殘留（現在兩個 variant 都補，不再需要）
        if [[ "$IMAGE_EXPLICIT" == false && -n "$light_uri$dark_uri" ]]; then
            printf '%s\n%s\n' "$light_uri" "$dark_uri" > "$WALLPAPER_URI_FILE"
        else
            rm -f "$WALLPAPER_URI_FILE"
        fi
        info "登入背景已套用（light/dark 皆已修補）"
        changed=true
    fi

    # --- 2. dconf：50-…（鏡射桌面，兩者都寫） ---
    local gen
    gen="$(mktemp)"
    generate_sync_dconf "$gen"
    if ! cmp -s "$gen" "$SYNC_DCONF_DEST" 2>/dev/null; then
        info "同步桌面外觀 → $SYNC_DCONF_DEST（$COLOR_SCHEME / accent / 主題 / 字型）"
        install -D -m 0644 "$gen" "$SYNC_DCONF_DEST"
        dconf update
        changed=true
    fi
    rm -f "$gen"

    # --- 2b. dconf：90-…（greeter 專屬設定） ---
    if ! cmp -s "$GDM_DCONF_SRC" "$GDM_DCONF_DEST" 2>/dev/null; then
        info "安裝 greeter 專屬設定 → $GDM_DCONF_DEST"
        install -D -m 0644 "$GDM_DCONF_SRC" "$GDM_DCONF_DEST"
        dconf update
        changed=true
    fi

    # --- 3. 系統層游標（greeter 讀不到 ~/.local） ---
    if install_cursor_theme; then
        changed=true
    fi

    if [[ "$changed" == false ]]; then
        info "全部已是最新，無需動作。"
        return
    fi
    prompt_restart
}

do_reset() {
    local changed=false
    local live_sha applied_sha
    live_sha="$(image_sha "$LIVE_GRESOURCE" 2>/dev/null || true)"
    applied_sha="$(cat "$APPLIED_SHA_FILE" 2>/dev/null || true)"

    if [[ -f "$ORIG_GRESOURCE" ]]; then
        if [[ "$live_sha" == "$applied_sha" ]]; then
            info "還原原廠 gresource..."
            cp -f "$ORIG_GRESOURCE" "$LIVE_GRESOURCE"
            changed=true
        else
            warn "gresource 已是原版（或已被更新覆蓋），不需還原"
        fi
    else
        warn "沒有備份基準，無 gresource 可還原（全新系統從未套用過？）"
    fi

    if [[ -f "$GDM_DCONF_DEST" || -f "$SYNC_DCONF_DEST" ]]; then
        info "移除 greeter dconf 設定（$GDM_DCONF_DEST / $SYNC_DCONF_DEST）"
        rm -f "$GDM_DCONF_DEST" "$SYNC_DCONF_DEST"
        command -v dconf >/dev/null 2>&1 && dconf update
        changed=true
    fi

    if [[ -f "$CURSOR_MARKER" ]]; then
        info "移除系統層游標 /usr/share/icons/$CURSOR_NAME"
        rm -rf "/usr/share/icons/$CURSOR_NAME"
        changed=true
    fi

    rm -rf "$STATE_DIR"

    if [[ "$changed" == false ]]; then
        info "沒有需要還原的項目。"
        return
    fi
    info "已還原原廠登入畫面。"
    prompt_restart
}

case "$MODE" in
    apply) do_apply ;;
    reset) do_reset ;;
esac
