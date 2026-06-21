# PDRX v2.0 Testing Branch

> **Branch:** `v2.0-testing`  
> **Status:** In Development  
> **Goal:** Evolve pdrx from package wrapper to Debian State Engine

---

## 🎯 What's New in v2.0

This testing branch introduces the **Debian State Engine** concept — moving beyond package management to capture and reproduce complete system states.

### Core Features

| Feature | Description | Status |
|---------|-------------|--------|
| **Auto-discovery** | `pdrx v2 discover` captures extensions, flatpaks, repos, services | ✅ Working |
| **GNOME extensions** | Full extension tracking with settings | ✅ Prototype ready |
| **Flatpak remotes** | Capture and restore flatpak repositories | ✅ Working |
| **APT repo tracking** | Third-party repo + GPG key management | 🔄 In progress |
| **YAML v2.0 format** | Human-readable, machine-validatable | 📋 Spec ready |
| **Profile inheritance** | Base → workstation → dev profiles | 📋 Planned |
| **Health check** | `pdrx v2 doctor` validates setup | ✅ Working |

---

## 🚀 Quick Start

### 1. Initialize v2.0

```bash
# Run from pdrx repo root
pdrx v2 doctor
```

This checks your system is ready for v2.0 testing.

### 2. Discover Current State

```bash
# Discover GNOME extensions
pdrx v2 discover gnome -o extensions.yaml

# Discover Flatpak config
pdrx v2 discover flatpak -o flatpak.yaml

# Discover APT repositories
pdrx v2 discover apt -o apt-repos.yaml

# Full system discovery
pdrx v2 discover all -o full-config.yaml
```

### 3. Test the Python Prototype

```bash
# Direct prototype usage (more verbose)
python3 prototypes/gnome_extensions.py discover -v

# Save to file
python3 prototypes/gnome_extensions.py discover -o my-extensions.yaml

# List current extensions
python3 prototypes/gnome_extensions.py list

# Restore from config (dry run first!)
python3 prototypes/gnome_extensions.py restore -c my-extensions.yaml --dry-run
```

---

## 📁 Repository Structure

```
pdrx/
├── pdrx                      # Main script (v1.x stable)
├── pdrx-v2                   # v2.0 module (sourced by main)
├── README.md                 # This file
├── docs/
│   ├── roadmap/
│   │   └── v2.0-implementation.md    # 10-phase roadmap
│   └── schema/
│       └── config-v2.0-spec.md       # Full YAML spec
├── prototypes/
│   └── gnome_extensions.py           # Python prototype
├── plugins/                  # v2.0 plugins (future)
├── profiles/                 # Profile templates (future)
└── tests/                    # Test suite (future)
```

---

## 🧪 Testing in a VM

### Debian VM Setup

```bash
# Create VM with virt-manager or VirtualBox
# Install minimal Debian 12 (Bookworm)

# In the VM:
sudo apt update
sudo apt install -y git curl vim

# Clone this branch
git clone -b v2.0-testing https://github.com/stefan-hacks/pdrx.git
cd pdrx

# Run health check
./pdrx v2 doctor

# Discover current state
mkdir -p ~/.pdrx/v2/config
./pdrx v2 discover all -o ~/.pdrx/v2/config/discovery.yaml

# Review the output
cat ~/.pdrx/v2/config/discovery.yaml
```

### Testing GNOME Extensions

```bash
# Install some extensions
# Option 1: via apt
sudo apt install gnome-shell-extension-caffeine

# Option 2: via extensions.gnome.org (in browser)
# Install dash-to-dock, blur-my-shell

# Discover them
./pdrx v2 discover gnome -o extensions.yaml

# Review
cat extensions.yaml

# Test restore (remove an extension first)
gnome-extensions uninstall dash-to-dock@micxgx.gmail.com

# Restore
python3 prototypes/gnome_extensions.py restore -c extensions.yaml
```

---

## 📝 v2.0 YAML Format Preview

```yaml
pdrx:
  version: "2.0"
  profile: "workstation"

inherits:
  - base

packages:
  apt:
    - vim
    - neovim:
        version: "0.9.0"
  
  flatpak:
    remotes:
      - name: flathub
        url: https://flathub.org/repo/flathub.flatpakrepo
    apps:
      - id: org.mozilla.firefox

desktop:
  environment: gnome
  gnome:
    extensions:
      - uuid: dash-to-dock@micxgx.gmail.com
        version: "89"
        settings:
          org.gnome.shell.extensions.dash-to-dock:
            dock-position: "BOTTOM"

services:
  enabled:
    - ssh
    - docker

apt:
  repos:
    docker:
      uris: ["https://download.docker.com/linux/debian"]
      suites: ["bookworm"]
      signed_by: "/etc/apt/keyrings/docker.asc"
```

See `docs/schema/config-v2.0-spec.md` for complete specification.

---

## 🛠️ Development Workflow

### Branch Strategy

```
main                    # v1.x stable
  └── v2.0-testing      # This branch - active development
        └── feature/*   # Individual features (future)
```

### Testing Checklist

- [ ] `pdrx v2 doctor` passes on fresh Debian
- [ ] `pdrx v2 discover gnome` captures extensions
- [ ] `pdrx v2 discover flatpak` captures remotes
- [ ] `pdrx v2 discover apt` captures third-party repos
- [ ] Python prototype restores extensions
- [ ] YAML output is valid and readable
- [ ] Legacy v1.x commands still work

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `docs/roadmap/v2.0-implementation.md` | 10-phase implementation plan |
| `docs/schema/config-v2.0-spec.md` | Complete YAML schema spec |
| `prototypes/gnome_extensions.py` | Working Python prototype |
| `pdrx-v2` | Bash module with discovery commands |

---

## 🐛 Known Issues

| Issue | Workaround | Status |
|-------|------------|--------|
| GNOME extensions require browser install | Manual install from extensions.gnome.org | Investigating EGO API |
| APT GPG key auto-download | Currently manual | In progress |
| YAML validation | No schema validation yet | Planned |
| Profile inheritance | Not implemented | Planned |

---

## 💡 Feedback & Contributions

This is a testing branch. All feedback welcome:

- Does the discovery capture everything you need?
- Is the YAML format intuitive?
- What features are missing?

Test in VMs first — don't break your daily driver!

---

## 🔮 Roadmap to v2.0 Release

| Phase | Feature | Target |
|-------|---------|--------|
| 1 | Enhanced sync with plugins | Week 1-2 |
| 2 | YAML v2.0 format + validation | Week 3-4 |
| 3 | System services + APT repos | Week 5-6 |
| 4 | Containers + secrets | Week 7-8 |
| 5 | chezmoi + Ansible export | Week 9-10 |
| 6 | Beta release | Month 3 |
| 7 | Stable v2.0 | Month 4-6 |

See `docs/roadmap/v2.0-implementation.md` for details.

---

## 🙏 Credits

- Original pdrx concept by stefan-hacks
- v2.0 evolution inspired by LLM analysis
- GNOME extension prototype: pdrx-gnome-extensions-prototype.py

---

*Happy testing! Remember: VMs first, daily driver second.*
