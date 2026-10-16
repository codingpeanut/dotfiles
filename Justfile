# Justfile - Declarative GNOME dotfiles & system manager
# Inspired by NixOS declarative workflow for Fedora

home := env("HOME")

default:
    @just --list

# Apply full configuration (system packages + GNOME + dotfiles + user services)
apply *args:
    ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-become-pass {{ args }}

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
    @echo "==> Enabling declarative extensions (gext)..."
    @grep -vE '^[[:space:]]*(#|$)' gnome/extensions.txt | while read -r uuid; do gext enable "$uuid" 2>/dev/null || true; done
    @echo "==> Done. Log out and back in to fully apply shell and theme changes."

# Capture the current GNOME settings from dconf back into the repo
gnome-backup:
    @echo "==> Backing up current /org/gnome/ settings to gnome/dconf.ini ..."
    @dconf dump /org/gnome/ > gnome/dconf.ini
    @echo "==> Saved. Review changes with 'git diff gnome/dconf.ini'."

# List installed GNOME extensions and their state
gnome-exts:
    @gext list

# Update all installed GNOME extensions to their latest version
gnome-update:
    @gext update --all

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

# Fast direct Stow re-link for all packages without running Ansible
stow:
    @echo "==> Stowing all packages into {{ home }}..."
    @if [ -f "{{ home }}/.bashrc" ] && [ ! -L "{{ home }}/.bashrc" ]; then \
        echo "Backing up existing regular ~/.bashrc to ~/.bashrc.bak..."; \
        mv "{{ home }}/.bashrc" "{{ home }}/.bashrc.bak"; \
    fi
    @if [ -f "{{ home }}/.vimrc" ] && [ ! -L "{{ home }}/.vimrc" ]; then \
        echo "Backing up existing regular ~/.vimrc to ~/.vimrc.bak..."; \
        mv "{{ home }}/.vimrc" "{{ home }}/.vimrc.bak"; \
    fi
    @cd stow && for pkg in */; do \
        pkg_name="${pkg%/}"; \
        echo "Stowing $pkg_name..."; \
        stow -v -R -t "{{ home }}" "$pkg_name"; \
    done

# Remove Stow symlinks
unstow:
    @echo "==> Unstowing all packages from {{ home }}..."
    @cd stow && for pkg in */; do \
        pkg_name="${pkg%/}"; \
        stow -v -D -t "{{ home }}" "$pkg_name"; \
    done

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
    sudo dnf install -y gnome-tweaks gnome-extensions-app dconf pipx python3-gobject sassc gtk-murrine-engine papirus-icon-theme bibata-cursor-theme rsms-inter-fonts nautilus file-roller blueman bluez bluez-tools nm-connection-editor network-manager-applet NetworkManager-tui gnome-calendar gnome-control-center pavucontrol playerctl wl-clipboard cliphist brightnessctl ddcutil libnotify cava btop starship zoxide fzf eza bat fastfetch nautilus fcitx5 fcitx5-chinese-addons fcitx5-chewing fcitx5-configtool fcitx5-gtk3 fcitx5-gtk4 fcitx5-qt5 fcitx5-qt6 google-noto-sans-cjk-fonts google-noto-serif-cjk-fonts google-noto-color-emoji-fonts jetbrains-mono-fonts
    sudo systemctl enable --now bluetooth || true
    @echo "==> Dependencies installed. Run 'just gnome' and 'just stow'."

# Check all GNOME, CLI and desktop dependencies
check:
    @echo "==> Checking GNOME desktop and CLI dependencies..."
    @for cmd in gnome-shell gnome-extensions dconf gsettings gext gnome-tweaks fc-cache sassc pipx kitty nvim starship fcitx5 nautilus btop fzf playerctl blueman-manager pavucontrol; do \
        if command -v "$cmd" >/dev/null 2>&1; then \
            printf "  [✓] %-22s found (%s)\n" "$cmd" "$(command -v "$cmd")"; \
        else \
            printf "  [✗] %-22s NOT FOUND\n" "$cmd"; \
        fi \
    done
    @echo "==> Enabled GNOME extensions:"
    @(gnome-extensions list --enabled 2>/dev/null | sed 's/^/  [✓] /') || true
    @if [ -d "{{ home }}/.local/share/themes/Colloid-Dark" ]; then echo "  [✓] Colloid-Dark theme installed"; else echo "  [✗] Colloid-Dark theme NOT installed"; fi

# Upgrade system packages and Flatpaks
update:
    sudo dnf upgrade -y
    @if command -v flatpak >/dev/null 2>&1; then \
        flatpak update -y; \
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
