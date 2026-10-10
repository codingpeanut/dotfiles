# uninstall.just - Declarative dotfiles & desktop uninstaller
# Usage:
#   just -f uninstall.just [recipe]
#   just -f uninstall.just
#   just -f uninstall.just dry-run
#   just -f uninstall.just dotfiles
#   just -f uninstall.just system
#   just -f uninstall.just all

default:
    @just -f uninstall.just --list

# Complete uninstallation: unstow dotfiles, restore backups, stop services, and prompt for system packages
uninstall *args:
    @bash scripts/uninstall.sh {{ args }}

# Preview actions that will be performed during uninstallation (dry-run)
dry-run:
    @bash scripts/uninstall.sh --dry-run

# Revert dotfiles symlinks, restore backups, and stop desktop services only
dotfiles:
    @bash scripts/uninstall.sh --dotfiles

# Revert system-level packages and COPR repositories (Fedora)
system:
    @bash scripts/uninstall.sh --system

# Full wipe: revert dotfiles + remove system packages & COPRs
all:
    @bash scripts/uninstall.sh --all
