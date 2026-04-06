# Managing this dotfiles repo

Reference for adding new configs or packages — either manually or via an LLM/agent.

---

## A) Adding a new .config file or directory

### 1. Copy the config into the repo

For a whole directory (most common):
```bash
cp -r ~/.config/APPNAME ~/Projects/dotfiles/.config/APPNAME
```

For a single file in home (like `.tmux.conf`):
```bash
cp ~/.FILENAME ~/Projects/dotfiles/.FILENAME
```

### 2. Add the symlink to install.sh

Open `install.sh` and find the relevant section.

**For a `.config/` directory**, add it to the loop:
```bash
for dir in hypr waybar rofi alacritty fish btop lazygit lazydocker APPNAME; do
    backup_and_link "$DOTFILES_DIR/.config/$dir" "$HOME/.config/$dir"
done
```

**For a home directory dotfile**, add a `backup_and_link` line:
```bash
backup_and_link "$DOTFILES_DIR/.FILENAME" "$HOME/.FILENAME"
```

### 3. Check for machine-specific values

Before committing, scan the copied config for anything that won't transfer:
- **Hardcoded home paths** — e.g. `/home/drillchan/...` → replace with `$HOME` or `~` if the app supports it, or leave a comment
- **Hostnames or IPs** — comment out or replace with a placeholder
- **Monitor names** — comment out (see how `hyprland.conf` handles this)
- **Hardware-specific settings** — comment out with a note

### 4. Check for files that should be gitignored

Some apps write volatile state into their config directory that shouldn't be committed:
- Cache files, lock files, session state, auto-generated files
- Anything with credentials or tokens

Add patterns to `.gitignore` if needed:
```
.config/APPNAME/cache/
.config/APPNAME/session
```

### 5. Update the README

Add a row to the "What's included" table in `README.md`:
```markdown
| `.config/APPNAME/` | `~/.config/APPNAME/` | One-line description |
```

### 6. Commit and push

```bash
git add .config/APPNAME install.sh README.md .gitignore
git commit -m "Add APPNAME config"
git push origin HEAD:cachyos
```

### 7. On this machine, create the symlink

`install.sh` is idempotent — just re-run it. It will skip everything already linked and only add the new one:
```bash
cd ~/Projects/dotfiles
./install.sh
```

---

## B) Adding a new package

### Pacman (official repos / CachyOS repos)

1. Open `install.sh` and find the `PACKAGES=(` array
2. Add the package under the appropriate comment group:
```bash
    # Group name
    package-name
```
3. Update the package table in `README.md`:
```markdown
| `package-name` | What it does | No |
```
4. Commit:
```bash
git add install.sh README.md
git commit -m "Add package-name to pacman packages"
git push origin HEAD:cachyos
```

### AUR (via paru)

1. Open `install.sh` and find the `AUR_PACKAGES=(` array
2. Add the package with an optional version comment:
```bash
    package-name  # vX.Y.Z
```
3. Update the AUR table in `README.md`:
```markdown
| `package-name` | What it does | latest |
```
4. Commit:
```bash
git add install.sh README.md
git commit -m "Add package-name to AUR packages"
git push origin HEAD:cachyos
```

### Package with its own setup script

If a package needs more than just installing (e.g. a service to enable, a config to write, a group to join), create a dedicated setup script rather than adding to `install.sh`:

```bash
cp ~/Projects/dotfiles/setup-keeper.sh ~/Projects/dotfiles/setup-APPNAME.sh
# Edit to fit the new package
chmod +x ~/Projects/dotfiles/setup-APPNAME.sh
```

Follow the same pattern as `setup-keeper.sh`:
- Check if already installed with `pacman -Q`
- Install via `pacman` or `paru` if missing
- Do any post-install steps (enable service, add to group, etc.)
- Print clear next steps at the end
- **Do not modify fish config or other dotfiles** — those are managed by `install.sh` via symlinks

---

## Conventions to follow

| Thing | Convention |
|---|---|
| Branch | `cachyos` on `Johndpete316/dotfiles` |
| Commit style | Short imperative subject, e.g. `Add foo config`, `Add bar to AUR packages` |
| Machine-specific values | Always comment out, leave as an example |
| Private keys / tokens | Never commit — add to `.gitignore` |
| Fish config changes | Only via `.config/fish/conf.d/` files tracked in the repo |
| Post-install steps | Separate `setup-APPNAME.sh`, never baked into `install.sh` |
| System files (`/etc/`) | Store under `system/etc/`, copied by `install.sh` with `sudo` |
