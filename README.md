<p align="center">
  <img src="icon_pdrx.png" width="160" alt="pdrx logo" />
</p>

<h1 align="center">pdrx</h1>
<p align="center"><strong>Portable Dynamic Reproducible gnu/linuX</strong></p>
<p align="center">
  Pure Bash. No Nix. No Ansible. No stow.<br>
  Install packages imperatively — get a declarative config automatically.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.5.0-blue" alt="version" />
  <img src="https://img.shields.io/badge/shell-bash-green" alt="bash" />
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT" />
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-informational" alt="platform" />
</p>

---

## What is pdrx?

`pdrx` wraps your existing package managers so every install or remove you run **also updates a declarative config file** — automatically. No manual YAML. No Nix expressions.

When you move to a new machine, `pdrx apply` reads that config and reproduces your exact setup using the same package manager that originally installed each package.

```
pdrx install --pm cargo ripgrep   →   records  cargo:ripgrep  in packages.conf
pdrx install --pm apt vim         →   records  apt:vim
pdrx install --pm flatpak org.gnome.GIMP  →  records  flatpak:org.gnome.GIMP

# On new machine:
pdrx apply    →   installs each package via its recorded PM, in the right order
```

> **Why record the package manager?** `ripgrep` is available from apt, brew, and cargo. Recording `cargo:ripgrep` means `apply` always reinstalls it with `cargo install`, not apt — keeping your setup truly identical across machines.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [How the Declarative Config Works](#how-the-declarative-config-works)
- [All Commands](#all-commands)
- [Supported Package Managers](#supported-package-managers)
- [Version Pinning](#version-pinning)
- [Parallel Operations](#parallel-operations)
- [Dotfile Tracking](#dotfile-tracking)
- [Desktop Export & Restore](#desktop-export--restore)
- [Backups & Rollback](#backups--rollback)
- [Config Layout](#config-layout)
- [Syncing to GitHub](#syncing-to-github)
- [Multi-Machine & Multi-Profile Setup](#multi-machine--multi-profile-setup)
- [Workflow: Desktop User](#workflow-desktop-user)
- [Workflow: Developer](#workflow-developer)
- [License](#license)

---

## Features

| | |
|---|---|
| 🐧 **All major distros** | Debian, Ubuntu, Fedora, Arch, openSUSE, and more |
| 📦 **10 package managers** | apt, dnf, yum, pacman, zypper, brew, flatpak, snap, cargo, winget |
| 📝 **Auto declarative config** | Every install/remove updates `packages.conf` instantly |
| 🔁 **Reproducible restore** | `pdrx apply` reinstalls everything via the exact same PM |
| 📌 **Optional version pinning** | `--pin` locks a specific version; unpinned is the default |
| ⚡ **Parallel operations** | `--parallel` on `apply` and `search` for speed |
| 🖥️ **Desktop export** | GNOME, KDE, XFCE, i3, Sway, Hyprland settings backup |
| 🗂️ **Dotfile tracking** | Symlink-based tracking for `~/.bashrc`, `~/.config/nvim`, etc. |
| ⏱️ **Backups & rollback** | Timestamped generations, rollback to any point |
| 🔄 **Self-update** | `pdrx self-update` fetches the latest version in-place |
| 📤 **Export / Import** | Portable tarball for air-gapped transfers |

---

## Installation

### One-line install

Installs to `~/.local/bin` and makes the script executable:

```bash
# curl
mkdir -p ~/.local/bin && curl -sSL https://raw.githubusercontent.com/stefan-hacks/pdrx/main/pdrx -o ~/.local/bin/pdrx && chmod +x ~/.local/bin/pdrx

# wget
mkdir -p ~/.local/bin && wget -qO ~/.local/bin/pdrx https://raw.githubusercontent.com/stefan-hacks/pdrx/main/pdrx && chmod +x ~/.local/bin/pdrx
```

Make sure `~/.local/bin` is on your PATH (add to `~/.bashrc` or `~/.zshrc` if needed):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then initialise:

```bash
pdrx init
```

### Homebrew (macOS / Linux)

Installs the binary and the `man pdrx` page in one step:

```bash
brew tap stefan-hacks/pdrx https://github.com/stefan-hacks/pdrx
brew install pdrx
pdrx init
```

Upgrade to the latest release:

```bash
brew upgrade pdrx
# or, from any install method:
pdrx self-update
```

### Clone and install

```bash
git clone https://github.com/stefan-hacks/pdrx.git
cd pdrx
make install   # copies to ~/.local/bin + installs man page
pdrx init
```

Or without Make:

```bash
./pdrx --install
source ~/.bashrc
pdrx init
```

### Man page (optional)

```bash
./install_manpage.sh --user     # installs to ~/.local/share/man (no root needed)
sudo ./install_manpage.sh --system   # system-wide

# If man pdrx doesn't find the page after --user install:
export MANPATH="$HOME/.local/share/man:$MANPATH"
```

---

## Quick Start

```bash
pdrx init                                    # initialise config at ~/.pdrx
pdrx sync                                    # snapshot all currently installed packages
pdrx install vim git                         # install; choose PM interactively
pdrx install --pm flatpak org.gnome.GIMP     # install with a specific PM
pdrx install --pm cargo ripgrep --pin        # install + pin the exact version
pdrx track ~/.bashrc ~/.config/nvim/init.vim # start tracking dotfiles
pdrx backup initial                          # create a named backup checkpoint
pdrx status                                  # overview of config, PMs, packages
```

---

## How the Declarative Config Works

`~/.pdrx/config/packages.conf` is the single source of truth for your setup. Every `pdrx install` and `pdrx remove` modifies it atomically.

```
# ~/.pdrx/config/packages.conf
# Format: package_manager:package_name
#         package_manager:package_name=version   (pinned)
#
# Synced: 2025-06-01T12:00:00+0000
# OS: ubuntu

apt:vim
apt:git
apt:vim=2:9.0.1672-1ubuntu3        ← pinned apt package
flatpak:org.gnome.GIMP
cargo:ripgrep
cargo:ripgrep=14.1.0               ← pinned cargo crate
brew:jq
winget:Vim.Vim
```

### Add / Remove / Restore

| Action | What happens |
|--------|-------------|
| `pdrx install vim` | Prompts for PM, installs, writes `apt:vim` (or whichever you chose) |
| `pdrx install --pm flatpak org.gnome.GIMP` | Forces Flatpak, writes `flatpak:org.gnome.GIMP` |
| `pdrx install --pm apt vim --pin` | Installs and records the current version: `apt:vim=2:9.0.1672-1` |
| `pdrx remove vim` | Looks up the recorded PM, uninstalls, removes the line |
| `pdrx -n remove vim` | Dry-run — shows what would be removed, no changes |
| `pdrx apply` | Reads every `pm:package` line and installs via that PM |
| `pdrx apply --parallel` | Same, but different PMs run concurrently |

**Version pinning is opt-in.** The default behaviour is unpinned — `apply` always installs the latest. Only use `--pin` when you need to lock a specific version.

---

## All Commands

### Global flags (prefix any command)

| Flag | Description |
|------|-------------|
| `-h`, `--help` | Show help |
| `-v`, `--version` | Show version |
| `-q`, `--quiet` | Suppress info output |
| `-d`, `--debug` | Verbose debug output |
| `-y`, `--yes` | Skip confirmation prompts |
| `-n`, `--dry-run` | Preview changes without applying them |
| `-c DIR`, `--config DIR` | Use `DIR` as the pdrx home (default: `~/.pdrx`) |
| `--install` | Install pdrx to `~/.local/bin` and add to PATH |

```bash
pdrx -n apply               # dry-run: show what would be installed
pdrx -y destroy             # remove pdrx without prompt
pdrx -c /opt/work status    # use an alternate config directory
```

### Package management

```bash
pdrx install vim git htop                      # interactive PM selection
pdrx install --pm apt vim git                  # force a specific PM
pdrx install --pm cargo ripgrep bat --pin      # install + auto-pin installed version
pdrx install --pm apt vim --pin=2:9.0.1672-1   # install + pin a specific version
pdrx remove vim                                # remove using the recorded PM
pdrx -n remove vim                             # preview removal
pdrx list                                      # list all entries in packages.conf
pdrx search ripgrep                            # search across all available PMs
pdrx search vim 1 3                            # search only PM 1 and PM 3
pdrx search ripgrep --parallel                 # search all PMs simultaneously
pdrx sync                                      # re-snapshot all installed packages
pdrx apply                                     # install everything in packages.conf
pdrx apply --parallel                          # install across PMs in parallel
pdrx update                                    # refresh PM package indexes (no upgrade)
pdrx upgrade                                   # upgrade all packages via each PM
```

### Dotfiles

```bash
pdrx track ~/.bashrc ~/.vimrc ~/.config/nvim/init.vim
pdrx untrack ~/.bashrc
```

Tracking copies the file into `~/.pdrx/config/dotfiles/` and replaces the original with a symlink. `pdrx apply` redeploys tracked dotfiles on a new machine.

### Backups & rollback

```bash
pdrx backup                         # timestamped backup (label: manual)
pdrx backup before-upgrade          # backup with a custom label
pdrx generations                    # list backups with reference numbers
pdrx rollback                       # rollback to the most recent backup
pdrx rollback 2                     # rollback to the 2nd most recent
pdrx restore ~/.pdrx/backups/...    # restore from a specific path
pdrx clean                          # list backups (interactive)
pdrx clean all                      # delete all backups
pdrx clean current                  # delete the newest backup
pdrx clean 2-4                      # delete backups 2 through 4
```

### Desktop

```bash
pdrx sync-desktop              # export DE settings (GNOME/KDE/XFCE/i3/Sway/Hyprland)
pdrx sync-desktop --restore    # restore DE settings from export
```

### Config & maintenance

```bash
pdrx init                          # initialise pdrx (run once)
pdrx status                        # show config, PMs, package count, backup count
pdrx export my-config.tar.gz       # export config as a tarball
pdrx import my-config.tar.gz       # import from a tarball
pdrx self-update                   # update pdrx itself to the latest version
pdrx destroy                       # restore dotfiles + remove pdrx completely
pdrx -y destroy                    # same, skip confirmation
```

---

## Supported Package Managers

| PM | Platform | Notes |
|----|----------|-------|
| `apt` | Debian, Ubuntu | System packages |
| `dnf` | Fedora, RHEL 8+ | System packages |
| `yum` | RHEL 7, CentOS | System packages |
| `pacman` | Arch, Manjaro | System packages |
| `zypper` | openSUSE | System packages |
| `brew` | Any (Homebrew) | User packages, no sudo required |
| `flatpak` | Any | Sandboxed apps |
| `snap` | Ubuntu, others | Snaps |
| `cargo` | Any (Rust) | `cargo install` crates; `upgrade` auto-installs `cargo-update` if needed |
| `winget` | Windows | Use full package IDs, e.g. `Vim.Vim` |

pdrx detects which of these are available on the current machine automatically.

---

## Version Pinning

Pinning is **opt-in**. By default, `pdrx apply` installs the latest version available. Use `--pin` only when exact version reproducibility matters.

```bash
# Unpinned (default) — always installs latest
pdrx install --pm apt vim

# Auto-pin: records whatever version actually gets installed
pdrx install --pm apt vim --pin

# Explicit pin: records and installs a specific version
pdrx install --pm apt vim --pin=2:9.0.1672-1
```

Result in `packages.conf`:
```
apt:vim=2:9.0.1672-1
```

When `pdrx apply` encounters a pinned entry, it uses the PM's native version syntax:

| PM | Pinned install syntax |
|----|-----------------------|
| apt | `apt-get install pkg=version` |
| dnf / yum | `dnf install pkg-version` |
| zypper | `zypper install pkg=version` |
| cargo | `cargo install pkg --version version` |
| brew | `brew install pkg@version` |
| winget | `winget install --id pkg --version version` |
| snap | version treated as channel |
| pacman / flatpak | CLI pinning not supported; installs latest and warns |

---

## Parallel Operations

### `apply --parallel`

Groups packages by PM (so `apt` or `dnf` each run as a single invocation, respecting package manager locks), then runs each PM group as a background job. Different PMs install concurrently.

```bash
pdrx apply --parallel
```

### `search --parallel`

Queries all selected PMs simultaneously. Output is buffered per PM and printed in the original order so results stay readable.

```bash
pdrx search ripgrep --parallel
pdrx search vim 1 3 --parallel    # search only PMs 1 and 3, in parallel
```

---

## Dotfile Tracking

`pdrx track` copies a file into `~/.pdrx/config/dotfiles/` and replaces the original with a symlink pointing back to it. This means your dotfiles are stored inside `~/.pdrx`, which you can version-control and push to GitHub.

```bash
pdrx track ~/.bashrc ~/.vimrc ~/.config/nvim/init.vim ~/.tmux.conf
```

On `pdrx apply` (e.g. on a new machine), tracked dotfiles are deployed back to their original paths automatically.

To stop tracking a file (removes the symlink, leaves the copy in place):

```bash
pdrx untrack ~/.bashrc
```

`pdrx destroy` reverses everything: it replaces symlinks with the real files before removing pdrx, so nothing is lost.

---

## Desktop Export & Restore

`pdrx sync-desktop` exports your desktop environment's configuration files and settings. Supported environments:

- **GNOME** — dconf dump, gsettings, extensions, GTK themes
- **KDE Plasma** — plasma/kwin/kscreen configs
- **XFCE** — xfce4 and Thunar config
- **i3** — config, i3status, i3blocks
- **Sway** — config, waybar, swaync, foot
- **Hyprland** — hypr config, waybar, wofi

Common files (mimeapps, user-dirs, fontconfig, Xresources) are exported for all DEs.

```bash
pdrx sync-desktop              # export to ~/.pdrx/config/desktop-export/
pdrx sync-desktop --restore    # restore from that export
```

---

## Backups & Rollback

Every backup is a timestamped snapshot of your entire `~/.pdrx/config` — packages, dotfiles, and desktop export.

```bash
pdrx backup before-big-change     # create a checkpoint
pdrx generations                  # list all backups, numbered oldest → newest
```

```
  1) ~/.pdrx/backups/20250214_120000_initial
  2) ~/.pdrx/backups/20250601_083000_before-big-change
  ---
  current  (active config, not a backup)
```

```bash
pdrx rollback                     # restore from the most recent backup
pdrx rollback 2                   # restore from backup #2 (second most recent)
pdrx restore ~/.pdrx/backups/...  # restore from a specific path

pdrx clean 1                      # remove backup #1
pdrx clean 2-4                    # remove backups 2 through 4
pdrx clean all                    # remove all backups
pdrx clean current                # remove only the newest backup
```

---

## Config Layout

```
~/.pdrx/
├── config/
│   ├── packages.conf          ← declarative: pm:package or pm:package=version
│   ├── dotfiles/              ← tracked dotfile copies (symlink targets)
│   └── desktop-export/        ← exported DE settings
├── backups/
│   └── 20250214_120000_manual/
│       ├── packages.conf
│       ├── desktop-export/
│       ├── dotfiles/
│       └── tracked-dotfiles
└── state/
    ├── initialized
    ├── version
    └── tracked-dotfiles       ← list of tracked relative paths
```

Each backup is self-contained: `pdrx restore` copies the backup's `packages.conf` back to config, then `pdrx apply` reinstalls everything from it.

---

## Syncing to GitHub

Push `~/.pdrx` to a private GitHub repo to back up your config and sync it across machines.

```bash
# 1. Initialise git inside your pdrx directory
cd ~/.pdrx
git init

# 2. Add a .gitignore (backups can be large)
cat > ~/.pdrx/.gitignore << 'EOF'
backups/
*.tar.gz
EOF

# 3. Create a repo on GitHub (github.com/new), then push
git add config/ state/
git commit -m "Initial pdrx config"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/my-pdrx-config.git
git push -u origin main
```

**On a new machine:**

```bash
git clone https://github.com/YOUR_USERNAME/my-pdrx-config.git ~/.pdrx
pdrx init          # marks as initialized if not already
pdrx apply --parallel
pdrx sync-desktop --restore
```

**Daily workflow:**

```bash
pdrx sync              # capture any new installs/removes
pdrx sync-desktop      # capture DE setting changes (optional)
cd ~/.pdrx && git add . && git commit -m "Update config" && git push
```

---

## Multi-Machine & Multi-Profile Setup

Keep multiple machines (or users) in **one repo** by using one directory per profile. Each directory is a complete pdrx home with its own `config/` and `state/`.

```bash
# Clone the shared repo
git clone https://github.com/YOUR_USERNAME/my-pdrx-configs.git ~/pdrx-configs

# Create profiles
mkdir -p ~/pdrx-configs/laptop/config  ~/pdrx-configs/laptop/state
mkdir -p ~/pdrx-configs/desktop/config ~/pdrx-configs/desktop/state
mkdir -p ~/pdrx-configs/work/config    ~/pdrx-configs/work/state
```

Point pdrx at the right profile either per-session or per-command:

```bash
# Per-session
export PDRX_HOME=~/pdrx-configs/laptop
pdrx init
pdrx apply --parallel

# Per-command
pdrx -c ~/pdrx-configs/laptop  sync
pdrx -c ~/pdrx-configs/desktop status
```

**Shell aliases** remove the need to type `-c` every time:

```bash
# In ~/.bashrc or ~/.zshrc
alias pdrx-laptop='pdrx -c ~/pdrx-configs/laptop'
alias pdrx-desktop='pdrx -c ~/pdrx-configs/desktop'
alias pdrx-work='pdrx -c ~/pdrx-configs/work'
```

```bash
pdrx-laptop sync
pdrx-desktop apply --parallel
```

Commit only the profile that changed:

```bash
cd ~/pdrx-configs
git add laptop/config laptop/state
git commit -m "laptop: add new tools"
git push
```

---

## Workflow: Desktop User

### First-time setup

```bash
pdrx init
pdrx sync                                              # capture existing packages
pdrx sync-desktop                                      # export DE settings
pdrx track ~/.bashrc ~/.config/gtk-4.0/settings.ini   # track key dotfiles
pdrx backup initial
```

### Day-to-day installs

```bash
# System utilities
pdrx install firefox-esr htop neofetch

# Flatpak apps (sandboxed, newer versions)
pdrx install --pm flatpak org.gnome.GIMP org.telegram.desktop org.libreoffice.LibreOffice

# Snap (if you use it)
pdrx install --pm snap code
```

### Before and after major changes

```bash
pdrx backup before-upgrade
sudo apt full-upgrade         # or whatever your distro's upgrade is
pdrx sync
pdrx backup after-upgrade
```

### Moving to a new machine

```bash
# On old machine
cd ~/.pdrx && git push
# (or: pdrx export ~/my-config.tar.gz)

# On new machine — install your package managers first, then:
git clone https://github.com/YOU/my-pdrx-config.git ~/.pdrx
pdrx init
pdrx apply --parallel
pdrx sync-desktop --restore
```

---

## Workflow: Developer

### First-time setup

```bash
pdrx init
pdrx install --pm apt build-essential git curl wget    # base dev stack
pdrx install --pm cargo ripgrep fd-find bat --pin      # Rust CLI tools, pinned
pdrx install --pm brew jq yq-go                        # tools not in apt
pdrx track ~/.bashrc ~/.vimrc ~/.config/nvim/init.vim ~/.tmux.conf ~/.gitconfig
pdrx sync-desktop
pdrx backup dev-setup
```

### Language-specific tooling

```bash
# Rust (global dev tools)
pdrx install --pm cargo rustfmt clippy cargo-watch

# Python
pdrx install --pm apt python3-pip python3-venv

# Node
pdrx install --pm brew node
```

### Syncing across workstation and laptop

```bash
# After changes on workstation
pdrx sync
cd ~/.pdrx && git add . && git commit -m "Add new tools" && git push

# On laptop
cd ~/.pdrx && git pull
pdrx apply --parallel
pdrx sync-desktop --restore
```

### Fresh machine setup

> Install your package managers first (brew, flatpak, cargo, etc.), then:

```bash
git clone https://github.com/YOU/my-pdrx-config.git ~/.pdrx
pdrx init
pdrx apply --parallel
pdrx sync-desktop --restore
# Dotfiles are deployed, packages installed via their exact original PMs
```

### Rollback after a bad change

```bash
pdrx generations           # list all checkpoints
pdrx rollback 2            # restore from 2nd most recent backup
pdrx apply --parallel      # reinstall from the restored config
```

---

## License

[MIT](LICENSE)

---

<p align="center">
  <sub>Started as dotfiles → stow → chezmoi → a Nix wrapper (painful) → pure Bash with shellcheck. No external dependencies. Enjoy.</sub>
</p>
