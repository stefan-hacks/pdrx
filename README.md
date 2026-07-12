<div align="center">

<!-- Hero Section with Icon -->
<img src="icon_pdrx.png" width="200" alt="pdrx - Portable Dynamic Reproducible gnu/linuX" />

<!-- Brand -->
<h1 align="center">
  <code>pdrx</code>
</h1>

<p align="center">
  <strong>Portable Dynamic Reproducible gnu/linuX</strong><br>
  <em>Imperative now. Declarative forever.</em>
</p>

<!-- Badges -->
<p align="center">
  <a href="https://github.com/stefan-hacks/pdrx/releases">
    <img src="https://img.shields.io/badge/version-1.7.3-2ea043?style=for-the-badge&logo=semver&logoColor=white" alt="version" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/pure_bash-121011?style=for-the-badge&logo=gnu-bash&logoColor=white" alt="bash" />
  </a>
  <a href="#package-managers">
    <img src="https://img.shields.io/badge/multi--distro-ff6e00?style=for-the-badge&logo=linux&logoColor=white" alt="multi-distro" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-8b949e?style=for-the-badge" alt="license" />
  </a>
</p>

<!-- Quick Description -->
<p align="center">
  <strong>Capture your existing Linux setup. Reproduce it anywhere.<br>
  Zero dependencies. Pure Bash. Works on any distro.</strong>
</p>

<!-- Preview Image -->
<p align="center">
  <img src="tool-preview.png" width="800" alt="pdrx terminal preview" />
</p>

</div>

---

## 🎯 Why pdrx?

**Most dotfile managers** make you manually declare what you want.

**pdrx** discovers what's **already there** — your years of accumulated shell aliases, that carefully tuned neovim config, those GNOME extensions you forgot you installed.

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

---

## 🚀 Quick Start

### Install

```bash
curl -fsSL https://github.com/stefan-hacks/pdrx/releases/latest/download/pdrx -o ~/.local/bin/pdrx \
  && chmod +x ~/.local/bin/pdrx
```

### Capture Your System

```bash
pdrx init              # Initialize config directory (~/.pdrx)
pdrx sync              # Capture ALL installed packages
pdrx sync-dotfiles     # Auto-discover shell & editor configs
pdrx sync-desktop      # Export desktop environment settings
```

### Store & Restore

```bash
# Store in Git
cd ~/.pdrx
git init
git add config/ state/
git commit -m "Complete system setup"
git push -u origin main

# Restore on new machine
git clone https://github.com/YOUR_USERNAME/my-pdrx-config.git ~/.pdrx
pdrx init
pdrx apply --parallel  # Reinstall everything
```

---

## ✨ What Gets Captured

| Category | Command | What It Does |
|----------|---------|--------------|
| **📦 Packages** | `pdrx sync` | All user-installed packages from apt, dnf, pacman, flatpak, cargo, brew, snap |
| **🔧 Dotfiles** | `pdrx sync-dotfiles` | Auto-discovers .bashrc, .zshrc, .config/nvim, .config/kitty, etc. |
| **📁 Custom Files** | `pdrx track <path>` | Track any file or directory into version control |
| **🖥️ Desktop** | `pdrx sync-desktop` | GNOME, KDE, i3, Sway, Hyprland settings & extensions |
| **📋 Sources** | `pdrx source add` | PPAs, custom repos, flatpak remotes, GPG keys |
| **⚙️ Systemd** | `pdrx sync` | Enabled system and user units |

---

## 📦 Package Management

### Capture Everything

```bash
# The magic command — reads from apt-mark, dnf history, flatpak list, cargo --list, etc.
pdrx sync
```

### Install & Record

```bash
pdrx install vim git htop              # Install with auto-detection
pdrx install --pm flatpak org.gnome.GIMP  # Specific package manager
pdrx install --pm cargo ripgrep --pin  # Pin installed version
```

### Restore

```bash
pdrx apply              # Install all captured packages
pdrx apply --parallel   # Run different PMs concurrently (faster)
```

---

## 🔧 Dotfile Management

### Auto-Discover

```bash
pdrx sync-dotfiles
```

Finds and tracks configs for:
- **Shells:** Bash, Zsh, Fish, Nushell
- **Editors:** Vim, Neovim, Helix, Emacs, VS Code
- **Terminals:** Kitty, Alacritty, WezTerm
- **Tools:** Tmux, Git, SSH, Starship, Direnv, GPG

### Manual Tracking

```bash
pdrx track ~/.config/alacritty/alacritty.toml
pdrx track ~/.ssh/config
pdrx track ~/.config/systemd/user/
```

---

## 🖥️ Desktop Environments

```bash
# Export current settings
pdrx sync-desktop

# Restore on new machine
pdrx sync-desktop --restore
```

**Supported:** GNOME · KDE Plasma · XFCE · i3 · Sway · Hyprland

---

## 🔄 Repository Sources

Track third-party repos for full reproducibility:

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
```

---

## 🌐 Supported Package Managers

<p align="center">
  <img src="https://img.shields.io/badge/apt-E95420?style=flat-square&logo=debian&logoColor=white" />
  <img src="https://img.shields.io/badge/dnf-294172?style=flat-square&logo=fedora&logoColor=white" />
  <img src="https://img.shields.io/badge/pacman-1793D1?style=flat-square&logo=arch-linux&logoColor=white" />
  <img src="https://img.shields.io/badge/flatpak-4A90D9?style=flat-square&logo=flatpak&logoColor=white" />
  <img src="https://img.shields.io/badge/cargo-DEA584?style=flat-square&logo=rust&logoColor=black" />
  <img src="https://img.shields.io/badge/brew-FBB040?style=flat-square&logo=homebrew&logoColor=black" />
  <img src="https://img.shields.io/badge/snap-EA4C89?style=flat-square&logo=snapcraft&logoColor=white" />
  <img src="https://img.shields.io/badge/winget-0078D6?style=flat-square&logo=windows&logoColor=white" />
</p>

| Manager | Discovery | Install |
|---------|-----------|---------|
| `apt` | `apt-mark showmanual` | `pdrx install --pm apt <pkg>` |
| `dnf` | `dnf history userinstalled` | `pdrx install --pm dnf <pkg>` |
| `pacman` | `pacman -Qe` | `pdrx install --pm pacman <pkg>` |
| `zypper` | `zypper search -i` | `pdrx install --pm zypper <pkg>` |
| `flatpak` | `flatpak list --app` | `pdrx install --pm flatpak <app>` |
| `cargo` | `cargo install --list` | `pdrx install --pm cargo <crate>` |
| `brew` | `brew leaves` | `pdrx install --pm brew <pkg>` |
| `snap` | `snap list` (excludes core*) | `pdrx install --pm snap <pkg>` |

---

## 📖 Command Reference

### Capture Commands

```bash
pdrx sync                   # Capture packages, sources, systemd
pdrx sync-dotfiles          # Auto-discover common dotfiles
pdrx sync-desktop           # Export DE settings
pdrx track <path>           # Track specific file/directory
```

### Restore Commands

```bash
pdrx apply                  # Full restore
pdrx apply --parallel       # Parallel restore (faster)
pdrx sync-desktop --restore # Restore DE only
```

### Package Commands

```bash
pdrx install <pkg>               # Install and record
pdrx install --pm <pm> <pkg>     # Use specific PM
pdrx install --pin               # Pin version
pdrx remove <pkg>                # Remove and un-record
pdrx list                        # List captured packages
pdrx search <term>               # Search across all PMs
```

### Maintenance

```bash
pdrx backup [label]         # Create checkpoint
pdrx rollback [N]           # Rollback to backup
pdrx status                 # Show system overview
pdrx history [N]            # Show audit log
pdrx self-update            # Update pdrx
```

---

## 🛡️ Version Pinning

```bash
# Pin current version
pdrx install --pm cargo ripgrep --pin

# Pin specific version
pdrx install --pm apt vim --pin=2:9.0.1672-1
```

---

## 🪝 Post-Apply Hooks

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

## 💾 Backups & Rollback

```bash
pdrx backup before-upgrade    # Create named backup
pdrx generations              # List all backups
pdrx rollback                 # Restore most recent
pdrx rollback 2               # Restore specific generation
```

---

## 🚫 Scope

**pdrx handles:**
- ✅ Packages from any package manager
- ✅ Repository/PPA sources with GPG keys
- ✅ Dotfiles and configuration files
- ✅ Desktop environment settings
- ✅ Enabled systemd units
- ✅ Post-apply hooks

**pdrx does NOT handle:**
- ❌ Disk partitioning, fstab, LUKS
- ❌ User/group creation
- ❌ Low-level system provisioning

---

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

<div align="center">

**<code>pdrx</code>** — *Capture your setup once. Reproduce it forever.*

<p align="center">
  <img src="https://img.shields.io/badge/made_with-❤️-ff69b4?style=flat-square" />
  <img src="https://img.shields.io/badge/pure_bash-121011?style=flat-square&logo=gnu-bash&logoColor=white" />
</p>

</div>
