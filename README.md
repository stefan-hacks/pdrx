# pdrx — Portable Dynamic Reproducible linuX

**Pure Bash tool for fully reproducible Linux system setups.** No Nix dependency.

Imperatively install/remove packages while automatically updating a **declarative config** that records both the package and **which package manager** installed it. Restore your exact setup on any major Linux distribution.

NOTE: This project originally started as bash aliases, then functions, then a few scripts, then I combined them essentially as a wrapper to the nix eco system which caused me many issues so I decidede to go nix free and just use BASH and have it support different package managers. So instead of having to manually declare everything this still enables me to do auto updates to the declaritive files respectively. So I finally decided to get cursor AI and shellcheck to help me clean up my bash scripts and ideas. Enjoy!! Please let me know if you encounter any issues.

## Features

- **All major Linux distros** — Debian, Ubuntu, Fedora, Arch, openSUSE, etc.
- **Multiple package managers** — apt, dnf, yum, pacman, zypper, Homebrew, Flatpak, Snap, Cargo
- **Reproducible** — Declarative config records `package_manager:package_name` for exact replay
- **Imperative + declarative** — `pdrx install vim` updates your declarative config automatically
- **Desktop export/restore** — GNOME, KDE, XFCE, i3, Sway, Hyprland
- **Dotfile tracking** — Track `~/.bashrc`, `~/.config/nvim/init.vim`, etc.
- **Backups & rollback** — Timestamped backups; rollback to any generation
- **Export/Import** — Share config across machines

## Installation

```bash
git clone https://github.com/stefan-hacks/pdrx.git
cd pdrx
chmod +x pdrx
./pdrx --install
source ~/.bashrc
pdrx init
```

Or with Make:

```bash
make install
pdrx init
```

## Quick Start

```bash
pdrx init
pdrx sync              # Capture current packages into declarative config
pdrx install vim git   # Install and choose PM (apt, brew, etc.)
pdrx install --pm flatpak org.gnome.GIMP  # Install with specific PM
pdrx track ~/.bashrc
pdrx backup
pdrx status
```

## Declarative Format and Package Manager Recording

`~/.pdrx/config/packages.conf` records **which package manager** installed each package. This ensures **reproducible restore** — the same PM is used when applying on a new system.

```
# pdrx declarative packages
# Format: package_manager:package_name
#
# ADD:     pdrx install <pkg> records PM used. pdrx install --pm <pm> <pkg> forces a PM.
# REMOVE:  pdrx remove <pkg> uses the recorded PM, removes from config.
# RESTORE: pdrx apply uses the recorded PM for each package. Same PM = reproducible.
#
# Synced: 2025-02-14T12:00:00+0000
# OS: debian

apt:vim
apt:git
apt:htop
flatpak:org.gnome.GIMP
cargo:ripgrep
brew:jq
```

### How Add / Remove / Restore Works

| Action | Behavior |
|--------|----------|
| **Add** | `pdrx install vim` — you choose PM interactively; it is recorded as `apt:vim` (or `brew:vim`, etc.). `pdrx install --pm flatpak org.gnome.GIMP` forces Flatpak and records `flatpak:org.gnome.GIMP`. |
| **Remove** | `pdrx remove vim` — looks up the recorded PM for `vim`, uninstalls via that PM, then removes the line from config. |
| **Restore** | `pdrx apply` — reads each `pm:package` line and installs via that PM. Same PM = same source, reproducible setup. |

**Why this matters:** A package like `ripgrep` might be available from apt, brew, or cargo. Recording `cargo:ripgrep` ensures `pdrx apply` installs it with `cargo install ripgrep`, not apt or brew.

## Commands

| Command | Description |
|---------|-------------|
| `init` | Initialize pdrx |
| `status` | Show config, PMs, packages |
| `install [pkg...]` | Install and choose PM interactively |
| `install --pm PM [pkg...]` | Install with specific PM |
| `remove [pkg...]` | Remove packages |
| `list` | List packages in declarative config |
| `search TERM` | Search across PMs |
| `sync` | Capture current system into declarative config |
| `apply` | Install all from declarative config |
| `track FILE` | Track dotfile |
| `untrack FILE` | Untrack dotfile |
| `backup [LABEL]` | Create backup |
| `restore PATH` | Restore from backup |
| `generations` | List backups |
| `rollback [N]` | Rollback to backup N |
| `sync-desktop` | Export DE state |
| `sync-desktop --restore` | Restore DE state |
| `update` | Update all PM indexes |
| `export [FILE]` | Export config tarball |
| `import FILE` | Import config |
| `destroy` | Remove pdrx |

## Supported Package Managers

| PM | Distros | Notes |
|----|---------|------|
| apt | Debian, Ubuntu | System packages |
| dnf | Fedora, RHEL 8+ | System packages |
| yum | RHEL 7, CentOS | System packages |
| pacman | Arch, Manjaro | System packages |
| zypper | openSUSE | System packages |
| brew | Any (Homebrew) | User packages |
| flatpak | Any | User/system apps |
| snap | Ubuntu, others | Snaps |
| cargo | Any (Rust) | `cargo install` crates |

## Reproducible Workflow

1. **On source machine:**
   ```bash
   pdrx init
   pdrx sync              # Capture all installed packages + PM
   pdrx track ~/.bashrc ~/.vimrc
   pdrx sync-desktop      # Export GNOME/KDE/... settings
   pdrx backup
   pdrx export > my-config.tar.gz
   ```

2. **On new machine:**
   ```bash
   pdrx init
   pdrx import my-config.tar.gz
   pdrx apply             # Install all packages via correct PMs
   pdrx sync-desktop --restore
   ```

## Configuration Layout

```
~/.pdrx/
├── config/
│   ├── packages.conf     # Declarative: pm:package (PM recorded per package)
│   ├── dotfiles/         # Tracked dotfiles
│   └── desktop-export/   # Exported DE state
├── backups/              # Timestamped backups
│   └── 20250214_120000_manual/
│       ├── packages.conf # Same format: pm:package for restore
│       ├── desktop-export/
│       ├── dotfiles/
│       └── tracked-dotfiles
└── state/
    ├── initialized
    ├── version
    └── tracked-dotfiles
```

Each backup includes `packages.conf` with full `pm:package` records. `pdrx restore` copies that back; then `pdrx apply` installs using the recorded PMs.

## License

MIT
