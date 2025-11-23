#!/usr/bin/env bash
set -euo pipefail

echo "[*] Setting up GNOME extensions..."

# --- Ensure dependencies ---
for cmd in flatpak curl jq unzip gnome-extensions git make; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[!] Required command '$cmd' is missing. Please install it first."
        exit 1
    fi
done

# --- Add Flathub as a Flatpak remote ---
flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo

# --- Install GNOME Extensions Manager ---
if ! flatpak list --user | grep -qi com.mattjakeman.ExtensionManager; then
    echo "[*] Installing GNOME Extensions Manager..."
    flatpak install -y --user flathub com.mattjakeman.ExtensionManager
else
    echo "[*] GNOME Extensions Manager already installed."
fi

# --- Pop Shell ---
echo "[*] Installing Pop Shell..."
sudo dnf install -y pop-shell gnome-shell-extension-pop-shell || echo "[!] Pop Shell install failed. Please install manually."
gnome-extensions enable pop-shell@system76.com || echo "[!] Could not enable Pop Shell. Maybe GNOME Shell needs restart."

# =============================
# Blur My Shell
# =============================
echo "[*] Installing Blur My Shell from source..."
TMP_DIR="/tmp/blur-my-shell"

rm -rf "$TMP_DIR"
git clone https://github.com/aunetx/blur-my-shell.git "$TMP_DIR"
make -C "$TMP_DIR" install
rm -rf "$TMP_DIR"

# =============================
# Dash to Dock
# =============================
echo "[*] Installing Dash to Dock from source..."
TMP_DIR="/tmp/dash-to-dock"

rm -rf "$TMP_DIR"
git clone https://github.com/micheleg/dash-to-dock.git "$TMP_DIR"

for cmd in msgfmt sassc glib-compile-schemas; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[*] '$cmd' is missing → installing..."
        case "$cmd" in
            msgfmt) sudo dnf install -y gettext ;;
            sassc) sudo dnf install -y sassc ;;
            glib-compile-schemas) sudo dnf install -y glib2 ;;
        esac
    fi
done

make -C "$TMP_DIR" install
rm -rf "$TMP_DIR"

# =============================
# Compact Top Bar
# =============================
echo "[*] Installing Compact Top Bar from source..."
TMP_DIR="/tmp/compact-top-bar"

rm -rf "$TMP_DIR"
git clone https://github.com/metehan-arslan/gnome-compact-top-bar.git "$TMP_DIR"

mkdir -p ~/.local/share/gnome-shell/extensions
cp -r "$TMP_DIR/gnome-compact-top-bar@metehan-arslan.github.io" ~/.local/share/gnome-shell/extensions

rm -rf "$TMP_DIR"

# =============================

echo "[✓] GNOME extensions installation completed!"
echo "Restart GNOME Shell (Alt+F2 → r) or log out to apply the extensions."

