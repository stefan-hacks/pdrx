# PDRX Configuration Schema v2.0 Specification

> **Version:** 2.0.0  
> **Status:** Draft  
> **Format:** YAML with JSON Schema validation  

---

## Overview

The PDRX v2.0 configuration format is a declarative, human-readable, machine-validatable specification for describing complete Linux system states. It supports profile inheritance, modular components, and references (not values) for secrets.

### Design Principles

1. **Human-editable:** Plain YAML, clear structure, inline comments supported
2. **Machine-validatable:** JSON Schema enforcement with clear error messages
3. **Backward-compatible:** v1.0 `packages.conf` still supported via migration
4. **Partial configurations:** Track only what you want, omit the rest
5. **Profile inheritance:** Build configs from reusable base profiles
6. **Secret-agnostic:** Reference secrets, never store values

---

## File Locations

```
~/.pdrx/
├── config/
│   ├── machine.yaml          # Main configuration (v2.0)
│   ├── packages.conf         # Legacy format (backward compatible)
│   ├── packages.conf.lock    # Version locks (legacy)
│   └── dotfiles/             # Tracked dotfiles
├── profiles/
│   ├── base.yaml             # Base profile
│   ├── workstation.yaml        # GUI workstation
│   ├── server.yaml           # Headless server
│   └── developer.yaml        # Dev machine with containers
├── backups/
│   └── YYYYMMDD-HHMMSS/      # Timestamped backups
└── state/
    └── current-generation     # Pointer to active config
```

---

## Top-Level Structure

```yaml
# Required metadata
pdrx:
  version: "2.0"
  created_at: "2025-01-20T10:30:00Z"
  last_sync: "2025-01-20T15:45:00Z"
  hostname: "ghost"
  profile: "workstation"

# Optional inheritance
inherits:
  - base
  - developer

# Configuration sections (all optional)
machine: {}
users: []
packages: {}
apt: {}
services: {}
desktop: {}
containers: {}
vms: {}
dotfiles: {}
fonts: {}
apps: {}
themes: {}
secrets: {}
hooks: {}
validation: {}
```

---

## Section Specifications

### `pdrx` (Required)

Configuration metadata and versioning.

```yaml
pdrx:
  version: "2.0"                    # Required: Schema version
  created_at: "2025-01-20T10:30:00Z"  # ISO 8601 timestamp
  last_sync: "2025-01-20T15:45:00Z" # Last successful sync
  hostname: "ghost"                  # Machine hostname
  profile: "workstation"             # Active profile name
  
  # Optional: Migration tracking
  migrated_from: "1.0"
  migrated_at: "2025-01-20T10:30:00Z"
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | ✅ | Schema version, must be `"2.0"` |
| `created_at` | string | ❌ | ISO 8601 timestamp of creation |
| `last_sync` | string | ❌ | ISO 8601 timestamp of last sync |
| `hostname` | string | ❌ | System hostname at creation |
| `profile` | string | ❌ | Active profile name |
| `migrated_from` | string | ❌ | Previous version if migrated |

---

### `inherits` (Optional)

Profile inheritance chain. Base profiles are loaded left-to-right, with later profiles overriding earlier ones.

```yaml
inherits:
  - base          # Loaded first
  - developer     # Overrides base
  - workstation   # Overrides developer (most specific)
```

**Inheritance Rules:**
- Dictionaries are deep-merged (recursive)
- Arrays are replaced (not merged)
- `null` values explicitly remove inherited keys

---

### `machine` (Optional)

Machine-level configuration.

```yaml
machine:
  hostname: "ghost"               # System hostname
  timezone: "Europe/London"       # tzdata timezone
  locale: "en_GB.UTF-8"           # System locale
  
  # Kernel configuration
  kernel_modules:
    - kvm
    - vboxdrv
  
  # Boot configuration
  bootloader: "systemd-boot"      # or "grub", "lilo"
  
  # Network (optional)
  network:
    static_ip: false
    # Or full static config:
    # interface: eth0
    # address: 192.168.1.100/24
    # gateway: 192.168.1.1
    # dns: [8.8.8.8, 8.8.4.4]
```

---

### `users` (Optional)

User account definitions. Note: Most fields require root/sudo.

```yaml
users:
  - username: stefan
    full_name: "Stefan Hacks"
    shell: /bin/bash
    groups: [sudo, docker, libvirt, adm]
    
    # Password: reference only (hashed or secret)
    password:
      source: sops
      path: "secrets/users/stefan-password"
    
    # SSH authorized keys
    ssh_authorized_keys:
      - "ssh-ed25519 AAAAC3NzaC... stefan@ghost"
    
    # Home directory configuration
    home:
      create: true
      permissions: "0750"
      
    # Systemd-homed integration (future)
    homed: false
    
    # User-specific packages (installed after user creation)
    packages:
      cargo:
        - starship
```

---

### `packages` (Optional)

Multi-package-manager package definitions.

#### Simple Format (String)

```yaml
packages:
  apt:
    - vim
    - tmux
    - git
  
  flatpak:
    - org.mozilla.firefox
    - org.gimp.GIMP
  
  cargo:
    - ripgrep
    - fd-find
```

#### Extended Format (Object)

```yaml
packages:
  apt:
    # Simple package
    - vim
    
    # Package with pinning
    - name: neovim
      version: "0.9.0"
    
    # Package from custom repo
    - name: docker-ce
      repo: docker
    
    # Package with alternatives
    - name: python3
      alternatives:
        - python3.11
        - python3.12
  
  flatpak:
    - id: org.mozilla.firefox
      remote: flathub
      version: "125.0"
      installation: user  # or "system"
  
  cargo:
    - name: bat
      version: "0.24.0"
      features: ["full"]
  
  brew:  # macOS only, ignored on Linux
    - neovim
    - tmux
  
  snap:
    - name: spotify
      channel: stable
      classic: false
  
  nix:  # Nix packages (if nix is installed)
    - ripgrep
    - fd
```

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Package name |
| `version` | string | Exact version to install |
| `repo` | string | APT repository key (references apt.repos) |
| `installation` | string | For flatpak: `user` or `system` |
| `features` | array | For cargo: feature flags |
| `channel` | string | For snap: channel name |
| `classic` | boolean | For snap: classic confinement |

---

### `apt` (Optional)

APT repository configuration. Supports both traditional `.list` and modern deb822 `.sources` formats.

```yaml
apt:
  # Modern deb822 format (preferred)
  repos:
    docker:
      name: "Docker CE"
      enabled: true
      types: [deb]                    # deb or deb-src
      architectures: [amd64, arm64]   # Optional: defaults to system arch
      uris:
        - "https://download.docker.com/linux/debian"
      suites:
        - "bookworm"
      components:
        - "stable"
        - "test"
      signed_by: "/etc/apt/keyrings/docker.asc"
      # Auto-download key if not present:
      key_url: "https://download.docker.com/linux/debian/gpg"
      # Or embed key content:
      # key_content: |
      #   -----BEGIN PGP PUBLIC KEY BLOCK-----
      #   ...
      
    vscode:
      name: "VS Code"
      uris: ["https://packages.microsoft.com/repos/code"]
      suites: ["stable"]
      components: ["main"]
      signed_by: "/etc/apt/keyrings/packages.microsoft.gpg"
      key_url: "https://packages.microsoft.com/keys/microsoft.asc"
    
    # Traditional format (auto-converted to deb822)
    hashicorp:
      name: "HashiCorp"
      format: "traditional"             # Explicit traditional format
      line: "deb [arch=amd64 signed-by=/etc/apt/keyrings/hashicorp.asc] https://apt.releases.hashicorp.com bookworm main"
      key_url: "https://apt.releases.hashicorp.com/gpg"
  
  # Pinning preferences
  preferences:
    - package: "*"
      pin: "release a=stable"
      priority: 900
    
    - package: "nvidia-*"
      pin: "release a=bookworm-backports"
      priority: 990
```

---

### `flatpak` (Optional)

Flatpak-specific configuration (can also use `packages.flatpak`).

```yaml
flatpak:
  # Remote repositories
  remotes:
    - name: flathub
      url: "https://flathub.org/repo/flathub.flatpakrepo"
      gpg: "https://flathub.org/repo/flathub.gpg"
      type: "system"        # or "user"
    
    - name: flathub-beta
      url: "https://flathub.org/beta-repo/flathub-beta.flatpakrepo"
      type: "user"
  
  # Applications
  apps:
    - id: org.mozilla.firefox
      remote: flathub
      branch: stable        # default: stable
      installation: user
      
    - id: org.gimp.GIMP
      remote: flathub
      version: "2.10.36"
  
  # Runtimes (usually auto-installed with apps)
  runtimes:
    - id: org.gnome.Platform
      version: "45"
      remote: flathub
  
  # Overrides
  overrides:
    global:
      filesystems:
        - "~/Projects:rw"
        - "~/.themes:ro"
      env:
        GTK_THEME: "Adwaita-dark"
```

---

### `services` (Optional)

Systemd service configuration.

```yaml
services:
  # Services to enable and start
  enabled:
    - ssh
    - docker
    - tailscaled
    - libvirtd
    - bluetooth
  
  # Services to explicitly disable
  disabled:
    - cups-browsed
    - avahi-daemon
  
  # Services to mask (completely disable)
  masked:
    - snapd
    - ModemManager
  
  # Custom service definitions
  custom:
    - name: syncthing
      type: user              # user or system
      enabled: true
      description: "Syncthing file sync"
      exec_start: "/usr/bin/syncthing -no-browser -no-restart"
      restart: "on-failure"
      
    - name: myapp
      type: system
      enabled: true
      unit_file: |
        [Unit]
        Description=My Application
        After=network.target
        
        [Service]
        Type=simple
        User=myuser
        ExecStart=/opt/myapp/bin/server
        Restart=always
        
        [Install]
        WantedBy=multi-user.target
```

---

### `desktop` (Optional)

Desktop environment configuration.

```yaml
desktop:
  environment: gnome            # gnome, kde, xfce, i3, sway, hyprland
  session_manager: gdm3         # gdm3, sddm, lightdm
  
  # GNOME-specific configuration
  gnome:
    # Extensions
    extensions:
      - uuid: dash-to-dock@micxgx.gmail.com
        name: "Dash to Dock"
        version: "89"
        source: "extensions.gnome.org"
        url: "https://extensions.gnome.org/extension/307/dash-to-dock/"
        settings:
          org.gnome.shell.extensions.dash-to-dock:
            dock-position: "BOTTOM"
            show-trash: false
            dash-max-icon-size: 48
            show-mounts: false
            isolate-workspaces: true
      
      - uuid: blur-my-shell@aunetx
        name: "Blur my Shell"
        version: "65"
        settings:
          org.gnome.shell.extensions.blur-my-shell:
            brightness: 0.6
            sigma: 30
            hacks-level: 1
      
      - uuid: caffeine@patapon.info
        name: "Caffeine"
        source: "apt"               # Installed via apt
        package: gnome-shell-extension-caffeine
    
    # General GNOME settings (dconf)
    settings:
      org.gnome.desktop.interface:
        color-scheme: "prefer-dark"
        enable-animations: true
        clock-show-weekday: true
        clock-show-seconds: false
        show-battery-percentage: true
      
      org.gnome.desktop.wm.preferences:
        button-layout: "appmenu:minimize,maximize,close"
        focus-mode: "sloppy"
        auto-raise: false
      
      org.gnome.desktop.session:
        idle-delay: 900              # 15 minutes
      
      org.gnome.settings-daemon.plugins.power:
        sleep-inactive-ac-timeout: 1800
        sleep-inactive-battery-timeout: 900
        idle-dim: true
      
      org.gnome.desktop.peripherals.mouse:
        natural-scroll: false
        speed: 0.0
    
    # Custom keyboard shortcuts
    keybindings:
      - name: "Launch Terminal"
        command: "kitty"
        binding: "<Super>Return"
      
      - name: "Launch Browser"
        command: "flatpak run org.mozilla.firefox"
        binding: "<Super>b"
      
      - name: "Launch Editor"
        command: "flatpak run com.visualstudio.code"
        binding: "<Super>e"
      
      - name: "Screenshot Area"
        command: "gnome-screenshot -a -f ~/Pictures/screenshots/%Y-%m-%d-%H%M%S.png"
        binding: "<Shift><Super>4"
    
    # Favorite apps in dock
    favorites:
      - firefox.desktop
      - org.gnome.Nautilus.desktop
      - org.gnome.Console.desktop
      - com.visualstudio.code.desktop
      - org.gnome.Settings.desktop
  
  # KDE Plasma configuration (future)
  kde:
    theme: "Breeze Dark"
    # ...
  
  # i3/sway configuration (future)
  i3:
    config_source: "~/.config/i3/config"
    # Or inline:
    # config: |
    #   bindsym $mod+Return exec kitty
```

---

### `containers` (Optional)

Docker/Podman container definitions.

```yaml
containers:
  docker:
    # Images to pull
    images:
      - kalilinux/kali-rolling:latest
      - ubuntu:22.04
      - python:3.11-slim
      - node:20-alpine
    
    # Named containers to create/run
    containers:
      - name: kali
        image: kalilinux/kali-rolling
        command: sleep infinity
        
        volumes:
          - source: "~/work"
            target: "/work"
            mode: "rw"
          - source: "~/tools"
            target: "/tools"
            mode: "ro"
        
        ports:
          - host: 8080
            container: 80
        
        env:
          TERM: xterm-256color
          EDITOR: vim
        
        capabilities:
          - NET_ADMIN
          - SYS_ADMIN
        
        devices:
          - /dev/net/tun
        
        restart: unless-stopped
        autostart: true
        
      - name: dev-postgres
        image: postgres:16-alpine
        env:
          POSTGRES_USER: dev
          POSTGRES_PASSWORD:
            source: sops
            path: "secrets/db/dev-postgres"
        volumes:
          - postgres-data:/var/lib/postgresql/data
        ports:
          - "5432:5432"
        restart: unless-stopped
    
    # Networks
    networks:
      - name: dev-network
        driver: bridge
  
  podman:
    # Similar structure to docker
    images: []
    containers: []
    pods: []
```

---

### `vms` (Optional)

Virtual machine definitions (libvirt/KVM, VirtualBox).

```yaml
vms:
  libvirt:
    - name: windows-dev
      title: "Windows Development VM"
      os_type: windows
      os_variant: win10
      
      hardware:
        memory: 8192              # MB
        vcpus: 4
        cpu_mode: host-passthrough
        
        disk:
          - type: file
            size: 100             # GB
            format: qcow2
            pool: default
        
        network:
          type: bridge
          source: virbr0
          mac: "52:54:00:12:34:56"
        
        graphics:
          type: spice
          listen: none
          password: false
        
        pci_passthrough: []
      
      # Storage pools
      storage_pools:
        - name: vm-storage
          type: dir
          target: "/var/lib/libvirt/images"
          capacity: 500
      
      # Auto-start with host
      autostart: true
      
      # XML definition (optional, for advanced config)
      xml_template: "~/.pdrx/templates/windows-dev.xml"
  
  virtualbox:
    - name: test-vm
      os: "Ubuntu_64"
      memory: 4096
      cpus: 2
      vram: 128
      disk:
        size: 50
        path: "~/VirtualBox VMs/test-vm/test-vm.vdi"
      network:
        - type: nat
        - type: hostonly
          name: vboxnet0
      autostart: false
```

---

### `dotfiles` (Optional)

Dotfile management configuration.

```yaml
dotfiles:
  # Option 1: Native pdrx tracking
  native:
    enabled: true
    strategy: "symlink"         # symlink, copy, or git-worktree
    
    # Repository containing dotfiles
    repo: "https://github.com/user/dotfiles"
    branch: main
    
    # Files to track
    tracked:
      - source: "bash/bashrc"
        target: "~/.bashrc"
      - source: "kitty"
        target: "~/.config/kitty"
      - source: "nvim"
        target: "~/.config/nvim"
      - source: "git/gitconfig"
        target: "~/.gitconfig"
        template: true              # Process as template
    
    # Templates use Jinja2 syntax
    template_variables:
      user_email: "user@example.com"
      user_name: "User Name"
  
  # Option 2: Delegate to chezmoi
  chezmoi:
    enabled: false
    repo: "https://github.com/user/dotfiles"
    branch: main
    apply: true                   # Run chezmoi apply after init
    
  # Option 3: Delegate to GNU Stow
  stow:
    enabled: false
    packages: [bash, kitty, nvim, git]
    target: "~"
    
  # Option 4: yadm (yet another dotfiles manager)
  yadm:
    enabled: false
    repo: "https://github.com/user/dotfiles"
    bootstrap: true               # Run yadm bootstrap if exists
```

---

### `fonts` (Optional)

Font installation configuration.

```yaml
fonts:
  # System-wide fonts (requires root)
  system:
    - name: "JetBrains Mono"
      source: "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip"
      install_method: "download"
      
    - name: "Fira Code"
      package: fonts-firacode       # Install via apt
      
    - name: "Cascadia Code"
      source: "github:microsoft/cascadia-code"
      version: "2404.23"
  
  # User fonts (no root required)
  user:
    - name: "Nerd Fonts"
      source: "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"
      extract_to: "~/.local/share/fonts/NerdFonts"
      
    - path: "~/.fonts/custom/"     # Copy from local path
  
  # Font configuration
  config:
    # Default monospace font
    monospace: "JetBrains Mono"
    
    # Default sans-serif
    sans_serif: "Cantarell"
    
    # Default serif
    serif: "DejaVu Serif"
    
    # Fontconfig tweaks
    hinting: true
    antialiasing: true
    dpi: 96
```

---

### `apps` (Optional)

Per-application configuration.

```yaml
apps:
  kitty:
    config_version: "0.35"
    
    # Settings written to ~/.config/kitty/kitty.conf
    settings:
      font_family: "JetBrains Mono"
      font_size: 12.0
      bold_font: "auto"
      italic_font: "auto"
      
      background_opacity: "0.95"
      background: "#1a1a1a"
      foreground: "#d4d4d4"
      
      enable_audio_bell: false
      visual_bell_duration: "0.0"
      
      scrollback_lines: 10000
      scrollback_pager: "less --chop-long-lines --RAW-CONTROL-CHARS"
      
      shell: "bash"
      editor: "nvim"
      
      # Keyboard shortcuts
      map:
        "ctrl+shift+t": "new_tab"
        "ctrl+shift+q": "close_tab"
        "ctrl+tab": "next_tab"
        "ctrl+shift+tab": "previous_tab"
  
  vscode:
    # Extensions to install
    extensions:
      - ms-python.python
      - ms-python.vscode-pylance
      - rust-lang.rust-analyzer
      - eamodio.gitlens
      - github.copilot
      - github.copilot-chat
      - editorconfig.editorconfig
      - esbenp.prettier-vscode
      - bradlc.vscode-tailwindcss
    
    # Settings.json content
    settings:
      "editor.fontFamily": "JetBrains Mono, 'Fira Code', monospace"
      "editor.fontSize": 14
      "editor.fontLigatures": true
      "editor.formatOnSave": true
      "editor.rulers": [80, 120]
      "editor.tabSize": 2
      "editor.insertSpaces": true
      "files.trimTrailingWhitespace": true
      "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font"
  
  firefox:
    profiles:
      default:
        # Preferences written to user.js
        preferences:
          "browser.startup.homepage": "about:blank"
          "browser.newtabpage.enabled": false
          "browser.download.startDownloadsinDownloadsDir": true
          "browser.tabs.firefox-view": false
          
        # Extensions to install
        extensions:
          - ublock-origin
          - bitwarden
          - tree-style-tab
        
        # Policies (requires Firefox ESR or admin install)
        policies:
          DisableTelemetry: true
          DisableFirefoxStudies: true
```

---

### `themes` (Optional)

System theming configuration.

```yaml
themes:
  # GTK theme
  gtk:
    theme: "Adwaita-dark"
    icon_theme: "Papirus-Dark"
    cursor_theme: "Bibata-Modern-Classic"
    font: "Cantarell 11"
    document_font: "Sans 11"
    monospace_font: "JetBrains Mono 10"
  
  # Qt/KDE theme
  qt:
    style: "kvantum"
    icon_theme: "Papirus-Dark"
  
  # Cursor configuration
  cursor:
    theme: "Bibata-Modern-Classic"
    size: 24
  
  # Wallpaper
  wallpaper:
    source: "https://github.com/user/wallpapers/raw/main/dark-forest.jpg"
    mode: "zoom"                    # zoom, center, tile, scale, span
    # Or local path:
    # path: "~/Pictures/wallpapers/forest.jpg"
  
  # Plymouth boot theme (future)
  plymouth:
    theme: "bgrt"
```

---

### `secrets` (Optional)

Secret references (values never stored in config).

```yaml
secrets:
  # SSH keys
  ssh:
    private_key:
      source: sops
      file: "secrets/ssh/id_ed25519.enc.yaml"
      path: "data.id_ed25519"
    
    known_hosts:
      source: sops
      file: "secrets/ssh/known_hosts.enc.yaml"
  
  # GPG keys
  gpg:
    private_key:
      source: sops
      file: "secrets/gpg/private-key.asc.enc.yaml"
  
  # API tokens
  api_tokens:
    github:
      source: env
      var: "GITHUB_TOKEN"
      required: true
    
    openai:
      source: bitwarden
      item: "OpenAI API Key"
      field: "password"
    
    aws:
      source: aws-vault
      profile: "default"
    
    digitalocean:
      source: sops
      file: "secrets/api/digitalocean.enc.yaml"
      path: "data.token"
  
  # Database passwords
  databases:
    postgres:
      dev:
        source: sops
        file: "secrets/db/dev-postgres.enc.yaml"
  
  # VPN credentials
  vpn:
    mullvad:
      source: sops
      file: "secrets/vpn/mullvad.enc.yaml"
      path: "data.account_number"
  
  # Custom commands
  custom:
    my_secret:
      source: command
      command: "pass show myapp/api-key"
```

**Secret Source Types:**

| Source | Description | Example |
|--------|-------------|---------|
| `sops` | Mozilla SOPS encrypted file | `file: "secrets/db.yaml", path: "data.password"` |
| `env` | Environment variable | `var: "API_TOKEN"` |
| `bitwarden` | Bitwarden password manager | `item: "API Key", field: "password"` |
| `1password` | 1Password password manager | `item: "Database", vault: "Dev"` |
| `vault` | HashiCorp Vault | `path: "secret/data/db", field: "password"` |
| `aws-vault` | AWS credentials | `profile: "default"` |
| `pass` | GNU Pass | `entry: "websites/github"` |
| `command` | Arbitrary shell command | `command: "pass show api-key"` |

---

### `hooks` (Optional)

Lifecycle hooks for custom actions.

```yaml
hooks:
  # Run before any sync operation
  pre-sync: |
    #!/bin/bash
    echo "Starting PDRX sync at $(date)"
    mkdir -p ~/.pdrx/backups
  
  # Run after successful sync
  post-sync: |
    #!/bin/bash
    echo "Sync complete!"
    notify-send "PDRX" "Configuration synced successfully"
  
  # Run before apply operation
  pre-apply: |
    #!/bin/bash
    echo "Preparing to apply configuration..."
    
    # Backup current GNOME extensions
    if [ -d ~/.local/share/gnome-shell/extensions ]; then
      backup_dir="$HOME/.pdrx/backups/gnome-ext-$(date +%s)"
      cp -r ~/.local/share/gnome-shell/extensions "$backup_dir"
      echo "Backed up GNOME extensions to $backup_dir"
    fi
  
  # Run after successful apply
  post-apply: |
    #!/bin/bash
    echo "Configuration applied successfully!"
    
    # Restart GNOME Shell if extensions changed
    if command -v gnome-shell &> /dev/null; then
      echo "Restarting GNOME Shell..."
      killall gnome-shell || true
    fi
    
    # Start user services
    systemctl --user start syncthing || true
    
    notify-send "PDRX" "System configuration applied" --urgency=critical
  
  # Run before package operations
  pre-package: |
    #!/bin/bash
    # Example: Check disk space
    available=$(df / | tail -1 | awk '{print $4}')
    if [ "$available" -lt 1000000 ]; then
      echo "WARNING: Low disk space"
    fi
  
  post-package: |
    #!/bin/bash
    echo "Package operations complete"
  
  # Run on errors
  on-error: |
    #!/bin/bash
    echo "ERROR: PDRX operation failed"
    notify-send "PDRX Error" "Configuration failed - check logs" --urgency=critical
```

---

### `validation` (Optional)

Validation rules for configuration integrity.

```yaml
validation:
  # Required packages (must be present in config)
  require_packages:
    - git
    - curl
    - vim
  
  # Required services
  require_services:
    - ssh
  
  # Package conflicts (warn if both present)
  conflicts:
    - [nvim, vim]                  # Warn if both vim and nvim
    - [docker.io, docker-ce]     # Conflicting docker packages
    - [firefox, firefox-esr]
  
  # OS requirements
  require_os:
    distribution: "debian"          # or "ubuntu", "fedora", etc.
    min_version: "12"               # Debian Bookworm
  
  # Disk space requirements (MB)
  require_disk_space: 5000
  
  # Network requirements
  require_network: true
  
  # Validation hooks
  custom: |
    #!/bin/bash
    # Custom validation script
    if [ ! -f ~/.ssh/id_ed25519 ]; then
      echo "WARNING: SSH key not found"
    fi
```

---

## JSON Schema

Complete JSON Schema for machine validation:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://pdrx.dev/schemas/config-v2.0.json",
  "title": "PDRX Configuration Schema v2.0",
  "description": "Schema for PDRX v2.0 system configuration files",
  "type": "object",
  "required": ["pdrx"],
  "properties": {
    "pdrx": {
      "type": "object",
      "description": "PDRX metadata",
      "required": ["version"],
      "properties": {
        "version": {
          "type": "string",
          "enum": ["2.0"],
          "description": "Configuration schema version"
        },
        "created_at": {
          "type": "string",
          "format": "date-time",
          "description": "ISO 8601 creation timestamp"
        },
        "last_sync": {
          "type": "string",
          "format": "date-time",
          "description": "ISO 8601 last sync timestamp"
        },
        "hostname": {
          "type": "string",
          "description": "System hostname"
        },
        "profile": {
          "type": "string",
          "description": "Active profile name"
        },
        "migrated_from": {
          "type": "string",
          "description": "Previous version if migrated"
        },
        "migrated_at": {
          "type": "string",
          "format": "date-time",
          "description": "Migration timestamp"
        }
      }
    },
    "inherits": {
      "type": "array",
      "description": "Profile inheritance chain",
      "items": {
        "type": "string"
      }
    },
    "machine": {
      "type": "object",
      "description": "Machine-level configuration",
      "properties": {
        "hostname": {"type": "string"},
        "timezone": {"type": "string"},
        "locale": {"type": "string"},
        "kernel_modules": {
          "type": "array",
          "items": {"type": "string"}
        },
        "bootloader": {
          "type": "string",
          "enum": ["systemd-boot", "grub", "lilo"]
        },
        "network": {
          "type": "object",
          "properties": {
            "static_ip": {"type": "boolean"},
            "interface": {"type": "string"},
            "address": {"type": "string"},
            "gateway": {"type": "string"},
            "dns": {
              "type": "array",
              "items": {"type": "string"}
            }
          }
        }
      }
    },
    "users": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["username"],
        "properties": {
          "username": {"type": "string"},
          "full_name": {"type": "string"},
          "shell": {"type": "string"},
          "groups": {
            "type": "array",
            "items": {"type": "string"}
          },
          "password": {"$ref": "#/definitions/secret_reference"},
          "ssh_authorized_keys": {
            "type": "array",
            "items": {"type": "string"}
          },
          "home": {
            "type": "object",
            "properties": {
              "create": {"type": "boolean"},
              "permissions": {"type": "string"}
            }
          },
          "homed": {"type": "boolean"},
          "packages": {"$ref": "#/definitions/package_manager_config"}
        }
      }
    },
    "packages": {"$ref": "#/definitions/package_manager_config"},
    "apt": {
      "type": "object",
      "properties": {
        "repos": {
          "type": "object",
          "additionalProperties": {
            "type": "object",
            "properties": {
              "name": {"type": "string"},
              "enabled": {"type": "boolean"},
              "types": {
                "type": "array",
                "items": {"type": "string"}
              },
              "architectures": {
                "type": "array",
                "items": {"type": "string"}
              },
              "uris": {
                "type": "array",
                "items": {"type": "string"}
              },
              "suites": {
                "type": "array",
                "items": {"type": "string"}
              },
              "components": {
                "type": "array",
                "items": {"type": "string"}
              },
              "signed_by": {"type": "string"},
              "key_url": {"type": "string"},
              "key_content": {"type": "string"}
            }
          }
        },
        "preferences": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "package": {"type": "string"},
              "pin": {"type": "string"},
              "priority": {"type": "integer"}
            }
          }
        }
      }
    },
    "flatpak": {
      "type": "object",
      "properties": {
        "remotes": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["name", "url"],
            "properties": {
              "name": {"type": "string"},
              "url": {"type": "string"},
              "gpg": {"type": "string"},
              "type": {"type": "string", "enum": ["system", "user"]}
            }
          }
        },
        "apps": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["id"],
            "properties": {
              "id": {"type": "string"},
              "remote": {"type": "string"},
              "branch": {"type": "string"},
              "installation": {"type": "string", "enum": ["system", "user"]}
            }
          }
        }
      }
    },
    "services": {
      "type": "object",
      "properties": {
        "enabled": {
          "type": "array",
          "items": {"type": "string"}
        },
        "disabled": {
          "type": "array",
          "items": {"type": "string"}
        },
        "masked": {
          "type": "array",
          "items": {"type": "string"}
        },
        "custom": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": {"type": "string"},
              "type": {"type": "string", "enum": ["user", "system"]},
              "enabled": {"type": "boolean"},
              "description": {"type": "string"},
              "exec_start": {"type": "string"},
              "restart": {"type": "string"},
              "unit_file": {"type": "string"}
            }
          }
        }
      }
    },
    "desktop": {
      "type": "object",
      "properties": {
        "environment": {
          "type": "string",
          "enum": ["gnome", "kde", "xfce", "i3", "sway", "hyprland"]
        },
        "session_manager": {"type": "string"},
        "gnome": {"$ref": "#/definitions/gnome_config"}
      }
    },
    "containers": {
      "type": "object",
      "properties": {
        "docker": {"$ref": "#/definitions/container_config"},
        "podman": {"$ref": "#/definitions/container_config"}
      }
    },
    "vms": {
      "type": "object",
      "properties": {
        "libvirt": {
          "type": "array",
          "items": {"$ref": "#/definitions/libvirt_vm_config"}
        },
        "virtualbox": {
          "type": "array",
          "items": {"$ref": "#/definitions/vbox_vm_config"}
        }
      }
    },
    "dotfiles": {"$ref": "#/definitions/dotfiles_config"},
    "fonts": {"$ref": "#/definitions/fonts_config"},
    "apps": {"type": "object"},
    "themes": {"$ref": "#/definitions/themes_config"},
    "secrets": {"type": "object"},
    "hooks": {"type": "object"},
    "validation": {"type": "object"}
  },
  "definitions": {
    "secret_reference": {
      "type": "object",
      "required": ["source"],
      "properties": {
        "source": {
          "type": "string",
          "enum": ["sops", "env", "bitwarden", "1password", "vault", "aws-vault", "pass", "command"]
        }
      }
    },
    "package_manager_config": {
      "type": "object",
      "properties": {
        "apt": {
          "type": "array",
          "items": {
            "oneOf": [
              {"type": "string"},
              {
                "type": "object",
                "required": ["name"],
                "properties": {
                  "name": {"type": "string"},
                  "version": {"type": "string"},
                  "repo": {"type": "string"},
                  "alternatives": {
                    "type": "array",
                    "items": {"type": "string"}
                  }
                }
              }
            ]
          }
        },
        "flatpak": {
          "type": "array",
          "items": {
            "oneOf": [
              {"type": "string"},
              {
                "type": "object",
                "properties": {
                  "id": {"type": "string"},
                  "remote": {"type": "string"},
                  "version": {"type": "string"},
                  "installation": {"type": "string"}
                }
              }
            ]
          }
        },
        "cargo": {
          "type": "array",
          "items": {
            "oneOf": [
              {"type": "string"},
              {
                "type": "object",
                "properties": {
                  "name": {"type": "string"},
                  "version": {"type": "string"},
                  "features": {
                    "type": "array",
                    "items": {"type": "string"}
                  }
                }
              }
            ]
          }
        },
        "brew": {
          "type": "array",
          "items": {"type": "string"}
        },
        "snap": {
          "type": "array",
          "items": {
            "oneOf": [
              {"type": "string"},
              {
                "type": "object",
                "properties": {
                  "name": {"type": "string"},
                  "channel": {"type": "string"},
                  "classic": {"type": "boolean"}
                }
              }
            ]
          }
        },
        "nix": {
          "type": "array",
          "items": {"type": "string"}
        }
      }
    },
    "gnome_config": {
      "type": "object",
      "properties": {
        "extensions": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["uuid"],
            "properties": {
              "uuid": {"type": "string"},
              "name": {"type": "string"},
              "version": {"type": "string"},
              "source": {"type": "string"},
              "url": {"type": "string"},
              "settings": {"type": "object"}
            }
          }
        },
        "settings": {"type": "object"},
        "keybindings": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["name", "command", "binding"],
            "properties": {
              "name": {"type": "string"},
              "command": {"type": "string"},
              "binding": {"type": "string"}
            }
          }
        },
        "favorites": {
          "type": "array",
          "items": {"type": "string"}
        }
      }
    },
    "container_config": {
      "type": "object",
      "properties": {
        "images": {
          "type": "array",
          "items": {"type": "string"}
        },
        "containers": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["name", "image"],
            "properties": {
              "name": {"type": "string"},
              "image": {"type": "string"},
              "command": {"type": "string"},
              "volumes": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "source": {"type": "string"},
                    "target": {"type": "string"},
                    "mode": {"type": "string"}
                  }
                }
              },
              "ports": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "host": {},
                    "container": {}
                  }
                }
              },
              "env": {"type": "object"},
              "capabilities": {
                "type": "array",
                "items": {"type": "string"}
              },
              "restart": {"type": "string"},
              "autostart": {"type": "boolean"}
            }
          }
        }
      }
    },
    "libvirt_vm_config": {
      "type": "object",
      "properties": {
        "name": {"type": "string"},
        "title": {"type": "string"},
        "os_type": {"type": "string"},
        "os_variant": {"type": "string"},
        "hardware": {
          "type": "object",
          "properties": {
            "memory": {"type": "integer"},
            "vcpus": {"type": "integer"},
            "cpu_mode": {"type": "string"},
            "disk": {
              "type": "array",
              "items": {"type": "object"}
            },
            "network": {
              "type": "object",
              "properties": {
                "type": {"type": "string"},
                "source": {"type": "string"},
                "mac": {"type": "string"}
              }
            },
            "graphics": {"type": "object"}
          }
        },
        "autostart": {"type": "boolean"},
        "xml_template": {"type": "string"}
      }
    },
    "vbox_vm_config": {
      "type": "object",
      "properties": {
        "name": {"type": "string"},
        "os": {"type": "string"},
        "memory": {"type": "integer"},
        "cpus": {"type": "integer"},
        "disk": {"type": "object"},
        "network": {"type": "array"},
        "autostart": {"type": "boolean"}
      }
    },
    "dotfiles_config": {
      "type": "object",
      "properties": {
        "native": {
          "type": "object",
          "properties": {
            "enabled": {"type": "boolean"},
            "strategy": {"type": "string"},
            "repo": {"type": "string"},
            "branch": {"type": "string"},
            "tracked": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "source": {"type": "string"},
                  "target": {"type": "string"},
                  "template": {"type": "boolean"}
                }
              }
            },
            "template_variables": {"type": "object"}
          }
        },
        "chezmoi": {
          "type": "object",
          "properties": {
            "enabled": {"type": "boolean"},
            "repo": {"type": "string"},
            "branch": {"type": "string"},
            "apply": {"type": "boolean"}
          }
        },
        "stow": {
          "type": "object",
          "properties": {
            "enabled": {"type": "boolean"},
            "packages": {
              "type": "array",
              "items": {"type": "string"}
            },
            "target": {"type": "string"}
          }
        }
      }
    },
    "fonts_config": {
      "type": "object",
      "properties": {
        "system": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": {"type": "string"},
              "source": {"type": "string"},
              "package": {"type": "string"}
            }
          }
        },
        "user": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": {"type": "string"},
              "source": {"type": "string"},
              "path": {"type": "string"},
              "extract_to": {"type": "string"}
            }
          }
        },
        "config": {
          "type": "object",
          "properties": {
            "monospace": {"type": "string"},
            "sans_serif": {"type": "string"},
            "serif": {"type": "string"},
            "hinting": {"type": "boolean"},
            "antialiasing": {"type": "boolean"},
            "dpi": {"type": "integer"}
          }
        }
      }
    },
    "themes_config": {
      "type": "object",
      "properties": {
        "gtk": {
          "type": "object",
          "properties": {
            "theme": {"type": "string"},
            "icon_theme": {"type": "string"},
            "cursor_theme": {"type": "string"},
            "font": {"type": "string"},
            "document_font": {"type": "string"},
            "monospace_font": {"type": "string"}
          }
        },
        "cursor": {
          "type": "object",
          "properties": {
            "theme": {"type": "string"},
            "size": {"type": "integer"}
          }
        },
        "wallpaper": {
          "type": "object",
          "properties": {
            "source": {"type": "string"},
            "path": {"type": "string"},
            "mode": {"type": "string"}
          }
        }
      }
    }
  }
}
```

---

## Migration from v1.0

### Automatic Migration

```bash
# Auto-migrate v1.0 config to v2.0
pdrx migrate --to v2.0

# Preview changes
pdrx migrate --to v2.0 --dry-run

# Keep v1.0 as backup
pdrx migrate --to v2.0 --backup
```

### Manual Migration Path

1. **v1.0 packages.conf**:
   ```
   apt:vim
   apt:tmux
   cargo:ripgrep
   flatpak:org.mozilla.firefox
   ```

2. **v2.0 machine.yaml**:
   ```yaml
   pdrx:
     version: "2.0"
     migrated_from: "1.0"
   
   packages:
     apt:
       - vim
       - tmux
     cargo:
       - ripgrep
     flatpak:
       apps:
         - id: org.mozilla.firefox
   ```

---

## Validation Examples

### Valid Configuration

```bash
$ pdrx config validate
✓ Configuration is valid (machine.yaml)
✓ Profile inheritance resolved: base → workstation
✓ Schema validation passed
✓ Secret references resolvable
✓ APT repository URLs reachable
```

### Invalid Configuration

```bash
$ pdrx config validate
✗ Configuration validation failed

  Error at packages.apt:
    Package "docker-ce" references repo "docker" 
    but apt.repos.docker is not defined

  Error at desktop.gnome.extensions[0]:
    Field "uuid" is required

  Error at secrets.api_tokens.github:
    Source "env" requires field "var"
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2025-01 | Complete rewrite with YAML, inheritance, and extensibility |
| 1.1 | 2024-06 | Added desktop export, version pinning |
| 1.0 | 2024-01 | Initial release (packages.conf format) |

---

*PDRX Configuration Schema v2.0 - https://pdrx.dev/schemas/config-v2.0.json*
