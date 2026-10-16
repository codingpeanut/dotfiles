#!/usr/bin/env bash
# ==============================================================================
# stow.sh - Safe GNU Stow wrapper with automatic conflict resolution
#
# 為什麼需要這個腳本？
#   1. 舊版 just stow 的備份邏輯會在「父目錄是指向 repo 的軟連結」時，透過
#      軟連結把 repo 內真正的設定檔改名成 .bak，導致設定遺失（例如 niri
#      找不到 config.kdl）。
#   2. 切換 repo / 換 clone 時，$HOME 中殘留指向舊路徑的軟連結會讓 stow
#      直接衝突失敗，錯誤訊息也不容易理解。
#
# Pre-flight 掃描規則（stow 模式）：
#   - 目標路徑本身是「指向其他位置」的軟連結   -> 備份為 *.bak
#   - 目標路徑是既有實體檔案                   -> 備份為 *.bak
#   - 目標路徑的父目錄是外部軟連結             -> 備份該目錄軟連結本身
#     （絕不透過軟連結去更動其他 repo 的檔案）
#   備份命名為 <path>.bak，若已存在則遞增為 <path>.bak.1、.bak.2 ...
#
# 用法:
#   scripts/stow.sh stow   [pkg ...] [--dry-run]
#   scripts/stow.sh unstow [pkg ...] [--dry-run]
#   未指定 pkg 時，處理 stow/ 下的所有套件。
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW_DIR="$DOTFILES_DIR/stow"
TARGET="${HOME}"

MODE="stow"
DRY_RUN=false
PKGS=()

usage() {
    echo "使用方式: $0 [stow|unstow] [pkg ...] [--dry-run]"
    echo ""
    echo "  stow      部署 stow/ 內所有（或指定）套件到 \$HOME（預設）"
    echo "  unstow    移除 stow/ 內所有（或指定）套件的軟連結"
    echo "  --dry-run 僅顯示將執行的動作，不實際變更"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        stow|unstow)
            MODE="$1"
            shift
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            PKGS+=("$1")
            shift
            ;;
    esac
done

if [ "${#PKGS[@]}" -eq 0 ]; then
    for d in "$STOW_DIR"/*/; do
        [ -d "$d" ] || continue
        PKGS+=("$(basename "$d")")
    done
fi

if [ "${#PKGS[@]}" -eq 0 ]; then
    echo "找不到任何 stow 套件（$STOW_DIR 為空？）" >&2
    exit 1
fi

echo "=========================================================="
echo "  GNU Stow (safe wrapper) - mode: $MODE"
[ "$DRY_RUN" = true ] && echo "  [!] DRY-RUN 模式：不會實際變更任何檔案"
echo "=========================================================="

is_in_repo() {
    [[ "$1" == "$DOTFILES_DIR"/* ]]
}

backup_path() {
    local p="$1" dest i=1 parent_real
    parent_real="$(readlink -f -- "$(dirname "$p")" 2>/dev/null || true)"
    if is_in_repo "$parent_real"; then
        echo "  [✗] 安全防護：拒絕透過軟連結備份 repo 內檔案: $p" >&2
        return 1
    fi
    dest="$p.bak"
    while [ -e "$dest" ] || [ -L "$dest" ]; do
        dest="$p.bak.$i"
        i=$((i + 1))
    done
    if [ "$DRY_RUN" = true ]; then
        echo "  [dry-run] 備份: $p -> $dest"
    else
        mv -- "$p" "$dest"
        echo "  [+] 已備份: $p -> $dest"
    fi
}

# 掃描單一套件對應到 $HOME 的所有路徑，處理衝突
preflight_package() {
    local pkg="$1" src rel full cur res i parts n
    while IFS= read -r -d '' src; do
        rel="${src#"$STOW_DIR/$pkg/"}"
        full="$TARGET/$rel"

        # 1) 由上而下檢查父目錄是否為外部軟連結
        #    若是，備份「軟連結本身」，絕不深入其中更動檔案
        IFS='/' read -r -a parts <<< "$rel"
        n=${#parts[@]}
        cur="$TARGET"
        for ((i = 0; i < n - 1; i++)); do
            cur="$cur/${parts[i]}"
            if [ -L "$cur" ]; then
                res="$(readlink -f -- "$cur" 2>/dev/null || true)"
                if ! is_in_repo "$res"; then
                    echo "  [!] 外部軟連結目錄: $cur -> ${res:-<失效連結>}"
                    backup_path "$cur"
                fi
            fi
        done

        # 2) 檢查葉節點本身
        if [ -L "$full" ]; then
            res="$(readlink -f -- "$full" 2>/dev/null || true)"
            if ! is_in_repo "$res"; then
                echo "  [!] 外部軟連結: $full -> ${res:-<失效連結>}"
                backup_path "$full"
            fi
        elif [ -e "$full" ] && [ ! -d "$full" ]; then
            # 可能是經由 stow fold 軟連結抵達的 repo 檔案，先解析實體路徑
            res="$(readlink -f -- "$full" 2>/dev/null || true)"
            if ! is_in_repo "$res"; then
                echo "  [!] 既有實體檔案: $full"
                backup_path "$full"
            fi
        fi
    done < <(find "$STOW_DIR/$pkg" -mindepth 1 ! -type d -print0)
}

FAILED=0

for pkg in "${PKGS[@]}"; do
    if [ ! -d "$STOW_DIR/$pkg" ]; then
        echo "  [✗] 找不到 stow 套件: $pkg"
        FAILED=1
        continue
    fi

    if [ "$MODE" = "stow" ]; then
        echo "==> [$pkg] pre-flight 衝突檢查..."
        preflight_package "$pkg"
        echo "==> [$pkg] stow -R ..."
        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] stow -v -R -t $TARGET -d $STOW_DIR $pkg"
        elif ! stow -v -R -t "$TARGET" -d "$STOW_DIR" "$pkg"; then
            echo "  [✗] stow 失敗: $pkg"
            FAILED=1
        fi
    else
        echo "==> [$pkg] unstow ..."
        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] stow -v -D -t $TARGET -d $STOW_DIR $pkg"
        elif ! stow -v -D -t "$TARGET" -d "$STOW_DIR" "$pkg"; then
            echo "  [✗] unstow 失敗: $pkg"
            FAILED=1
        fi
    fi
done

if [ "$FAILED" -eq 0 ]; then
    echo "==> 完成（衝突檔案皆已備份為 *.bak，可自行確認後刪除）。"
else
    echo "==> 有部分套件失敗，請檢查上方訊息。" >&2
fi
exit "$FAILED"
