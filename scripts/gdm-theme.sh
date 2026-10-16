#!/usr/bin/env bash
# ==============================================================================
# gdm-theme.sh - GDM 登入畫面美化：淺色主題 + 桌面同款桌布（自動同步）
#
# 為什麼需要這個腳本？
#   1. GNOME 的 GDM 登入畫面（greeter）不會顯示桌布：背景是 shell 主題裡
#      #lockDialogGroup 的純色。要換成圖片，唯一乾淨的做法是重建
#      /usr/share/gnome-shell/gnome-shell-theme.gresource（把圖片嵌進去 +
#      覆寫背景樣式），再重啟 GDM。
#      → gnome-shell 套件更新會覆蓋這個檔；更新後重新執行本腳本即可
#        （以 sha256 判斷，未變更時完全 no-op，Justfile 的 just update 會自動重跑）。
#   2. GNOME 50 的 gresource 內只有 gnome-shell-{dark,light,high-contrast}.css
#      （已無舊版 gdm.css）；greeter 依 gdm profile 的 color-scheme 選檔：
#        prefer-light → gnome-shell-light.css（淺色登入畫面）
#        prefer-dark  → gnome-shell-dark.css
#      本腳本只在「淺色」樣式檔覆寫背景，因此使用者工作階段的鎖定畫面
#      （深色、同一組 css 的另一份）不受影響。設定檔
#      /etc/dconf/db/gdm.d/90-dotfiles 會宣告 color-scheme=prefer-light，
#      其餘可宣告式處理的部分（字型、游標、accent 色）也走 Fedora 官方支援的
#      /etc/dconf/db/gdm.d/（system-db:gdm），不受套件更新影響。
#   3. 換桌布同步：背景預設自動讀取使用者目前的「淺色桌布」
#      （org.gnome.desktop.background picture-uri）；換完桌布執行
#      just gdm-theme 即同步，just check 也會提示尚未同步。
#      若用 --image 明確指定就以此為準（不做同步提示）。
#   4. greeter 以 gdm 使用者身分執行、只讀得到系統路徑，所以游標主題需要
#      一份系統層拷貝（~/.local 的 Bibata 在登入畫面會 fallback 成預設）。
#
# 需求：glib2-devel（glib-compile-resources）、glib2（gresource）、dconf。
#
# 用法:
#   sudo scripts/gdm-theme.sh                     # 套用（背景 = 桌面的淺色桌布）
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
WALLPAPER_URI_FILE="$STATE_DIR/source-uri"
CURSOR_MARKER="$STATE_DIR/cursor-installed"
GDM_DCONF_SRC="$REPO_DIR/gnome/gdm-dconf.ini"
GDM_DCONF_DEST="/etc/dconf/db/gdm.d/90-dotfiles"
DEFAULT_IMAGE="/usr/share/backgrounds/gnome/adwaita-l.jxl"
GRESOURCE_PREFIX="/org/gnome/shell/theme"
LOGIN_CSS="gnome-shell-light.css"
CURSOR_NAME="Bibata-Modern-Ice"

MODE="apply"
IMAGE=""
IMAGE_EXPLICIT=false
NO_RESTART=false

usage() {
    echo "用法:"
    echo "  sudo $0                     # 套用（背景 = 桌面的淺色桌布）"
    echo "  sudo $0 --image /path.png   # 換登入背景圖（png/jpg/jxl 等）"
    echo "  sudo $0 --no-restart        # 套用但不詢問重啟 GDM"
    echo "  sudo $0 --reset             # 還原原廠登入畫面"
    echo ""
    echo "背景預設: 目前桌面的淺色桌布（picture-uri），讀不到時用 $DEFAULT_IMAGE"
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

# 讀取 SUDO_USER 目前工作階段的淺色桌布；成功時設定 LAST_WALLPAPER_URI
desktop_light_wallpaper() {
    local user="${SUDO_USER:-}"
    [[ -n "$user" && "$user" != "root" ]] || return 1
    local uid uri path
    uid="$(id -u "$user")"
    [[ -S "/run/user/$uid/bus" ]] || return 1
    uri="$(sudo -u "$user" env \
        XDG_RUNTIME_DIR="/run/user/$uid" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
        gsettings get org.gnome.desktop.background picture-uri 2>/dev/null)" || return 1
    [[ -n "$uri" ]] || return 1
    path="$(decode_file_uri "$uri")" || return 1
    [[ -f "$path" ]] || return 1
    LAST_WALLPAPER_URI="$uri"
    printf '%s\n' "$path"
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
    local user_home=""
    if [[ -n "${SUDO_USER:-}" ]] && [[ "${SUDO_USER}" != "root" ]]; then
        user_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    fi
    if [[ -z "$user_home" || ! -d "$user_home/.local/share/icons/$CURSOR_NAME" ]]; then
        warn "找不到使用者層游標 $CURSOR_NAME，登入畫面游標維持預設"
        return 1
    fi
    if [[ -d "/usr/share/icons/$CURSOR_NAME" ]]; then
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

    local source_uri=""
    if [[ "$IMAGE_EXPLICIT" == false ]]; then
        if IMAGE="$(desktop_light_wallpaper)"; then
            source_uri="$LAST_WALLPAPER_URI"
            info "背景 = 桌面淺色桌布: $IMAGE"
        else
            IMAGE="$DEFAULT_IMAGE"
            warn "讀不到桌面桌布（找不到使用者工作階段？），改用預設: $DEFAULT_IMAGE"
        fi
    fi
    [[ -f "$IMAGE" ]] || die "背景圖不存在: $IMAGE"
    IMAGE="$(readlink -f "$IMAGE")"

    mkdir -p "$STATE_DIR"

    local changed=false
    local live_sha applied_sha cur_image_sha prev_image_sha
    live_sha="$(image_sha "$LIVE_GRESOURCE")"
    applied_sha="$(cat "$APPLIED_SHA_FILE" 2>/dev/null || true)"
    cur_image_sha="$(image_sha "$IMAGE")"
    prev_image_sha="$(cat "$IMAGE_SHA_FILE" 2>/dev/null || true)"

    # --- 1. 背景圖（重建 gresource） ---
    if [[ "$live_sha" == "$applied_sha" && "$cur_image_sha" == "$prev_image_sha" ]]; then
        info "登入背景已是最新（$IMAGE），略過重建"
        if [[ -n "$source_uri" ]]; then
            [[ "$(cat "$WALLPAPER_URI_FILE" 2>/dev/null || true)" == "$source_uri" ]] \
                || printf '%s\n' "$source_uri" > "$WALLPAPER_URI_FILE"
        else
            rm -f "$WALLPAPER_URI_FILE"
        fi
    else
        if [[ "$live_sha" != "$applied_sha" ]]; then
            info "備份現行 gresource 作為重建基準（原版或 gnome-shell 更新後的新版）"
            cp -f "$LIVE_GRESOURCE" "$ORIG_GRESOURCE"
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

        # 選擇要覆寫背景的樣式檔：
        #   GNOME ≤ 49: gdm.css（單一樣式檔）
        #   GNOME 50 : greeter 依 gdm color-scheme 選 gnome-shell-{light,dark}.css；
        #              只補淺色檔，工作階段鎖定畫面（深色）不受影響。
        local css_files=()
        if [[ -f "$work/theme/gdm.css" ]]; then
            css_files=("$work/theme/gdm.css")
        elif [[ -f "$work/theme/$LOGIN_CSS" ]]; then
            css_files=("$work/theme/$LOGIN_CSS")
        else
            local found
            found="$(grep -rl -- '#lockDialogGroup' "$work/theme" | head -n1 || true)"
            [[ -n "$found" ]] || die "#lockDialogGroup 樣式未找到（gnome-shell 主題結構可能已變更）"
            warn "未預期的主題結構，改為修補: ${found#$work/theme/}"
            css_files=("$found")
        fi

        local bg_name="gdm-wallpaper.${IMAGE##*.}"
        cp -f "$IMAGE" "$work/theme/$bg_name"
        local css
        for css in "${css_files[@]}"; do
            cat >> "$css" <<EOF

/* dotfiles-gdm-theme: login background (rebuilt by scripts/gdm-theme.sh) */
#lockDialogGroup {
  background: url("resource://$GRESOURCE_PREFIX/$bg_name");
  background-size: cover;
  background-position: center;
}
EOF
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
        if [[ -n "$source_uri" ]]; then
            printf '%s\n' "$source_uri" > "$WALLPAPER_URI_FILE"
        else
            rm -f "$WALLPAPER_URI_FILE"
        fi
        info "登入背景已套用: $IMAGE"
        changed=true
    fi

    # --- 2. greeter dconf 設定（淺色/字型/游標/accent） ---
    if ! cmp -s "$GDM_DCONF_SRC" "$GDM_DCONF_DEST" 2>/dev/null; then
        info "安裝 greeter 設定 → $GDM_DCONF_DEST"
        install -D -m 0644 "$GDM_DCONF_SRC" "$GDM_DCONF_DEST"
        dconf update
        changed=true
    else
        info "greeter 設定已是最新（$GDM_DCONF_DEST）"
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

    if [[ -f "$GDM_DCONF_DEST" ]]; then
        info "移除 greeter 設定 $GDM_DCONF_DEST"
        rm -f "$GDM_DCONF_DEST"
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
