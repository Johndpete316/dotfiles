#!/usr/bin/env bash
# Dotfiles install script — creates symlinks from $HOME to this repo
# Run from the dotfiles directory: ./install.sh
#
# Designed for CachyOS (Arch-based). Most packages below come pre-installed
# on a standard CachyOS Hyprland edition; this script only installs what's missing.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

info()    { echo "[INFO]    $*"; }
success() { echo "[OK]      $*"; }
warning() { echo "[WARNING] $*"; }
error()   { echo "[ERROR]   $*" >&2; }

# ── Package check & install ───────────────────────────────────────────────────
# Packages that ship with CachyOS Hyprland are marked with (pre-installed).
# The check runs either way — nothing is installed if it's already present.
PACKAGES=(
    # Compositor / WM  (pre-installed on CachyOS Hyprland)
    hyprland
    hyprpaper
    hyprlock

    # Bar (pre-installed)
    waybar

    # Launcher (pre-installed)
    rofi

    # Terminals (pre-installed)
    alacritty
    kitty

    # Shell (pre-installed)
    fish
    fisher

    # Multiplexer
    tmux

    # TUI tools
    btop
    lazygit
    lazydocker

    # YubiKey
    yubikey-manager
    yubico-piv-tool
    libfido2

    # Dev tools
    docker
    kubectl
)

# AUR packages — installed via paru
AUR_PACKAGES=(
    visual-studio-code-bin  # v1.109.5
    obsidian
    keeper-password-manager
)

MISSING=()
for pkg in "${PACKAGES[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        MISSING+=("$pkg")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    warning "The following pacman packages are not installed: ${MISSING[*]}"
    read -rp "Install them now with pacman? [y/N] " confirm || confirm="n"
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed "${MISSING[@]}"
    else
        warning "Skipping pacman install. Some configs may not work without their programs."
    fi
else
    success "All pacman packages already installed."
fi

# ── AUR packages (paru) ───────────────────────────────────────────────────────
if ! command -v paru &>/dev/null; then
    warning "paru not found — skipping AUR packages: ${AUR_PACKAGES[*]}"
    warning "Install paru first: https://github.com/Morganamilo/paru"
else
    MISSING_AUR=()
    for pkg in "${AUR_PACKAGES[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            MISSING_AUR+=("$pkg")
        fi
    done

    if [ ${#MISSING_AUR[@]} -gt 0 ]; then
        warning "The following AUR packages are not installed: ${MISSING_AUR[*]}"
        read -rp "Install them now with paru? [y/N] " confirm || confirm="n"
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            paru -S --needed "${MISSING_AUR[@]}"
        else
            warning "Skipping AUR install."
        fi
    else
        success "All AUR packages already installed."
    fi
fi

# ── Symlink helper ────────────────────────────────────────────────────────────
backup_and_link() {
    local src="$1"   # file/dir in dotfiles repo
    local dest="$2"  # target path under $HOME

    # Already a correct symlink — skip
    if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
        info "Already linked: $dest"
        return
    fi

    # Back up whatever is already there
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mkdir -p "$BACKUP_DIR"
        warning "Backing up existing $dest → $BACKUP_DIR/"
        mv "$dest" "$BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    success "Linked: $dest → $src"
}

# ── .config entries ───────────────────────────────────────────────────────────
for dir in hypr waybar rofi alacritty fish btop lazygit lazydocker; do
    backup_and_link "$DOTFILES_DIR/.config/$dir" "$HOME/.config/$dir"
done

# ── Home directory dotfiles ───────────────────────────────────────────────────
backup_and_link "$DOTFILES_DIR/.tmux.conf"  "$HOME/.tmux.conf"
backup_and_link "$DOTFILES_DIR/.gitconfig"  "$HOME/.gitconfig"

# ── Wallpaper ─────────────────────────────────────────────────────────────────
mkdir -p "$HOME/Pictures"
for wp in "$DOTFILES_DIR/wallpapers/"*; do
    name="$(basename "$wp")"
    dest="$HOME/Pictures/$name"
    if [ ! -e "$dest" ]; then
        cp "$wp" "$dest"
        success "Copied wallpaper: $dest"
    else
        info "Wallpaper already present: $dest"
    fi
done

# ── SDDM autologin (system files — requires sudo) ────────────────────────────
# This enables autologin → Hyprland → hyprlock as the "lock screen on boot" setup.
SDDM_SRC="$DOTFILES_DIR/system/etc/sddm.conf.d/autologin.conf"
SDDM_DEST="/etc/sddm.conf.d/autologin.conf"
SDDM_BASE_SRC="$DOTFILES_DIR/system/etc/sddm.conf"
SDDM_BASE_DEST="/etc/sddm.conf"

if [ -f "$SDDM_SRC" ]; then
    if [ ! -f "$SDDM_DEST" ] || ! diff -q "$SDDM_SRC" "$SDDM_DEST" &>/dev/null; then
        warning "Installing SDDM autologin config (requires sudo)..."
        sudo mkdir -p /etc/sddm.conf.d
        sudo cp "$SDDM_SRC" "$SDDM_DEST"
        success "Installed: $SDDM_DEST"
    else
        info "SDDM autologin config already up to date."
    fi
fi

if [ -f "$SDDM_BASE_SRC" ]; then
    if [ ! -f "$SDDM_BASE_DEST" ] || ! diff -q "$SDDM_BASE_SRC" "$SDDM_BASE_DEST" &>/dev/null; then
        warning "Installing /etc/sddm.conf (requires sudo)..."
        sudo cp "$SDDM_BASE_SRC" "$SDDM_BASE_DEST"
        success "Installed: $SDDM_BASE_DEST"
    else
        info "SDDM base config already up to date."
    fi
fi

# ── SSH public key ────────────────────────────────────────────────────────────
if [ -f "$DOTFILES_DIR/id_ed25519.pub" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    dest_pub="$HOME/.ssh/id_ed25519.pub"
    if [ ! -f "$dest_pub" ]; then
        cp "$DOTFILES_DIR/id_ed25519.pub" "$dest_pub"
        chmod 644 "$dest_pub"
        success "Copied SSH public key to $dest_pub"
        warning "You still need to copy your PRIVATE key (id_ed25519) manually — see README."
    else
        info "SSH public key already present: $dest_pub"
    fi
fi

# ── Fish plugins ──────────────────────────────────────────────────────────────
# fisher is a fish function, not a PATH binary — check via fish itself
if command -v fish &>/dev/null; then
    if fish -c "fisher list" 2>/dev/null | grep -q "nvm.fish"; then
        info "Fish plugins already installed."
    else
        info "Installing fish plugins via fisher..."
        if fish -c "fisher install jorgebucaran/nvm.fish" 2>/dev/null; then
            success "Fish plugins installed."
        else
            warning "Fisher install failed — run manually: fish -c 'fisher install jorgebucaran/nvm.fish'"
        fi
    fi
fi

echo ""
echo "================================================================"
echo " Installation complete!"
[ -d "$BACKUP_DIR" ] && echo " Backups saved to: $BACKUP_DIR"
echo ""
echo " Remaining manual steps:"
echo "  1. Copy your SSH private key — see README.md"
echo "  2. Add yourself to the docker group (if docker was just installed):"
echo "       sudo usermod -aG docker \$USER  (then log out/in)"
echo "  3. Enable SDDM if not already: sudo systemctl enable sddm"
echo "  4. Log out and back in (or hyprctl reload) to apply Hyprland config"
echo "================================================================"
