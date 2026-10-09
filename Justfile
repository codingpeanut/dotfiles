# Justfile - Declarative dotfiles & system manager
# Architecture: GNU Stow + Tokyo Night Theme + Noctalia & Niri
# Target: Debian / Fedora

home := env("HOME")

default:
    @just --list

# Fast direct Stow re-link for all packages into $HOME
stow:
    @echo "==> Stowing all packages into {{ home }}..."
    @if [ -f "{{ home }}/.bashrc" ] && [ ! -L "{{ home }}/.bashrc" ]; then \
        echo "Backing up existing regular ~/.bashrc to ~/.bashrc.bak..."; \
        mv "{{ home }}/.bashrc" "{{ home }}/.bashrc.bak"; \
    fi
    @if [ ! -L "{{ home }}/.config/niri" ] && [ -f "{{ home }}/.config/niri/config.kdl" ] && [ ! -L "{{ home }}/.config/niri/config.kdl" ]; then \
        echo "Backing up existing regular ~/.config/niri/config.kdl to ~/.config/niri/config.kdl.bak..."; \
        mv "{{ home }}/.config/niri/config.kdl" "{{ home }}/.config/niri/config.kdl.bak"; \
    fi
    @if [ ! -L "{{ home }}/.config/noctalia" ] && [ -f "{{ home }}/.config/noctalia/config.toml" ] && [ ! -L "{{ home }}/.config/noctalia/config.toml" ]; then \
        echo "Backing up existing regular ~/.config/noctalia/config.toml to ~/.config/noctalia/config.toml.bak..."; \
        mv "{{ home }}/.config/noctalia/config.toml" "{{ home }}/.config/noctalia/config.toml.bak"; \
    fi
    @cd stow && for pkg in */; do \
        pkg_name="${pkg%/}"; \
        echo "Stowing $pkg_name..."; \
        stow -v -R -t "{{ home }}" "$pkg_name"; \
    done
    @echo "==> All packages stowed successfully!"

# Remove Stow symlinks
unstow:
    @echo "==> Unstowing all packages from {{ home }}..."
    @cd stow && for pkg in */; do \
        pkg_name="${pkg%/}"; \
        stow -v -D -t "{{ home }}" "$pkg_name"; \
    done

# Reload running desktop components (Niri, Noctalia, Fcitx5)
reload:
    @echo "==> Reloading Niri compositor configuration..."
    @(niri msg action reload-config 2>/dev/null || true)
    @echo "==> Restarting Noctalia shell..."
    @(killall noctalia 2>/dev/null || true)
    @sleep 0.3
    @(nohup noctalia >/dev/null 2>&1 &)
    @echo "==> Reloading Fcitx5 configuration..."
    @(fcitx5-remote -r 2>/dev/null || true)
    @echo "==> Desktop reloaded!"

# Install required desktop dependencies for Niri + Noctalia
deps:
    @echo "==> Installing system dependencies (Niri, Noctalia, Audio, Fonts)..."
    @if [ -f /etc/os-release ]; then \
        . /etc/os-release; \
        if [ "$ID" = "fedora" ]; then \
            echo "Detected Fedora system..."; \
            sudo dnf copr enable -y solopasha/hyprland || true; \
            sudo dnf copr enable -y zhangyi6324/noctalia-shell || true; \
            sudo dnf install -y --skip-unavailable \
                gcc gcc-c++ meson ninja-build cmake git curl wget pkgconf-pkg-config \
                wayland-devel wayland-protocols-devel libxkbcommon-devel pam-devel mesa-libgbm-devel \
                libinput-devel libseat-devel pipewire-devel wireplumber-devel sdbus-cpp-devel \
                tomlplusplus-devel libsecret-devel libsodium-devel kitty fcitx5 fcitx5-chewing \
                pipewire wireplumber brightnessctl grim slurp wl-clipboard cliphist nautilus \
                btop fuzzel swaybg wlsunset hyprlock hypridle keyd network-manager-applet blueman \
                pavucontrol google-noto-sans-cjk-vf-fonts google-noto-cjk-fonts jetbrains-mono-fonts stow; \
            if ! command -v powerprofilesctl >/dev/null 2>&1; then \
                sudo dnf install -y tuned-ppd 2>/dev/null || sudo dnf install -y power-profiles-daemon 2>/dev/null || true; \
            fi; \
        else \
            echo "Detected Debian/Ubuntu system..."; \
            sudo apt update; \
            sudo apt install -y \
                build-essential meson ninja-build cmake pkg-config git curl wget \
                libwayland-dev wayland-protocols libxkbcommon-dev libpam0g-dev libgbm-dev \
                libinput-dev libseat-dev libpipewire-0.3-dev libwireplumber-0.5-dev libsdbus-c++-dev \
                libtomlplusplus-dev libsecret-1-dev libsodium-dev kitty fcitx5 fcitx5-chewing \
                pipewire wireplumber pipewire-audio brightnessctl grim slurp wl-clipboard cliphist \
                nautilus btop fuzzel network-manager-gnome blueman pavucontrol swaybg wlsunset \
                hyprlock hypridle fonts-noto-cjk fonts-jetbrains-mono stow; \
        fi; \
    fi
    @just install-noctalia

# Install or compile Noctalia binary if missing
install-noctalia:
    @if ! command -v noctalia >/dev/null 2>&1; then \
        echo "==> Installing Noctalia desktop shell..."; \
        if command -v dnf >/dev/null 2>&1 && sudo dnf install -y noctalia 2>/dev/null; then \
            echo "==> Noctalia installed via DNF!"; \
        else \
            echo "==> Compiling Noctalia from source..."; \
            BUILD_DIR="/tmp/noctalia_build"; \
            rm -rf "$$BUILD_DIR"; \
            git clone --recursive https://github.com/noctalia-dev/noctalia.git "$$BUILD_DIR"; \
            cd "$$BUILD_DIR" && meson setup build --buildtype=release -Dprefix=/usr/local && ninja -C build && sudo ninja -C build install; \
            rm -rf "$$BUILD_DIR"; \
        fi; \
    else \
        echo "==> Noctalia is already installed: $$(which noctalia)"; \
    fi

# One-stop command to fix everything: pull, install dependencies, stow, reload
fix:
    @echo "==> Pulling latest changes from Git..."
    @git pull --rebase --autostash || git reset --hard origin/main
    @just deps
    @just stow
    @just reload
    @echo "==> All dotfiles, dependencies, and Noctalia have been updated and reloaded!"

# One-command commit & push local changes to GitHub
push msg="chore: update dotfiles":
    @git add -A
    @git commit -m "{{ msg }}" || true
    @git push origin main
    @echo "==> Changes pushed to GitHub successfully."

# Quick-edit specific configuration files
edit app="niri":
    @case "{{ app }}" in \
        niri) ${EDITOR:-nvim} stow/niri/.config/niri/config.kdl ;; \
        noctalia) ${EDITOR:-nvim} stow/noctalia/.config/noctalia/config.toml ;; \
        kitty) ${EDITOR:-nvim} stow/kitty/.config/kitty/kitty.conf ;; \
        hyprlock) ${EDITOR:-nvim} stow/hypr/.config/hypr/hyprlock.conf ;; \
        *) echo "Unknown app: {{ app }}" ;; \
    esac
