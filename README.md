# dotfiles

Personal dotfiles for a CachyOS Hyprland setup.

## What's included

| Path in repo | Symlinked to | Notes |
|---|---|---|
| `.config/hypr/` | `~/.config/hypr/` | Hyprland, Hyprlock, Hyprpaper configs |
| `.config/waybar/` | `~/.config/waybar/` | Bar config + CSS |
| `.config/rofi/` | `~/.config/rofi/` | Launcher themes, applets, powermenu |
| `.config/alacritty/` | `~/.config/alacritty/` | Terminal config |
| `.config/fish/` | `~/.config/fish/` | Shell config, functions, conf.d |
| `.config/btop/` | `~/.config/btop/` | System monitor config |
| `.config/lazygit/` | `~/.config/lazygit/` | Git TUI config |
| `.config/lazydocker/` | `~/.config/lazydocker/` | Docker TUI config |
| `.tmux.conf` | `~/.tmux.conf` | Tmux config (prefix: `Ctrl+A`) |
| `.gitconfig` | `~/.gitconfig` | Git user config |
| `wallpapers/` | copied to `~/Pictures/` | Desktop wallpapers |
| `id_ed25519.pub` | copied to `~/.ssh/` | SSH public key only |
| `system/etc/sddm.conf` | copied to `/etc/sddm.conf` (sudo) | SDDM default session |
| `system/etc/sddm.conf.d/autologin.conf` | copied to `/etc/sddm.conf.d/` (sudo) | SDDM autologin config |

## Installing on a new machine

### 1. Clone the repo

```bash
git clone <your-repo-url> ~/Projects/dotfiles
cd ~/Projects/dotfiles
```

### 2. Run the install script

```bash
./install.sh
```

The script will:
- Check for missing pacman packages and offer to install them
- Check for missing AUR packages and offer to install them via `paru`
- Symlink all configs into the right places under `$HOME`
- Back up any existing configs to `~/.dotfiles-backup-<timestamp>/` before overwriting
- Copy the wallpaper to `~/Pictures/`
- Install fish plugins via `fisher` if not already present
- Copy SDDM autologin config to `/etc/` (requires sudo)

> **Note:** Most packages (Hyprland, waybar, rofi, alacritty, fish, etc.) come
> pre-installed on CachyOS Hyprland edition. The script only installs what's missing.

### 3. SSH private key (manual step)

The private key is **never** committed to this repo. On the new machine either:

**Option A — copy from old machine over the network:**
```bash
# Run this on the NEW machine
scp user@old-machine:~/.ssh/id_ed25519 ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
```

**Option B — copy via USB / secure transfer, then:**
```bash
cp /path/to/id_ed25519 ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
```

**Option C — generate a new key pair on the new machine:**
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
# Then add the new public key to GitHub/servers:
cat ~/.ssh/id_ed25519.pub
# Paste into GitHub → Settings → SSH Keys
```

### 4. Add the new machine's SSH key to GitHub (if generating a new key)

```bash
gh auth login
# or paste ~/.ssh/id_ed25519.pub manually at github.com/settings/keys
```

### 5. After install

- **Reload Hyprland:** `hyprctl reload` or log out/in
- **Waybar:** restarts automatically with Hyprland; or `killall waybar && waybar &`
- **Tmux:** config loads on next session — no action needed
- **Fish plugins:** already handled by the install script; verify with `fisher list`

---

## Keeping configs in sync

After changing a config on any machine:

```bash
cd ~/Projects/dotfiles
git add -p          # review changes
git commit -m "..."
git push
```

On another machine:
```bash
cd ~/Projects/dotfiles
git pull
# symlinks already point here, so changes are live immediately
```

---

## Package list

These are the packages the install script checks for. All are available in the
CachyOS / Arch repos.

| Package | Purpose | CachyOS default? |
|---|---|---|
| `hyprland` | Compositor / WM | Yes |
| `hyprpaper` | Wallpaper daemon | Yes |
| `hyprlock` | Screen locker | Yes |
| `waybar` | Status bar | Yes |
| `rofi` | App launcher | Yes |
| `alacritty` | Terminal | Yes |
| `kitty` | Terminal (alternate) | Yes |
| `fish` | Shell | Yes |
| `fisher` | Fish plugin manager | Yes |
| `tmux` | Terminal multiplexer | No |
| `btop` | System monitor | Yes |
| `lazygit` | Git TUI | Yes |
| `lazydocker` | Docker TUI | Yes |
| `yubikey-manager` | YubiKey CLI | No |
| `yubico-piv-tool` | PIV/smartcard tool | No |
| `libfido2` | FIDO2 library | No |
| `docker` | Container runtime | No |
| `kubectl` | Kubernetes CLI | No |

**AUR packages** (installed via `paru`):

| Package | Purpose | Version |
|---|---|---|
| `visual-studio-code-bin` | VS Code (official binary) | 1.109.5 |
| `obsidian` | Notes / knowledge base | latest |
| `keeper-password-manager` | Keeper password manager | latest |

---

## Autologin + Hyprlock boot flow

This setup uses SDDM autologin so the machine boots directly into Hyprland with
`hyprlock` as the first visible screen — effectively acting as the lock screen on startup.

```
Boot → SDDM (autologin) → Hyprland → exec-once: hyprlock & waybar & hyprpaper
```

The two relevant files are:

| File | Purpose |
|---|---|
| `system/etc/sddm.conf` | Sets default session to `hyprland` |
| `system/etc/sddm.conf.d/autologin.conf` | Autologins as `drillchan` into `hyprland.desktop` |
| `.config/hypr/hyprland.conf` | `exec-once = hyprlock & waybar & hyprpaper` |
| `.config/hypr/hyprlock.conf` | Custom lock screen (blurred wallpaper, clock, styled input) |

The install script copies the `system/` files to `/etc/` using `sudo`.

**On a new machine**, after running `./install.sh`:
1. Make sure SDDM is enabled: `sudo systemctl enable sddm`
2. The username in `autologin.conf` is hardcoded to `drillchan` — change it if your
   username differs on the new machine:
   ```bash
   # edit before installing, or after:
   sudo sed -i 's/User=drillchan/User=YOURUSERNAME/' /etc/sddm.conf.d/autologin.conf
   ```
3. The hyprlock wallpaper path in `hyprlock.conf` is hardcoded to
   `/home/drillchan/Pictures/...` — update it if your home directory path differs.

---

## Notes

- `rofi` is used in place of `wofi` — the Hyprland config calls rofi for the launcher.
- Waybar has a typo'd duplicate `stlye.css` / `style.css` — both are included.
- The fish config sources `/usr/share/cachyos-fish-config/cachyos-config.fish` which
  is a CachyOS-specific path. On non-CachyOS Arch installs, install `cachyos-fish-config`
  from the CachyOS repo or remove that line from `.config/fish/config.fish`.
- `fish_variables` is gitignored — it's auto-generated and contains local state.
