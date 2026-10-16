#!/usr/bin/env bash
# ==============================================================================
# gdm-theme.sh - GDM 登入畫面美化：桌布同款背景 + 與桌面一致的介面設定
#
# 為什麼需要這個腳本？
#   1. GNOME 46+ 的 GDM 登入畫面（greeter）不會顯示桌布：背景是 shell 主題
#      gresource 裡定義的純色（#lockDialogGroup）。要換成圖片，唯一乾淨的
#      做法是重建 /usr/share/gnome-shell/gnome-shell-theme.gresource
#      （把圖片嵌進去 + 在 gdm.css 覆寫背景），再重啟 GDM。
#      → gnome-shell 套件更新會覆蓋這個檔；更新後重新執行本腳本即可
#        （以 sha256 判斷，未變更時完全 no-op，Justfile 的 just update 會自動重跑）。
#   2. 其餘可以宣告式處理的部分（深色模式、字型、游標、accent 色）走 Fedora
#      官方支援的 /etc/dconf/db/gdm.d/（system-db:gdm），不受套件更新影響。
#   3. greeter 以 gdm 使用者身分執行、只讀得到系統路徑，所以游標主題需要
#      一份系統層拷貝（~/.local 的 Bibata 在登入畫面會 fallback 成預設游標）。
#
# 需求：glib2-devel（glib-compile-resources）、glib2（gresource）、dconf。
#
# 用法:
#   sudo scripts/gdm-theme.sh                     # 套用（背景 = 與桌面相同的暗色桌布）
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
CURSOR_MARKER="$STATE_DIR/cursor-installed"
GDM_DCONF_SRC="$REPO_DIR/gnome/gdm-dconf.ini"
GDM_DCONF_DEST="/etc/dconf/db/gdm.d/90-dotfiles"
DEFAULT_IMAGE="/usr/share/backgrounds/gnome/adwaita-d.jxl"
GRESOURCE_PREFIX="/org/gnome/shell/theme"
CURSOR_NAME="Bibata-Modern-Ice"

MODE="apply"
IMAGE="$DEFAULT_IMAGE"
NO_RESTART=false

usage() {
    echo "用法:"
    echo "  sudo $0                     # 套用（背景 = 與桌面相同的暗色桌布）"
    echo "  sudo $0 --image /path.png   # 換登入背景圖（png/jpg/jxl 等）"
    echo "  sudo $0 --no-restart        # 套用但不詢問重啟 GDM"
    echo "  sudo $0 --reset             # 還原原廠登入畫面"
    echo ""
    echo "背景預設: $DEFAULT_IMAGE"
}

info() { echo "==> $*"; }
warn() { echo "  [!] $*" >&2; }
die()  { echo "  [✗] $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image)
            [[ $# -ge 2 ]] || die "--image 需要一個路徑參數"
            IMAGE="$2"; shift 2 ;;
        --no-restart) NO_RESTART=true; shift ;;
        --reset)      MODE="reset"; shift ;;
        --help|-h)    usage; exit 0 ;;
        *)            echo "未知參數: $1" >&2; usage; exit 1 ;;
    esac
done

[[ "$(id -u)" -eq 0 ]] || die "需要 root 權限，請以: sudo $0 執行"

image_sha() { sha256sum "$1" | awk '{print $1}'; }

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
    [[ -f "$IMAGE" ]] || die "背景圖不存在: $IMAGE"
    IMAGE="$(readlink -f "$IMAGE")"
    [[ -f "$GDM_DCONF_SRC" ]] || die "找不到 $GDM_DCONF_SRC"

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

        local css="$work/theme/gdm.css"
        if [[ ! -f "$css" ]]; then
            css="$(grep -rl -- '#lockDialogGroup' "$work/theme" | head -n1 || true)"
            [[ -n "$css" ]] || die "#lockDialogGroup 樣式未找到（gnome-shell 主題結構可能已變更）"
            warn "未找到 gdm.css，改為修補: ${css#$work/theme/}"
        fi

        local bg_name="gdm-wallpaper.${IMAGE##*.}"
        cp -f "$IMAGE" "$work/theme/$bg_name"
        cat >> "$css" <<EOF

/* dotfiles-gdm-theme: login background (rebuilt by scripts/gdm-theme.sh) */
#lockDialogGroup {
  background: url("resource://$GRESOURCE_PREFIX/$bg_name");
  background-size: cover;
  background-position: center;
}
EOF

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
        info "登入背景已套用: $IMAGE"
        changed=true
    fi

    # --- 2. greeter dconf 設定（字型/游標/accent/深色） ---
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
