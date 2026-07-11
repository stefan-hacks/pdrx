<div align="center">

<img src="icon_pdrx.png" width="120" alt="pdrx" />

# pdrx

**Portable Dynamic Reproducible gnu/linuX**

<p>
  <a href="https://github.com/stefan-hacks/pdrx/releases"><img src="https://img.shields.io/badge/version-1.7.3-58a6ff?style=flat-square" alt="version" /></a>
  <a href="#"><img src="https://img.shields.io/badge/shell-bash-2ea043?style=flat-square" alt="bash" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-8b949e?style=flat-square" alt="license" /></a>
</p>

<p>
  <strong>Capture your existing Linux setup. Reproduce it anywhere. Pure Bash. Zero dependencies.</strong>
</p>

</div>

---

## 🎯 The Killer Feature

**pdrx captures your ALREADY WORKING system** — not just packages you install through it.

```bash
# On your current machine — discover everything automatically
pdrx init
pdrx sync              # ← Captures ALL installed packages
pdrx sync-dotfiles     # ← Discovers .bashrc, .zshrc, .config/nvim, etc.
pdrx sync-desktop      # ← Exports GNOME/KDE/i3 settings

# Push to git
cd ~/.pdrx && git init && git add . && git commit -m "My setup" && git push

# On a fresh machine — restore everything
pdrx apply             # ← Reinstalls packages, deploys dotfiles, restores DE
```

> **Why this matters:** Most dotfile managers make you manually declare what you want. pdrx **discovers what's already there** — your years of accumulated shell aliases, that carefully tuned neovim config, those GNOME extensions you forgot you installed.

---

## 🚀 Quick Start

### 1. Install pdrx

```bash
curl -fsSL https://github.com/stefan-hacks/pdrx/releases/latest/download/pdrx -o ~/.local/bin/pdrx && chmod +x ~/.local/bin/pdrx
```

### 2. Capture Your Existing System

```bash
pdrx init              # Initialize config directory
pdrx sync              # Capture ALL installed packages
pdrx sync-dotfiles     # Auto-discover shell & editor configs
pdrx sync-desktop      # Export desktop environment settings
```

### 3. Store in Git

```bash
cd ~/.pdrx
git init
cat > .gitignore << 'EOF'
backups/
*.tar.gz
EOF
git add config/ state/
git commit -m "My complete system setup"
git remote add origin https://github.com/YOUR_USERNAME/my-pdrx-config.git
git push -u origin main
```

### 4. Restore on New Machine

```bash
# After installing your distro...
git clone https://github.com/YOUR_USERNAME/my-pdrx-config.git ~/.pdrx
pdrx init
pdrx apply --parallel  # Reinstall everything in parallel
pdrx sync-desktop --restore  # Restore DE settings
```

---

## ✨ What pdrx Captures

| What | Command | Details |
|------|---------|---------|
| **Packages** | `pdrx sync` | ALL installed packages from apt, dnf, flatpak, cargo, etc. |
| **Dotfiles** | `pdrx sync-dotfiles` | Auto-discovers .bashrc, .zshrc, .config/nvim, etc. |
| **Custom configs** | `pdrx track <path>` | Track any file or directory |
| **Desktop** | `pdrx sync-desktop` | GNOME, KDE, i3, Sway, Hyprland settings |
| **Sources** | `pdrx source add` | PPAs, custom repos, flatpak remotes |
| **Systemd** | `pdrx sync` | Enabled system and user units |

---

## 📦 Package Management

### Capture Existing Packages

```bash
# Capture ALL currently installed packages (the magic command)
pdrx sync

# This reads from apt-mark, dnf history, flatpak list, cargo --list, etc.
# Only user-installed packages are captured (not dependencies)
```

### Install New Packages

```bash
# Install and auto-record
pdrx install vim git htop
pdrx install --pm flatpak org.gnome.GIMP
pdrx install --pm cargo ripgrep --pin
```

### Restore Everything

```bash
pdrx apply              # Install all captured packages
pdrx apply --parallel   # Faster: run different PMs concurrently
```

---

## 🔧 Dotfile Management

### Auto-Discover (Recommended)

```bash
pdrx sync-dotfiles
```

Discovers and tracks configs for:
- **Shells:** Bash, Zsh, Fish, Nushell
- **Editors:** Vim, Neovim, Helix, Emacs, VS Code
- **Terminals:** Kitty, Alacritty, WezTerm
- **Tools:** Tmux, Git, SSH, Starship, Direnv, GPG

### Manual Tracking

```bash
# Track specific files
pdrx track ~/.config/alacritty/alacritty.toml
pdrx track ~/.ssh/config
pdrx track ~/.config/systemd/user/

# Stop tracking
pdrx untrack ~/.bashrc
```

---

## 🖥️ Desktop Environment

Export your entire DE configuration:

```bash
# Export current settings
pdrx sync-desktop

# Restore on new machine
pdrx sync-desktop --restore
```

**Supported:** GNOME, KDE Plasma, XFCE, i3, Sway, Hyprland

---

## 🔄 Repository Sources

Track third-party repos so they reinstall on fresh machines:

```bash
# Add a PPA
pdrx source add apt ppa:deadsnakes/ppa

# Add Docker repo with GPG key
pdrx source add apt-repo \
  'deb [signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable' \
  /etc/apt/keyrings/docker.gpg \
  https://download.docker.com/linux/ubuntu/gpg

# Add flatpak remote
pdrx source add flatpak flathub https://flathub.org/repo/flathub.flatpakrepo

# List all sources
pdrx source list
```

---

## ⚙️ Systemd Units

Automatically captured during `pdrx sync`:

```bash
# View tracked units
cat ~/.pdrx/config/systemd.conf

# Format:
# system:kanata.service     ← system-wide unit
# user:pipewire.service     ← user unit
```

---

## 💾 Backups & Rollback

Create checkpoints before major changes:

```bash
pdrx backup before-upgrade    # Create named backup
pdrx generations              # List all backups
pdrx rollback                 # Restore most recent
pdrx rollback 2               # Restore second most recent
```

---

## 🌐 Supported Package Managers

| Manager | Discovery Command | Install Command |
|---------|-------------------|-----------------|
| `apt` | `apt-mark showmanual` | `pdrx install --pm apt <pkg>` |
| `dnf` | `dnf history userinstalled` | `pdrx install --pm dnf <pkg>` |
| `pacman` | `pacman -Qe` | `pdrx install --pm pacman <pkg>` |
| `flatpak` | `flatpak list --app` | `pdrx install --pm flatpak <app>` |
| `cargo` | `cargo install --list` | `pdrx install --pm cargo <crate>` |
| `brew` | `brew leaves` | `pdrx install --pm brew <pkg>` |
| + 4 more | | |

---

## 📖 Complete Command Reference

### Capture Commands (Discovery)

```bash
pdrx sync                   # Capture packages, sources, systemd units
pdrx sync-dotfiles          # Auto-discover common dotfiles
pdrx sync-desktop           # Export DE settings
pdrx track <path>           # Track specific file/directory
```

### Restore Commands

```bash
pdrx apply                  # Full restore (sources → packages → dotfiles → DE → systemd)
pdrx apply --parallel       # Parallel restore (faster)
pdrx sync-desktop --restore # Restore DE settings only
```

### Package Commands

```bash
pdrx install <pkg>          # Install and record
pdrx install --pm <pm> <pkg> # Use specific package manager
pdrx install --pin          # Pin installed version
pdrx remove <pkg>           # Remove and un-record
pdrx list                   # List captured packages
pdrx search <term>          # Search across all PMs
pdrx upgrade                # Upgrade all packages
```

### Source Commands

```bash
pdrx source add <pm> <source>   # Add repository
pdrx source list                # List repositories
pdrx source apply               # Re-apply all sources
```

### Maintenance

```bash
pdrx backup [label]         # Create checkpoint
pdrx rollback [N]           # Rollback to backup
pdrx status                 # Show system overview
pdrx history [N]            # Show audit log
pdrx self-update            # Update pdrx
pdrx export <file.tar.gz>   # Export config
pdrx import <file.tar.gz>   # Import config
```

---

## 🛡️ Version Pinning

Lock specific package versions:

```bash
# Pin current version
pdrx install --pm cargo ripgrep --pin

# Pin specific version
pdrx install --pm apt vim --pin=2:9.0.1672-1
```

---

## 🪝 Post-Apply Hooks

Run custom commands after `pdrx apply`:

```bash
pdrx hook edit
```

Example `~/.pdrx/config/hooks/post-apply.sh`:
```bash
#!/bin/bash
sudo udevadm control --reload-rules
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
```

---

## 🚫 Scope

**pdrx handles:**
- ✅ Packages from any package manager
- ✅ Repository/PPA sources
- ✅ Dotfiles and config files
- ✅ Desktop environment settings
- ✅ Enabled systemd units
- ✅ Post-apply hooks

**pdrx does NOT handle:**
- ❌ Disk partitioning, fstab, LUKS
- ❌ User/group creation
- ❌ Low-level system provisioning

These belong in cloud-init, Ansible, or your distro installer.

---

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

<div align="center">

**Capture your setup once. Reproduce it forever.**

</div>
