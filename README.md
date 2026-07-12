<div align="center">

<!-- Animated-style Hero Section -->
<img src="icon_pdrx.png" width="220" alt="pdrx - Portable Dynamic Reproducible gnu/linuX" />

<h1>
  <code>pdrx</code>
</h1>

<p align="center">
  <strong>🐧 Portable Dynamic Reproducible gnu/linuX</strong><br>
  <em>Capture your Linux setup. Reproduce it anywhere. Instantly.</em>
</p>

<!-- Dynamic Badges -->
<p align="center">
  <a href="https://github.com/stefan-hacks/pdrx/releases">
    <img src="https://img.shields.io/badge/v1.8.0-2ea043?style=for-the-badge&logo=semver&logoColor=white&label=version" alt="version" />
  </a>
  <a href="#features">
    <img src="https://img.shields.io/badge/Ansible%20Export-EE0000?style=for-the-badge&logo=ansible&logoColor=white" alt="ansible" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Pure%20Bash-121011?style=for-the-badge&logo=gnu-bash&logoColor=white" alt="bash" />
  </a>
  <a href="#supported-distros">
    <img src="https://img.shields.io/badge/10%2B%20Distros-ff6e00?style=for-the-badge&logo=linux&logoColor=white" alt="distros" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/MIT-8b949e?style=for-the-badge" alt="license" />
  </a>
</p>

<!-- Terminal Preview -->
<p align="center">
  <img src="tool-preview.png" width="780" alt="pdrx terminal interface showing install, sync, and apply commands" />
</p>

<!-- Quick Stats Row -->
<p align="center">
  <img src="https://img.shields.io/badge/📦%2010%20Package%20Managers-2ea043?style=flat-square" />
  <img src="https://img.shields.io/badge/🔧%20Zero%20Dependencies-5865F2?style=flat-square" />
  <img src="https://img.shields.io/badge/⚡%20Parallel%20Apply-yellow?style=flat-square" />
  <img src="https://img.shields.io/badge/🚀%20Ansible%20Export-EE0000?style=flat-square" />
</p>

</div>

---

## ✨ What's New in v1.8.0

<div align="center">

### 🎉 **Ansible Export** — Share Your Setup as Code

```bash
pdrx export --ansible ./my-playbook
```

Export your entire system configuration as a **runnable Ansible playbook** in seconds.
Perfect for teams, CI/CD pipelines, and infrastructure-as-code workflows.

<a href="#ansible-export"><img src="https://img.shields.io/badge/Read%20More-2ea043?style=for-the-badge" /></a>

</div>

---

## 🎯 The Problem

**"I spent 3 days configuring my Linux setup and now I need to reproduce it on a new machine"**

- ❌ Manually installing packages one-by-one
- ❌ Forgetting which PPAs/repos you added
- ❌ Losing track of dotfiles and shell customizations
- ❌ GNOME extensions and settings gone
- ❌ Different package managers on different distros

---

## 💡 The Solution

**pdrx automatically captures everything** and restores it anywhere:

| Your Current Setup | → | Reproducible Config |
|-------------------|---|---------------------|
| 200+ installed packages | → | `packages.conf` with PM annotations |
| `.bashrc`, `.zshrc`, `.config/nvim` | → | Tracked dotfiles in Git |
| GNOME/KDE/i3 customizations | → | Desktop environment exports |
| Docker PPA, Flathub remote | → | Source declarations |
| Enabled systemd services | → | Service enablement config |

```bash
# On your current machine — one command captures everything
pdrx init && pdrx sync && pdrx sync-dotfiles && pdrx sync-desktop

# Push to Git
cd ~/.pdrx && git init && git add . && git commit -m "My setup" && git push

# On any new machine — restore everything
pdrx apply --parallel   # Installs all packages, restores DE, deploys dotfiles
```

---

## 🚀 Quick Start

### Install (Any Linux Distro)

```bash
curl -fsSL https://github.com/stefan-hacks/pdrx/releases/latest/download/pdrx -o ~/.local/bin/pdrx \
  && chmod +x ~/.local/bin/pdrx
```

### Capture Your System

```bash
pdrx init              # Initialize (~/.pdrx)
pdrx sync              # Capture ALL installed packages
pdrx sync-dotfiles     # Auto-discover configs (.bashrc, .zshrc, .config/nvim, etc.)
pdrx sync-desktop      # Export GNOME/KDE/i3/Sway settings
```

### Backup to Git

```bash
cd ~/.pdrx
git init
git add config/ state/
git commit -m "Complete system setup"
git push -u origin main
```

### Restore Anywhere

```bash
# On fresh machine
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.pdrx
pdrx init
pdrx apply --parallel  # Reinstall everything in parallel
```

---

## 🎨 What Gets Captured

<div align="center">

| Feature | Command | Details |
|:--------|:--------|:--------|
| **📦 Packages** | `pdrx sync` | From apt, dnf, pacman, flatpak, cargo, brew, snap, etc. |
| **📁 Dotfiles** | `pdrx sync-dotfiles` | Auto-discovers 45+ common configs |
| **🖥️ Desktop** | `pdrx sync-desktop` | GNOME, KDE, XFCE, i3, Sway, Hyprland |
| **📋 Sources** | `pdrx source add` | PPAs, repos, flatpak remotes with GPG keys |
| **⚙️ Systemd** | `pdrx sync` | Enabled system & user units |
| **🔧 Custom** | `pdrx track <path>` | Any file or directory |

</div>

---

## 🔥 Ansible Export <a id="ansible-export"></a>

<div align="center">

<p>
  <img src="https://img.shields.io/badge/New%20in%20v1.8.0-2ea043?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Ansible%20Compatible-EE0000?style=for-the-badge&logo=ansible&logoColor=white" />
</p>

**Turn your pdrx config into a runnable Ansible playbook**

</div>

### Why Ansible Export?

- 🏢 **Team Sharing** — Share setups with colleagues
- 🔄 **CI/CD Integration** — Automate environment provisioning  
- ☁️ **Cloud Ready** — Deploy to servers, VMs, containers
- 📋 **Documentation** — Self-documenting infrastructure

### Usage

```bash
# Export your entire system config
pdrx export --ansible ./infrastructure

# Generated structure:
# infrastructure/
# ├── site.yml              # Main playbook
# ├── inventory             # Localhost inventory
# ├── README.md             # Usage docs
# └── roles/pdrx_system/
#     ├── tasks/main.yml    # Package tasks per PM
#     └── vars/main.yml     # Metadata

# Dry-run to verify
cd infrastructure
ansible-playbook -i inventory site.yml --check

# Deploy for real
ansible-playbook -i inventory site.yml
```

### Supported Package Managers in Ansible Export

<p align="center">
  <img src="https://img.shields.io/badge/apt-E95420?style=flat-square&logo=debian&logoColor=white" />
  <img src="https://img.shields.io/badge/dnf-294172?style=flat-square&logo=fedora&logoColor=white" />
  <img src="https://img.shields.io/badge/pacman-1793D1?style=flat-square&logo=arch-linux&logoColor=white" />
  <img src="https://img.shields.io/badge/zypper-73BA25?style=flat-square&logo=opensuse&logoColor=white" />
  <img src="https://img.shields.io/badge/flatpak-4A90D9?style=flat-square&logo=flatpak&logoColor=white" />
  <img src="https://img.shields.io/badge/cargo-DEA584?style=flat-square&logo=rust&logoColor=black" />
  <img src="https://img.shields.io/badge/brew-FBB040?style=flat-square&logo=homebrew&logoColor=black" />
  <img src="https://img.shields.io/badge/snap-EA4C89?style=flat-square&logo=snapcraft&logoColor=white" />
</p>

---

## 🌐 Supported Distros <a id="supported-distros"></a>

<p align="center">
  <img src="https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white" />
  <img src="https://img.shields.io/badge/Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white" />
  <img src="https://img.shields.io/badge/Fedora-294172?style=for-the-badge&logo=fedora&logoColor=white" />
  <img src="https://img.shields.io/badge/Arch-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" />
  <img src="https://img.shields.io/badge/openSUSE-73BA25?style=for-the-badge&logo=opensuse&logoColor=white" />
  <img src="https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white" />
  <img src="https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" />
</p>

---

## 📖 Command Reference

### Core Commands

```bash
pdrx init                   # Initialize pdrx (~/.pdrx)
pdrx sync                   # Capture packages, sources, systemd
pdrx sync-dotfiles          # Auto-discover common dotfiles
pdrx sync-desktop           # Export desktop environment
pdrx apply                  # Restore everything
pdrx apply --parallel       # Parallel restore (faster)
```

### Package Management

```bash
pdrx install vim                    # Install with auto-detected PM
pdrx install --pm flatpak org.gimp.GIMP  # Force specific PM
pdrx install --pm cargo ripgrep --pin    # Pin version
pdrx remove vim                     # Remove package
pdrx list                           # List captured packages
pdrx search vim                     # Search across all PMs
```

### Export & Share

```bash
pdrx export my-config.tar.gz      # Export as tarball
pdrx export --ansible ./playbook  # Export as Ansible (v1.8.0+) 🆕
pdrx import my-config.tar.gz      # Import config
```

### Source Management

```bash
pdrx source add apt ppa:deadsnakes/ppa          # Add PPA
pdrx source add dnf https://docker.com/linux/fedora/docker-ce.repo
pdrx source add flatpak flathub https://flathub.org/repo/flathub.flatpakrepo
pdrx source list                                # List sources
pdrx source apply                               # Re-apply sources
```

### Backup & Maintenance

```bash
pdrx backup before-upgrade    # Create checkpoint
pdrx generations              # List backups
pdrx rollback                 # Restore newest backup
pdrx rollback 2               # Restore specific backup
pdrx status                   # Show system overview
pdrx history 50               # Show last 50 actions
pdrx self-update              # Update pdrx itself
pdrx upgrade                  # Upgrade all packages
```

---

## 🛡️ Version Pinning

Lock packages to specific versions:

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

## 💾 Backup & Rollback

```bash
pdrx backup before-upgrade    # Create named backup
pdrx generations              # List all backups with numbers
pdrx rollback                 # Restore most recent
pdrx rollback 2               # Restore second most recent
```

---

## 🚫 Scope

**pdrx handles:**
- ✅ Packages from any package manager
- ✅ Repository/PPA sources with GPG keys
- ✅ Dotfiles and configuration files
- ✅ Desktop environment settings (GNOME, KDE, i3, Sway, Hyprland)
- ✅ Enabled systemd units
- ✅ Post-apply hooks
- ✅ **Ansible playbook export (v1.8.0+)**

**pdrx does NOT handle:**
- ❌ Disk partitioning, fstab, LUKS
- ❌ User/group creation
- ❌ Low-level system provisioning

*For OS-level provisioning, use cloud-init, Ansible, or NixOS.*

---

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

<div align="center">

## **<code>pdrx</code>** — *Capture your setup once. Reproduce it forever.*

<p>
  <img src="https://img.shields.io/badge/Made%20with%20❤️-ff69b4?style=flat-square" />
  <img src="https://img.shields.io/badge/Pure%20Bash-121011?style=flat-square&logo=gnu-bash&logoColor=white" />
  <img src="https://img.shields.io/badge/PRs%20Welcome-2ea043?style=flat-square" />
</p>

</div>
