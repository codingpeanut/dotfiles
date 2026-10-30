# Justfile - Declarative GNOME dotfiles & system manager
# Inspired by NixOS declarative workflow for Fedora

home := env("HOME")

default:
    @just --list

# One-click full sync: git pull + system packages + GNOME + dotfiles + user services
apply *args:
    @echo "==> Pulling latest changes from Git..."
    @git pull --rebase --autostash
    ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-become-pass {{ args }}
    @echo ""
    @echo "==> Done! If shell, theme or extensions changed, log out and back in (Wayland cannot restart GNOME Shell)."

# Sync and apply dotfiles symlinks via GNU Stow (through Ansible)
dotfiles *args:
    ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --tags dotfiles {{ args }}

# Run only system-level configuration (DNF packages, COPR repos, systemd services)
system *args:
    ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --tags system --ask-become-pass {{ args }}

# Run only user-level configuration (dotfiles, flatpaks, GNOME, user services)
user *args:
    ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --tags user {{ args }}

# ---------------------------------------------------------------------------
# GNOME desktop
# ---------------------------------------------------------------------------

# Full GNOME setup: extensions, themes, icons, cursor, fonts and dconf settings
gnome *args:
    ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --tags gnome {{ args }}

# Install / refresh only the declarative GNOME Shell extensions (gext)
gnome-ext *args:
    ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --tags gnome_ext {{ args }}

# Install / refresh only GNOME themes, icons, cursor and fonts
gnome-theme *args:
    ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --tags gnome_themes {{ args }}

# Apply only the dconf / gsettings configuration
gnome-settings *args:
    ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --tags gnome_settings {{ args }}

# Fast dconf apply without Ansible (loads gnome/dconf.ini into /org/gnome/)
gnome-apply:
    @echo "==> Loading gnome/dconf.ini into /org/gnome/ ..."
    @dconf load /org/gnome/ < gnome/dconf.ini
    @echo "==> Loading gnome/dconf-desktop.ini into /desktop/ ..."
    @dconf load /desktop/ < gnome/dconf-desktop.ini
    @echo "==> Syncing declarative extension state (gext)..."
    @disabled=$(cat gnome/extensions-disabled.txt 2>/dev/null | grep -vE '^[[:space:]]*(#|$)' | sort -u); \
     cat gnome/extensions.txt gnome/extensions-local.txt | grep -vE '^[[:space:]]*(#|$)' | while read -r uuid; do \
        if echo "$disabled" | grep -qx "$uuid"; then \
            gext disable "$uuid" 2>/dev/null || true; \
        else \
            gext enable "$uuid" 2>/dev/null || true; \
        fi; \
     done
    @echo "==> Done. Log out and back in to fully apply shell and theme changes."

# Workaround for known Blur My Shell bug: half-transparent panel after login
# (upstream issue aunetx/blur-my-shell#882). Toggling the extension fixes it.
gnome-fix-blur:
    @echo "==> Restarting Blur My Shell to fix the panel blur glitch..."
    @gnome-extensions disable blur-my-shell@aunetx 2>/dev/null || true
    @sleep 1
    @gnome-extensions enable blur-my-shell@aunetx 2>/dev/null || true
    @echo "==> Done. If the glitch returns after every login, see README (blur workaround)."

# 以桌面即時值鏡射 color-scheme（深/淺）、accent、GTK/icon 主題、字型、游標，
# 桌布 picture-uri / picture-uri-dark 兩張都嵌進 gresource，light/dark 樣式檔都修補
# （切換深淺不需重建）；gnome-shell 更新後 just update 會自動重跑。
# 參數會轉給腳本（例: just gdm-theme --image ~/Pictures/wall.png）。
# 套用 GDM 登入畫面主題（需 root；外觀與桌面同步）
gdm-theme *args:
    @echo "==> Applying GDM login screen theme (root required)..."
    @sudo bash scripts/gdm-theme.sh {{ args }}

# 還原原廠登入畫面（背景、字型、游標、dconf）
gdm-theme-reset:
    @echo "==> Restoring stock GDM login screen (root required)..."
    @sudo bash scripts/gdm-theme.sh --reset

# Capture the current GNOME settings from dconf back into the repo
gnome-backup:
    @echo "==> Backing up current /org/gnome/ settings to gnome/dconf.ini ..."
    @dconf dump /org/gnome/ | awk 'BEGIN { skip=0 } /^\[desktop\/background\]/ { skip=1; next } /^\[/ { skip=0 } !skip' > gnome/dconf.ini
    @sed -i '/^restore-keybinds=/d' gnome/dconf.ini
    @echo "==> Saved (wallpaper and PaperWM conflict-restore JSON filtered out). Review with 'git diff gnome/dconf.ini'."

# List installed GNOME extensions and their state
gnome-exts:
    @gext list

# Update all installed GNOME extensions to their latest version
gnome-update:
    @gext update --all

# Restart IBus cleanly (fixes stale daemon / no Chinese input in terminals)
im-reset:
    -ibus exit
    -pkill -x fcitx5
    -systemctl --user reset-failed org.freedesktop.IBus.session.GNOME.service
    systemctl --user start org.freedesktop.IBus.session.GNOME.service
    @sleep 2
    -ibus engine chewing
    @ibus engine || true

# Reset all GNOME settings to defaults and remove gext-managed extensions (destructive)
gnome-reset:
    @echo "WARNING: this resets ALL /org/gnome/ settings and removes gext-managed extensions."
    @ans=""; printf "Continue? [y/N] "; read ans; [ "$ans" = "y" ] || { echo "Aborted."; exit 0; }
    @dconf reset -f /org/gnome/
    @grep -vE '^[[:space:]]*(#|$)' gnome/extensions.txt | while read -r uuid; do gext uninstall "$uuid" 2>/dev/null || true; done
    @echo "==> GNOME reset complete. Log out and back in to apply."

# ---------------------------------------------------------------------------
# Dotfiles (GNU Stow)
# ---------------------------------------------------------------------------

# Fast direct Stow re-link for all packages (safe wrapper with auto-backup)
stow *args:
    @HOME="{{ home }}" bash scripts/stow.sh stow {{ args }}

# Dry-run of `just stow` (shows what would happen, changes nothing)
stow-dry *args:
    @HOME="{{ home }}" bash scripts/stow.sh stow --dry-run {{ args }}

# Remove Stow symlinks
unstow *args:
    @HOME="{{ home }}" bash scripts/stow.sh unstow {{ args }}

# ---------------------------------------------------------------------------
# Applications
# ---------------------------------------------------------------------------

# Install user Flatpak applications directly with live progress bar
flatpaks:
    @echo "==> Ensuring user Flathub remote is configured..."
    @flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    @flatpak remote-modify --user flathub --enable --no-filter
    @echo "==> Installing declarative user Flatpaks (live interactive progress bar)..."
    flatpak install --user -y flathub com.discordapp.Discord com.mattjakeman.ExtensionManager

# Accelerate Flathub downloads by switching to Asian mirror (SJTU)
mirror-flathub:
    @echo "==> Switching user Flathub to SJTU mirror (https://mirror.sjtu.edu.cn/flathub)..."
    flatpak remote-modify --user flathub --url=https://mirror.sjtu.edu.cn/flathub
    @echo "==> Switched to mirror. Run 'just flatpaks' to test speed."

# Reset user Flathub to official global CDN
reset-flathub:
    @echo "==> Resetting user Flathub to official global CDN..."
    flatpak remote-modify --user flathub --url=https://dl.flathub.org/repo
    @echo "==> Flathub reset to default."

# ---------------------------------------------------------------------------
# Maintenance
# ---------------------------------------------------------------------------

# Bootstrap a fresh Fedora workstation (installs git/ansible/just/stow, then applies)
bootstrap:
    @bash scripts/bootstrap.sh

# Install GNOME desktop dependencies directly (fallback when not using Ansible)
deps:
    @echo "==> Installing GNOME desktop dependencies..."
    sudo dnf install -y gnome-tweaks gnome-extensions-app dconf pipx python3-gobject sassc gtk-murrine-engine glib2 glib2-devel papirus-icon-theme rsms-inter-fonts nautilus file-roller bluez bluez-tools nm-connection-editor network-manager-applet NetworkManager-tui gnome-calendar gnome-control-center gnome-system-monitor pavucontrol playerctl wl-clipboard cliphist brightnessctl ddcutil libnotify cava starship zoxide fzf eza bat fastfetch nautilus fcitx5 fcitx5-chinese-addons fcitx5-chewing fcitx5-configtool fcitx5-gtk3 fcitx5-gtk4 fcitx5-qt5 fcitx5-qt6 google-noto-sans-cjk-fonts google-noto-serif-cjk-fonts google-noto-color-emoji-fonts jetbrains-mono-fonts
    sudo systemctl enable --now bluetooth || true
    @echo "==> Dependencies installed. Run 'just gnome' and 'just stow'."

# Check every declared item against the system: CLI deps, extensions, assets, Flatpaks
check:
    @echo "==> Checking GNOME desktop and CLI dependencies..."
    @for cmd in gnome-shell gnome-extensions dconf gsettings gext gnome-tweaks fc-cache sassc pipx ptyxis nvim starship fcitx5 nautilus fzf playerctl pavucontrol gnome-system-monitor opencode hermes; do \
        if command -v "$cmd" >/dev/null 2>&1; then \
            printf "  [✓] %-22s found (%s)\n" "$cmd" "$(command -v "$cmd")"; \
        else \
            printf "  [✗] %-22s NOT FOUND\n" "$cmd"; \
        fi \
    done
    @echo "==> GNOME extensions (declared vs desired state):"
    @declared=$(cat gnome/extensions.txt gnome/extensions-local.txt | grep -vE '^[[:space:]]*(#|$)' | sort -u); \
    disabled=$(cat gnome/extensions-disabled.txt 2>/dev/null | grep -vE '^[[:space:]]*(#|$)' | sort -u); \
    enabled=$(gnome-extensions list --enabled 2>/dev/null | sort -u); \
    ok=1; \
    for uuid in $declared; do \
        if echo "$disabled" | grep -qx "$uuid"; then \
            if echo "$enabled" | grep -qx "$uuid"; then \
                printf "  [✗] %s (disabled by default but currently enabled)\n" "$uuid"; ok=0; \
            else \
                printf "  [✓] %s (disabled by default)\n" "$uuid"; \
            fi; \
        elif echo "$enabled" | grep -qx "$uuid"; then \
            printf "  [✓] %s\n" "$uuid"; \
        else \
            printf "  [✗] %s (declared but NOT enabled)\n" "$uuid"; ok=0; \
        fi; \
    done; \
    for uuid in $enabled; do \
        echo "$declared" | grep -qx "$uuid" || printf "  [!] %s (enabled but not declared)\n" "$uuid"; \
    done; \
    if [ "$ok" = 1 ]; then echo "  ==> All declared extensions match the desired state."; else echo "  ==> Run 'just gnome-apply' to fix."; fi
    @echo "==> Desktop assets:"
    @if [ -d "{{ home }}/.local/share/themes/Colloid-Grey-Light" ] && [ -d "{{ home }}/.local/share/themes/Colloid-Grey-Dark" ]; then echo "  [✓] Colloid-Grey-Light / Dark themes installed"; else echo "  [✗] Colloid themes NOT installed (run: just gnome-theme)"; fi
    @if [ -d "{{ home }}/.local/share/icons/Bibata-Modern-Ice" ]; then echo "  [✓] Bibata-Modern-Ice cursor installed"; else echo "  [✗] Bibata-Modern-Ice cursor NOT installed"; fi
    @if [ -f "{{ home }}/.local/share/fonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf" ]; then echo "  [✓] JetBrainsMono Nerd Font installed"; else echo "  [✗] JetBrainsMono Nerd Font NOT installed"; fi
    @if fc-list 2>/dev/null | grep -qi Inter; then echo "  [✓] Inter font installed"; else echo "  [✗] Inter font NOT installed"; fi
    @if [ -d /usr/share/icons/Papirus-Light ] && [ -d /usr/share/icons/Papirus-Dark ]; then echo "  [✓] Papirus-Light / Dark icons installed"; else echo "  [✗] Papirus icons NOT installed"; fi
    @if rpm -q gnome-rounded-blur >/dev/null 2>&1; then echo "  [✓] gnome-rounded-blur helper installed (dynamic blur corners)"; else echo "  [✗] gnome-rounded-blur NOT installed (run: just system, then re-login)"; fi
    @if [ "$(systemctl --user show gnome-software.service -p Nice --value 2>/dev/null)" = "10" ] && [ "$(systemctl --user show gnome-software.service -p CPUWeight --value 2>/dev/null)" = "50" ]; then echo "  [✓] GNOME Software background priority tuned"; else echo "  [!] GNOME Software background priority NOT applied (run: just user)"; fi
    @if grep -aq 'dotfiles-gdm-theme' /usr/share/gnome-shell/gnome-shell-theme.gresource 2>/dev/null && { [ -f /etc/dconf/db/gdm.d/50-dotfiles-desktop-sync ] || [ -f /etc/dconf/db/gdm.d/90-dotfiles ]; }; then echo "  [✓] GDM login theme applied (desktop-matched wallpaper + greeter settings)"; else echo "  [!] GDM login theme NOT applied (run: just gdm-theme; re-run after gnome-shell updates)"; fi
    @if [ -f /var/lib/dotfiles-gdm/source-uri ] && command -v gsettings >/dev/null 2>&1; then \
        c_light="$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null)"; \
        c_dark="$(gsettings get org.gnome.desktop.background picture-uri-dark 2>/dev/null)"; \
        s_light="$(sed -n 1p /var/lib/dotfiles-gdm/source-uri 2>/dev/null)"; \
        s_dark="$(sed -n 2p /var/lib/dotfiles-gdm/source-uri 2>/dev/null)"; \
        if [ -n "$s_light" ] && [ -n "$c_light" ] && { [ "$c_light" != "$s_light" ] || [ "$c_dark" != "$s_dark" ]; }; then \
            echo "  [!] Desktop wallpaper changed — run 'just gdm-theme' to sync the login background"; \
        fi; \
    fi
    @if [ -f /etc/dconf/db/gdm.d/50-dotfiles-desktop-sync ]; then f=/etc/dconf/db/gdm.d/50-dotfiles-desktop-sync; else f=/etc/dconf/db/gdm.d/90-dotfiles; fi; \
     if [ -f "$f" ] && command -v gsettings >/dev/null 2>&1; then \
        live="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)"; \
        stored="$(sed -n 's/^color-scheme=//p' "$f" 2>/dev/null | head -n1)"; \
        if [ -n "$live" ] && [ -n "$stored" ] && [ "$live" != "$stored" ]; then \
            echo "  [!] Desktop colour scheme changed ($live) — run 'just gdm-theme' to sync the login screen"; \
        fi; \
    fi
    @if [ -f /var/lib/dotfiles-gdm/css.sha256 ] && [ -f gnome/gdm-greeter.css ]; then \
        cur="$(sha256sum gnome/gdm-greeter.css | awk '{print $1}')"; \
        stored="$(cat /var/lib/dotfiles-gdm/css.sha256 2>/dev/null)"; \
        if [ -n "$stored" ] && [ "$cur" != "$stored" ]; then \
            echo "  [!] Greeter CSS changed (gnome/gdm-greeter.css) — run 'just gdm-theme' to apply"; \
        fi; \
    fi
    @if [ -f "{{ home }}/.config/paperwm/user.css" ]; then echo "  [✓] PaperWM user.css deployed (selection border)"; else echo "  [✗] PaperWM user.css NOT deployed (run: just stow)"; fi
    @echo "==> Declared user Flatpaks:"
    @for app in com.discordapp.Discord com.mattjakeman.ExtensionManager; do \
        if flatpak info --user "$app" >/dev/null 2>&1; then \
            printf "  [✓] %s installed\n" "$app"; \
        else \
            printf "  [✗] %s NOT installed (run: just flatpaks)\n" "$app"; \
        fi \
    done

# Diagnose memory usage: top consumers, GNOME Shell footprint and enabled extensions
mem:
    @echo "==> Top memory consumers (RSS):"
    @ps -eo rss,comm --sort=-rss | awk 'NR>1 && NR<=16 {printf "  %7.0f MB  %s\n", $1/1024, $2}'
    @echo ""
    @echo "==> GNOME Shell (compositor + all extensions):"
    @ps -C gnome-shell -o rss=,%mem= | awk '{printf "  %7.0f MB  (%.1f%% of RAM)\n", $1/1024, $2}'
    @echo "    Hundreds of MB here, growing across logins? Test:"
    @echo "    gnome-extensions disable blur-my-shell@aunetx   (then log out and back in)"
    @echo ""
    @echo "==> Enabled GNOME extensions:"
    @(gnome-extensions list --enabled 2>/dev/null | sed 's/^/  [✓] /') || true
    @echo ""
    free -h

# Upgrade system packages and Flatpaks
update:
    sudo dnf upgrade -y
    @if command -v flatpak >/dev/null 2>&1; then \
        flatpak update -y; \
    fi
    @if [ -f /var/lib/dotfiles-gdm/applied.sha256 ]; then \
        echo "==> Refreshing GDM login theme (no-op unless gnome-shell was updated)..."; \
        sudo bash scripts/gdm-theme.sh --no-restart; \
    fi

# Check Git status
status:
    @echo "==> Git status:"
    @git status -s

# One-command sync: pull latest, auto-stow, and re-apply GNOME settings
pull:
    @echo "==> Pulling latest dotfiles from remote..."
    @git pull --rebase --autostash || (echo "==> Auto-resolving conflict with origin/main..." && git reset --hard origin/main)
    @just stow
    @just gnome-apply
    @echo "==> All dotfiles synced, stowed, and applied successfully!"

# Re-apply GNOME settings (Wayland: log out/in for shell and theme changes)
reload:
    @just gnome-apply

# One-stop command to fix everything: pull, install packages, stow and verify
fix:
    @echo "==> Pulling latest changes from Git..."
    @git pull --rebase --autostash || git reset --hard origin/main
    @just system
    @just stow
    @just gnome
    @just check
    @echo "==> All dotfiles, dependencies and GNOME settings have been fixed."

# One-command commit & push local changes to GitHub
push msg="chore: update dotfiles":
    @git add -A
    @git commit -m "{{ msg }}" || true
    @git push origin main
    @echo "==> Changes pushed to GitHub successfully."

# Quick-edit specific configuration files
edit target="gnome":
    @case "{{ target }}" in \
        gnome) ${EDITOR:-nvim} gnome/dconf.ini ;; \
        ext|extensions) ${EDITOR:-nvim} gnome/extensions.txt ;; \
        gtk) ${EDITOR:-nvim} stow/gnome/.config/gtk-4.0/gtk.css ;; \
        kitty) ${EDITOR:-nvim} stow/kitty/.config/kitty/kitty.conf ;; \
        fcitx5) ${EDITOR:-nvim} stow/fcitx5/.config/fcitx5/config && (fcitx5-remote -r 2>/dev/null || true) ;; \
        *) echo "Unknown target: {{ target }}. Available: gnome, ext, gtk, kitty, fcitx5" ;; \
    esac

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------

# Completely uninstall dotfiles from local system (unstow, restore backups, reset GNOME, remove binaries)
uninstall *args:
    @bash scripts/uninstall.sh {{ args }}

# Preview actions that will be performed during uninstallation (dry-run)
uninstall-dry:
    @bash scripts/uninstall.sh --dry-run

# Revert dotfiles symlinks, restore backups, reset GNOME settings and remove extensions
uninstall-dotfiles:
    @bash scripts/uninstall.sh --dotfiles

# Revert system-level packages and COPR repositories installed for this desktop (Fedora)
uninstall-system:
    @bash scripts/uninstall.sh --system

# Alias for uninstall
revert *args:
    @bash scripts/uninstall.sh {{ args }}
