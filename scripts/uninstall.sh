#!/usr/bin/env bash
# ==============================================================================
# uninstall.sh - Safely uninstall and revert declarative dotfiles from local system
# ==============================================================================
set -eo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_HOME="${HOME}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

MODE="dotfiles"
DRY_RUN=false
FORCE=false

print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "=========================================================="
    echo "  Declarative Dotfiles - System Uninstaller"
    echo "=========================================================="
    echo -e "${NC}"
}

usage() {
    echo -e "使用方式: $0 [選項]"
    echo ""
    echo "選項:"
    echo "  --dotfiles, -d   僅還原 dotfiles 軟連結、恢復原始備份與停止桌面服務 (預設)"
    echo "  --system, -s     僅移除桌面專用套件與停用 COPR 軟體庫 (Fedora)"
    echo "  --all, -a        完整移除：還原 dotfiles + 移除系統套件與 COPR 來源"
    echo "  --dry-run, -n    預覽模式：僅顯示將執行的動作，不實際修改任何檔案"
    echo "  --force, -f      強制執行：不要求互動確認"
    echo "  --help, -h       顯示此說明訊息"
    echo ""
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dotfiles|-d)
            MODE="dotfiles"
            shift
            ;;
        --system|-s)
            MODE="system"
            shift
            ;;
        --all|-a)
            MODE="all"
            shift
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}未知參數: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

print_banner

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[!] 正在以預覽模式 (DRY-RUN) 執行，不會實際變更系統。${NC}\n"
fi

confirm_action() {
    local msg="$1"
    if [ "$FORCE" = true ] || [ "$DRY_RUN" = true ]; then
        return 0
    fi
    echo -en "${YELLOW}${BOLD}${msg} (y/N): ${NC}"
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            echo -e "${RED}已取消操作。${NC}"
            exit 0
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 1. 停止桌面外殼與使用者層級服務
# ------------------------------------------------------------------------------
stop_services() {
    echo -e "${BLUE}==> [1/5] 檢查並停止桌面服務與背景行程...${NC}"

    if [ "$DRY_RUN" = true ]; then
        echo "  [dry-run] 將停止 systemd user 服務: noctalia, waybar"
        echo "  [dry-run] 將終止行程: quickshell, qs, noctalia, waybar, mako, fcitx5-watcher"
        return 0
    fi

    # 停止與停用 systemd user services
    if command -v systemctl >/dev/null 2>&1; then
        for svc in noctalia waybar; do
            if systemctl --user is-enabled "$svc" >/dev/null 2>&1 || systemctl --user is-active "$svc" >/dev/null 2>&1; then
                echo "  [-] 停止並停用 systemd 服務: $svc"
                systemctl --user stop "$svc" 2>/dev/null || true
                systemctl --user disable "$svc" 2>/dev/null || true
            fi
        done
        systemctl --user daemon-reload 2>/dev/null || true
    fi

    # 終止桌面元件行程
    for proc in quickshell qs noctalia waybar mako fcitx5-watcher desktop-shell; do
        if pgrep -x "$proc" >/dev/null 2>&1; then
            echo "  [-] 終止背景行程: $proc"
            killall "$proc" 2>/dev/null || true
        fi
    done

    echo -e "${GREEN}  [✓] 桌面服務與行程已清理完畢。${NC}"
}

# ------------------------------------------------------------------------------
# 2. 解除 GNU Stow 軟連結與清理殘留 Link
# ------------------------------------------------------------------------------
remove_symlinks() {
    echo -e "${BLUE}==> [2/5] 解除所有 dotfiles 軟連結 (Unstow)...${NC}"

    # 若有 stow 指令，先執行正規 unstow
    if command -v stow >/dev/null 2>&1 && [ -d "$DOTFILES_DIR/stow" ]; then
        echo "  [-] 呼叫 GNU Stow 解除模組..."
        cd "$DOTFILES_DIR/stow"
        for pkg in */; do
            pkg_name="${pkg%/}"
            if [ "$DRY_RUN" = true ]; then
                echo "  [dry-run] stow -D -t $TARGET_HOME $pkg_name"
            else
                stow -v -D -t "$TARGET_HOME" "$pkg_name" 2>/dev/null || true
            fi
        done
        cd "$DOTFILES_DIR"
    fi

    # 安全機制：遍歷使用者家目錄中可能指向本 dotfiles 專案的軟連結並強制移除
    echo "  [-] 檢查並清除指向此專案目錄的剩餘軟連結..."
    
    # 檢查根目錄檔案
    local root_files=(".bashrc" ".vimrc" ".bash_profile" ".profile")
    for rf in "${root_files[@]}"; do
        local target_path="$TARGET_HOME/$rf"
        if [ -L "$target_path" ]; then
            local dest
            dest="$(readlink -f "$target_path" 2>/dev/null || true)"
            if [[ "$dest" == "$DOTFILES_DIR"* ]]; then
                if [ "$DRY_RUN" = true ]; then
                    echo "  [dry-run] 移除軟連結: $target_path -> $dest"
                else
                    echo "  [-] 移除軟連結: $target_path"
                    rm -f "$target_path"
                fi
            fi
        fi
    done

    # 檢查 ~/.config 與 ~/.local/bin 中的軟連結
    local search_dirs=("$TARGET_HOME/.config" "$TARGET_HOME/.local/bin" "$TARGET_HOME/.config/autostart" "$TARGET_HOME/.config/systemd/user")
    for sdir in "${search_dirs[@]}"; do
        if [ -d "$sdir" ]; then
            # 尋找第一層與第二層軟連結
            while IFS= read -r link; do
                if [ -L "$link" ]; then
                    local dest
                    dest="$(readlink -f "$link" 2>/dev/null || true)"
                    if [[ "$dest" == "$DOTFILES_DIR"* ]]; then
                        if [ "$DRY_RUN" = true ]; then
                            echo "  [dry-run] 移除軟連結: $link -> $dest"
                        else
                            echo "  [-] 移除軟連結: $link"
                            rm -f "$link"
                        fi
                    fi
                fi
            done < <(find "$sdir" -maxdepth 3 -type l 2>/dev/null)
        fi
    done

    echo -e "${GREEN}  [✓] 軟連結已成功解除。${NC}"
}

# ------------------------------------------------------------------------------
# 3. 還原原本備份的設定檔 (.bak)
# ------------------------------------------------------------------------------
restore_backups() {
    echo -e "${BLUE}==> [3/5] 檢查並還原原本系統備份檔案 (.bak)...${NC}"

    local backups=(
        "$TARGET_HOME/.bashrc.bak:$TARGET_HOME/.bashrc"
        "$TARGET_HOME/.vimrc.bak:$TARGET_HOME/.vimrc"
        "$TARGET_HOME/.config/niri/config.kdl.bak:$TARGET_HOME/.config/niri/config.kdl"
        "$TARGET_HOME/.config/fcitx5.bak:$TARGET_HOME/.config/fcitx5"
    )

    for item in "${backups[@]}"; do
        local src="${item%%:*}"
        local dst="${item##*:}"

        if [ -e "$src" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "  [dry-run] 還原備份: $src -> $dst"
            else
                echo "  [+] 還原備份: $src -> $dst"
                # 若目標仍為軟連結，先移除
                [ -L "$dst" ] && rm -f "$dst"
                mv "$src" "$dst"
            fi
        fi
    done

    # 若 ~/.bashrc 遺失且無備份，嘗試從 /etc/skel/.bashrc 還原
    if [ ! -f "$TARGET_HOME/.bashrc" ] && [ -f "/etc/skel/.bashrc" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] 從 /etc/skel/.bashrc 建立預設 ~/.bashrc"
        else
            echo "  [+] 未檢測到 ~/.bashrc 備份，正在從 /etc/skel/.bashrc 復原預設值..."
            cp /etc/skel/.bashrc "$TARGET_HOME/.bashrc"
        fi
    fi

    echo -e "${GREEN}  [✓] 原始備份已還原。${NC}"
}

# ------------------------------------------------------------------------------
# 4. 清理本套件專用生成的二進位檔與快取目錄
# ------------------------------------------------------------------------------
cleanup_artifacts() {
    echo -e "${BLUE}==> [4/5] 清理專用二進位檔與下載項目...${NC}"

    local items_to_clean=(
        "$TARGET_HOME/.local/bin/nmgui"
        "$TARGET_HOME/.config/autostart/noctalia.desktop"
        "$TARGET_HOME/.config/autostart/waybar.desktop"
        "$TARGET_HOME/.config/quickshell/niri-caelestia-shell"
    )

    for path in "${items_to_clean[@]}"; do
        if [ -e "$path" ] || [ -L "$path" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "  [dry-run] 移除檔案/目錄: $path"
            else
                echo "  [-] 移除: $path"
                rm -rf "$path"
            fi
        fi
    done

    # 清理殘留的空目錄 (若為空才刪除)
    local empty_dirs=(
        "$TARGET_HOME/.config/noctalia"
        "$TARGET_HOME/.config/quickshell"
        "$TARGET_HOME/.config/wlogout"
    )
    for ed in "${empty_dirs[@]}"; do
        if [ -d "$ed" ] && [ -z "$(ls -A "$ed" 2>/dev/null)" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "  [dry-run] 移除空白設定資料夾: $ed"
            else
                rmdir "$ed" 2>/dev/null || true
            fi
        fi
    done

    echo -e "${GREEN}  [✓] 專用檔案清理完畢。${NC}"
}

# ------------------------------------------------------------------------------
# 5. 系統層級移除 (Fedora RPMs, COPR 與 Flatpaks)
# ------------------------------------------------------------------------------
remove_system_packages() {
    echo -e "${BLUE}==> [5/5] 系統套件與 COPR 軟體庫清理...${NC}"

    if ! command -v dnf >/dev/null 2>&1; then
        echo -e "${YELLOW}  [i] 非 Fedora/DNF 系統，跳過 DNF 套件清理。${NC}"
        return 0
    fi

    local rice_pkgs=("noctalia" "quickshell" "cava")
    local copr_repos=("zhangyi6324/noctalia-shell" "errornointernet/quickshell" "celestelove/libcava")

    if [ "$DRY_RUN" = true ]; then
        echo "  [dry-run] 將停用 COPR: ${copr_repos[*]}"
        echo "  [dry-run] 將移除專用 RPM 套件: ${rice_pkgs[*]}"
        return 0
    fi

    echo -e "${YELLOW}即將清理本專案安裝之桌面外殼套件 (noctalia, quickshell, cava) 與對應 COPR。${NC}"
    echo -e "${YELLOW}注意：共用工具 (如 git, niri, kitty, fcitx5, neovim) 將會保留以確保系統正常運作。${NC}"
    
    if confirm_action "是否繼續移除桌面外殼 RPM 套件與停用 COPR？"; then
        echo "  [-] 移除 RPM 套件: ${rice_pkgs[*]}..."
        sudo dnf remove -y "${rice_pkgs[@]}" 2>/dev/null || true

        echo "  [-] 停用專用 COPR 軟體庫..."
        for repo in "${copr_repos[@]}"; do
            sudo dnf copr disable -y "$repo" 2>/dev/null || true
        done
        echo -e "${GREEN}  [✓] 系統專用套件與 COPR 來源已移除。${NC}"
    fi

    # 詢問是否移除 Flatpak Discord (若由 just flatpaks 安裝)
    if command -v flatpak >/dev/null 2>&1; then
        if flatpak list --user 2>/dev/null | grep -q "com.discordapp.Discord"; then
            if confirm_action "檢測到經由本專案安裝的使用者 Flatpak Discord，是否一併移除？"; then
                echo "  [-] 移除 Flatpak: com.discordapp.Discord..."
                flatpak uninstall --user -y com.discordapp.Discord 2>/dev/null || true
            fi
        fi
    fi
}

# ------------------------------------------------------------------------------
# Main Flow
# ------------------------------------------------------------------------------
case "$MODE" in
    dotfiles)
        confirm_action "即將在本地電腦解除 dotfiles 軟連結、還原備份設定並停止桌面外殼服務。是否確認執行？"
        stop_services
        remove_symlinks
        restore_backups
        cleanup_artifacts
        echo ""
        echo -e "${GREEN}${BOLD}==========================================================${NC}"
        echo -e "${GREEN}${BOLD}  Dotfiles 已成功完全復原與解除！${NC}"
        echo -e "${GREEN}${BOLD}  原始設定與備份檔案已還原回 \$HOME。${NC}"
        echo -e "${GREEN}${BOLD}==========================================================${NC}"
        ;;
    system)
        confirm_action "即將移除桌面外殼相關之 RPM 套件與停用 COPR 來源。是否確認執行？"
        remove_system_packages
        echo ""
        echo -e "${GREEN}${BOLD}==========================================================${NC}"
        echo -e "${GREEN}${BOLD}  系統層級桌面套件與 COPR 軟體庫已清理完成！${NC}"
        echo -e "${GREEN}${BOLD}==========================================================${NC}"
        ;;
    all)
        confirm_action "即將在本地電腦完全捨棄並移除此套件的所有設定、軟連結與專屬系統套件。是否確認執行？"
        stop_services
        remove_symlinks
        restore_backups
        cleanup_artifacts
        remove_system_packages
        echo ""
        echo -e "${GREEN}${BOLD}==========================================================${NC}"
        echo -e "${GREEN}${BOLD}  本套件已完全從本地電腦捨棄並解除安裝完畢！${NC}"
        echo -e "${GREEN}${BOLD}==========================================================${NC}"
        ;;
esac
