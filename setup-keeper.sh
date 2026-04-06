#!/usr/bin/env bash
# Keeper Password Manager setup
# Installs Keeper via paru. SSH agent config is handled by the dotfiles
# fish conf.d (keeper.fish) — no changes to fish config are made here.

set -e

info()    { echo "[INFO]    $*"; }
success() { echo "[OK]      $*"; }
warning() { echo "[WARNING] $*"; }

# ── Install Keeper via paru ───────────────────────────────────────────────────
if pacman -Q keeper-password-manager &>/dev/null; then
    info "keeper-password-manager already installed."
else
    if ! command -v paru &>/dev/null; then
        echo "[ERROR]   paru not found. Install paru first: https://github.com/Morganamilo/paru"
        exit 1
    fi
    warning "Installing keeper-password-manager via paru..."
    paru -S --needed keeper-password-manager
    success "keeper-password-manager installed."
fi

echo ""
echo "================================================================"
echo " Keeper installed."
echo ""
echo " SSH agent socket is configured via the dotfiles fish conf.d."
echo " SSH_AUTH_SOCK will be set automatically in every fish session."
echo ""
echo " Next steps:"
echo "  1. Launch Keeper Password Manager and log in"
echo "  2. In Keeper: Settings → SSH Agent → Enable"
echo "  3. Verify in a new fish session: ssh-add -l"
echo "================================================================"
