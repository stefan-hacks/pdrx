<div align="center">

<img src="icon_pdrx.png" width="120" alt="pdrx" />

# pdrx

**Portable Dynamic Reproducible gnu/linuX**

<p>
  <a href="https://github.com/stefan-hacks/pdrx/releases"><img src="https://img.shields.io/badge/version-1.7.0-58a6ff?style=flat-square" alt="version" /></a>
  <a href="#"><img src="https://img.shields.io/badge/shell-bash-2ea043?style=flat-square" alt="bash" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-8b949e?style=flat-square" alt="license" /></a>
</p>

<p>
  <strong>Pure Bash. Zero dependencies. Imperative UX with declarative output.</strong>
</p>

</div>

---

## ✨ What is pdrx?

`pdrx` wraps your existing package managers. Every install or remove automatically updates a declarative config file. No manual YAML. No Nix expressions. No complex setup.

```bash
# Install packages — your config updates automatically
pdrx install vim git htop
pdrx install --pm cargo ripgrep bat
pdrx install --pm flatpak org.gnome.GIMP

# Move to a new machine — restore everything
pdrx apply
```

> **Why it works:** `pdrx` records which package manager installed each package. On a new machine, it reinstalls everything using the *same* package manager — keeping your setup truly identical.

---

## 🚀 Quick Start (60 seconds)

```bash
# 1. Install pdrx
curl -fsSL https://github.com/stefan-hacks/pdrx/releases/latest/download/pdrx -o ~/.local/bin/pdrx && chmod +x ~/.local/bin/pdrx

# 2. Initialize your config
pdrx init

# 3. Capture your current system
pdrx sync

# 4. Start using it
pdrx install neovim tmux ripgrep
pdrx track ~/.bashrc ~/.config/nvim

# 5. Check your setup
pdrx status
```

---

## 📦 Installation

### One-line Install

```bash
# With curl
mkdir -p ~/.local/bin && \
curl -fsSL https://github.com/stefan-hacks/pdrx/releases/latest/download/pdrx -o ~/.local/bin/pdrx && \
chmod +x ~/.local/bin/pdrx
```

```bash
# With wget
mkdir -p ~/.local/bin && \
wget -qO ~/.local/bin/pdrx https://github.com/stefan-hacks/pdrx/releases/latest/download/pdrx && \
chmod +x ~/.local/bin/pdrx
```

Add to your PATH (if needed):

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Verify Installation

```bash
pdrx --version    # Should show 1.7.0
pdrx init         # Creates ~/.pdrx/
```

---

## 🎯 Core Commands

| Command | What it does |
|---------|--------------|
| `pdrx install <pkg>` | Install a package (auto-detects package manager) |
| `pdrx install --pm apt <pkg>` | Force specific package manager |
| `pdrx remove <pkg>` | Remove a package |
| `pdrx list` | Show all tracked packages |
| `pdrx search <pkg>` | Search across all package managers |
| `pdrx apply` | Restore all packages from config |
| `pdrx sync` | Capture currently installed packages |
| `pdrx status` | Overview of your entire setup |

### Examples

```bash
# Interactive package installation
pdrx install vim git htop neofetch

# Force a specific package manager
pdrx install --pm flatpak org.gnome.GIMP org.telegram.desktop
pdrx install --pm cargo ripgrep fd-find bat

# Pin a specific version
pdrx install --pm apt vim --pin=2:9.0.1672-1

# Preview changes without applying
pdrx -n remove vim
pdrx -n apply

# Parallel installation (faster)
pdrx apply --parallel
```

---

## 📁 Configuration

Your entire system configuration lives in `~/.pdrx/`:

```
~/.pdrx/
├── config/
│   ├── packages.conf       # All tracked packages
│   ├── sources.conf        # Repository/PPA sources
│   ├── systemd.conf        # Enabled systemd units
│   ├── dotfiles/           # Tracked dotfiles
│   ├── desktop-export/     # Desktop environment settings
│   └── hooks/              # Post-apply automation
├── backups/                # Backup snapshots
└── state/
    ├── tracked-dotfiles    # Symlink tracking
    └── pdrx.log           # Audit log
```

### The packages.conf File

```
# ~/.pdrx/config/packages.conf
# Format: package_manager:package_name
#         package_manager:package_name=version (pinned)

apt:vim
apt:git
apt:vim=2:9.0.1672-1ubuntu3        ← pinned version
flatpak:org.gnome.GIMP
cargo:ripgrep
cargo:ripgrep=14.1.0                 ← pinned version
brew:jq
```

---

## 🔧 Dotfile Tracking

Track your configuration files with automatic symlinking:

```bash
# Start tracking
pdrx track ~/.bashrc ~/.vimrc ~/.config/nvim/init.vim ~/.tmux.conf

# Stop tracking
pdrx untrack ~/.bashrc
```

How it works:
1. Copies the file to `~/.pdrx/config/dotfiles/`
2. Replaces original with a symlink
3. On `pdrx apply`, symlinks are recreated on new machines

---

## 💾 Backups & Rollback

Create checkpoints before major changes:

```bash
# Create a backup
pdrx backup before-upgrade

# List all backups
pdrx generations

# Rollback to previous state
pdrx rollback              # Most recent backup
pdrx rollback 2            # Second most recent

# Restore from specific path
pdrx restore ~/.pdrx/backups/20250711_120000_manual
```

---

## 🌐 Supported Package Managers

| Package Manager | Platform | Install Command |
|-----------------|----------|-----------------|
| `apt` | Debian, Ubuntu | `pdrx install --pm apt <pkg>` |
| `dnf` | Fedora, RHEL 8+ | `pdrx install --pm dnf <pkg>` |
| `yum` | RHEL 7, CentOS | `pdrx install --pm yum <pkg>` |
| `pacman` | Arch, Manjaro | `pdrx install --pm pacman <pkg>` |
| `zypper` | openSUSE | `pdrx install --pm zypper <pkg>` |
| `brew` | macOS, Linux | `pdrx install --pm brew <pkg>` |
| `flatpak` | Any | `pdrx install --pm flatpak <pkg>` |
| `snap` | Ubuntu, others | `pdrx install --pm snap <pkg>` |
| `cargo` | Any (Rust) | `pdrx install --pm cargo <pkg>` |
| `winget` | Windows | `pdrx install --pm winget <pkg>` |

---

## 🔄 Repository Sources (New in 1.7.0)

Track third-party repositories:

```bash
# Add a PPA
pdrx source add apt ppa:deadsnakes/ppa

# Add a repository with GPG key
pdrx source add apt-repo \
  'deb [signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable' \
  /etc/apt/keyrings/docker.gpg \
  https://download.docker.com/linux/ubuntu/gpg

# Add a dnf repo
pdrx source add dnf https://download.docker.com/linux/fedora/docker-ce.repo

# Add flatpak remote
pdrx source add flatpak flathub https://flathub.org/repo/flathub.flatpakrepo

# List all sources
pdrx source list
```

---

## ⚙️ Systemd Units (New in 1.7.0)

Track enabled systemd units:

```bash
# Automatically captured during sync
pdrx sync

# View tracked units
cat ~/.pdrx/config/systemd.conf

# Format:
# system:kanata.service     ← system-wide unit
# user:pipewire.service      ← user unit
```

---

## 🪝 Post-Apply Hooks (New in 1.7.0)

Run custom automation after `pdrx apply`:

```bash
# Edit the hook script
pdrx hook edit

# Example ~/.pdrx/config/hooks/post-apply.sh:
#!/bin/bash
# Reload udev rules
sudo udevadm control --reload-rules
# Enable GNOME extensions
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
```

---

## 📊 Audit Log (New in 1.7.0)

View history of all changes:

```bash
# Show last 30 changes
pdrx history

# Show last 50 changes
pdrx history 50

# Log file location
~/.pdrx/state/pdrx.log
```

---

## 🖥️ Desktop Environment Export

Export and restore your DE settings:

```bash
# Export current settings
pdrx sync-desktop

# Restore settings
pdrx sync-desktop --restore
```

**Supported:** GNOME, KDE Plasma, XFCE, i3, Sway, Hyprland

---

## ☁️ Sync to GitHub

Back up your config and sync across machines:

```bash
# Initialize git
cd ~/.pdrx
git init

# Create .gitignore
cat > .gitignore << 'EOF'
backups/
*.tar.gz
EOF

# Commit and push
git add config/ state/
git commit -m "Initial pdrx config"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/my-pdrx-config.git
git push -u origin main
```

**On a new machine:**

```bash
git clone https://github.com/YOUR_USERNAME/my-pdrx-config.git ~/.pdrx
pdrx init
pdrx apply --parallel
pdrx sync-desktop --restore
```

---

## 🏷️ Self-Update

Update pdrx to the latest version:

```bash
pdrx self-update
```

Uses SHA256 verification for security.

---

## 📖 Complete Command Reference

### Global Flags

| Flag | Description |
|------|-------------|
| `-h, --help` | Show help |
| `-v, --version` | Show version |
| `-q, --quiet` | Suppress output |
| `-d, --debug` | Verbose debug output |
| `-y, --yes` | Skip confirmations |
| `-n, --dry-run` | Preview changes only |
| `-c DIR` | Use alternate config directory |

### All Commands

```bash
# Package management
pdrx install <pkg> [pkg...]              # Install packages
pdrx install --pm <pm> <pkg>             # Use specific package manager
pdrx install --pm <pm> <pkg> --pin       # Pin current version
pdrx install --pm <pm> <pkg> --pin=X.Y.Z # Pin specific version
pdrx remove <pkg> [pkg...]               # Remove packages
pdrx list                                # List all tracked packages
pdrx search <query>                      # Search all package managers
pdrx search <query> --parallel           # Parallel search
pdrx sync                                # Capture installed packages
pdrx apply                               # Restore from config
pdrx apply --parallel                    # Parallel restore
pdrx update                              # Refresh package indexes
pdrx upgrade                             # Upgrade all packages

# Sources
pdrx source add <pm> <source>              # Add repository source
pdrx source list                         # List all sources
pdrx source apply                        # Re-apply all sources

# Dotfiles
pdrx track <path> [path...]              # Track dotfiles
pdrx untrack <path> [path...]            # Stop tracking

# Desktop
pdrx sync-desktop                        # Export DE settings
pdrx sync-desktop --restore              # Restore DE settings

# Backups
pdrx backup [label]                      # Create backup
pdrx generations                         # List backups
pdrx rollback [N]                        # Rollback (N=generations back)
pdrx restore <path>                      # Restore from path
pdrx clean [all|current|N-N]             # Remove backups

# Hooks
pdrx hook edit                           # Edit post-apply hook

# Audit
pdrx history [N]                         # Show audit log

# Config
pdrx init                                # Initialize pdrx
pdrx status                              # Show setup overview
pdrx export <file.tar.gz>                # Export config
pdrx import <file.tar.gz>                # Import config
pdrx self-update                         # Update pdrx
pdrx destroy                             # Remove pdrx completely
```

---

## 🛡️ Version Pinning

Lock specific versions for reproducibility:

```bash
# Auto-pin current version
pdrx install --pm apt vim --pin

# Pin specific version
pdrx install --pm apt vim --pin=2:9.0.1672-1

# Results in packages.conf:
# apt:vim=2:9.0.1672-1
```

**Note:** Pinning is opt-in. Default behavior installs latest versions.

---

## 🚫 Scope & Limitations

pdrx handles:
- ✅ Packages (apt, dnf, flatpak, cargo, etc.)
- ✅ Repository/PPA sources
- ✅ Dotfiles and config files
- ✅ Desktop environment settings
- ✅ Enabled systemd units
- ✅ Post-apply hooks

pdrx does **not** handle:
- ❌ Disk partitioning
- ❌ Filesystem/fstab configuration
- ❌ LUKS encryption
- ❌ User/group management
- ❌ Low-level system provisioning

These remain in your provisioning layer (Ansible, Terraform, or manual setup).

---

## 🧪 Testing

```bash
# Run test suite
cd /path/to/pdrx
./test_suite.sh

# Test in containers
make test-debian
make test-fedora
make test-arch
make test-all
```

---

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

<div align="center">

**Started as dotfiles → stow → chezmoi → a Nix wrapper (painful) → pure Bash.**

Enjoy.

</div>
