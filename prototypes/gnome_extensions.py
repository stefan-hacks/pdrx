#!/usr/bin/env python3
"""
PDRX GNOME Extensions Discovery Module
======================================

A standalone prototype for discovering and capturing GNOME Shell extension
current state for reproducible system configuration.

This module discovers:
- Enabled extension UUIDs
- Extension metadata (name, version, download URL)
- Extension settings via dconf/GSettings
- Extension source (user-installed vs system)
- System extensions (warn only - can't be auto-installed)

Usage:
    python3 gnome_extensions.py discover
    python3 gnome_extensions.py discover --output extensions.yaml
    python3 gnome_extensions.py restore --config extensions.yaml
    python3 gnome_extensions.py validate --config extensions.yaml

Author: PDRX Project
License: MIT
"""

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime


# =============================================================================
# Data Structures
# =============================================================================

@dataclass
class ExtensionSettings:
    """Extension settings from dconf."""
    schema: str
    values: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict:
        return {"schema": self.schema, "values": self.values}


@dataclass
class ExtensionInfo:
    """Complete extension information."""
    uuid: str
    name: str
    version: str = "unknown"
    description: str = ""
    source: str = "unknown"  # "user", "system", "apt"
    download_url: Optional[str] = None
    settings: Dict[str, Any] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)
    compatible_shell: Optional[str] = None
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for YAML/JSON serialization."""
        result = {
            "uuid": self.uuid,
            "name": self.name,
            "version": self.version,
            "source": self.source,
        }
        
        if self.description:
            result["description"] = self.description
        if self.download_url:
            result["download_url"] = self.download_url
        if self.compatible_shell:
            result["compatible_shell"] = self.compatible_shell
        if self.metadata:
            result["metadata"] = self.metadata
        if self.settings:
            result["settings"] = self.settings
            
        return result


@dataclass
class DiscoveryResult:
    """Result of extension discovery operation."""
    timestamp: str
    gnome_shell_version: str
    extensions: List[ExtensionInfo] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)
    
    def to_dict(self) -> Dict:
        return {
            "timestamp": self.timestamp,
            "gnome_shell_version": self.gnome_shell_version,
            "extensions": [e.to_dict() for e in self.extensions],
            "warnings": self.warnings,
            "errors": self.errors,
        }


# =============================================================================
# Discovery Engine
# =============================================================================

class GnomeExtensionDiscovery:
    """Discovery engine for GNOME Shell extensions."""
    
    # Standard paths
    USER_EXTENSIONS_DIR = Path.home() / ".local/share/gnome-shell/extensions"
    SYSTEM_EXTENSIONS_DIR = Path("/usr/share/gnome-shell/extensions")
    
    # GNOME Shell settings schema
    SHELL_SCHEMA = "org.gnome.shell"
    ENABLED_EXTENSIONS_KEY = "enabled-extensions"
    
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self._shell_version: Optional[str] = None
        
    def log(self, message: str):
        """Print verbose output."""
        if self.verbose:
            print(f"[DISCOVER] {message}")
    
    def discover(self) -> DiscoveryResult:
        """
        Run full discovery of GNOME extensions.
        
        Returns:
            DiscoveryResult with complete extension information
        """
        timestamp = datetime.utcnow().isoformat() + "Z"
        
        # Get GNOME Shell version
        shell_version = self._get_shell_version()
        self.log(f"GNOME Shell version: {shell_version}")
        
        # Initialize result
        result = DiscoveryResult(
            timestamp=timestamp,
            gnome_shell_version=shell_version,
        )
        
        # Check if GNOME is running
        if not self._is_gnome_session():
            result.warnings.append("Not running in a GNOME session. Some features may not work.")
        
        # Get enabled extension UUIDs
        enabled_uuids = self._get_enabled_extensions()
        self.log(f"Found {len(enabled_uuids)} enabled extensions")
        
        # Discover each extension
        for uuid in enabled_uuids:
            try:
                ext_info = self._discover_extension(uuid)
                if ext_info:
                    result.extensions.append(ext_info)
            except Exception as e:
                result.errors.append(f"Failed to discover extension {uuid}: {e}")
        
        # Check for system extensions that can't be auto-installed
        system_exts = self._get_system_extensions()
        user_ext_uuids = {e.uuid for e in result.extensions if e.source == "user"}
        non_reproducible = [uuid for uuid in system_exts if uuid not in user_ext_uuids]
        
        if non_reproducible:
            result.warnings.append(
                f"Found {len(non_reproducible)} system extensions that "
                "may require manual installation: " + ", ".join(non_reproducible[:5])
            )
        
        return result
    
    def _is_gnome_session(self) -> bool:
        """Check if running in a GNOME session."""
        desktop_session = os.environ.get("DESKTOP_SESSION", "").lower()
        xdg_current = os.environ.get("XDG_CURRENT_DESKTOP", "").lower()
        return "gnome" in desktop_session or "gnome" in xdg_current
    
    def _get_shell_version(self) -> str:
        """Get GNOME Shell version."""
        if self._shell_version:
            return self._shell_version
        
        try:
            result = subprocess.run(
                ["gnome-shell", "--version"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                # Output: "GNOME Shell 45.3"
                match = re.search(r'(\d+\.\d+(?:\.\d+)?)', result.stdout)
                if match:
                    self._shell_version = match.group(1)
                    return self._shell_version
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        
        # Fallback: check gsettings
        try:
            result = subprocess.run(
                ["gsettings", "get", "org.gnome.shell", "version"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                self._shell_version = result.stdout.strip().strip("'")
                return self._shell_version
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        
        self._shell_version = "unknown"
        return self._shell_version
    
    def _get_enabled_extensions(self) -> List[str]:
        """Get list of enabled extension UUIDs from gsettings."""
        try:
            result = subprocess.run(
                ["gsettings", "get", self.SHELL_SCHEMA, self.ENABLED_EXTENSIONS_KEY],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                # Parse output: ['uuid1', 'uuid2', 'uuid3']
                output = result.stdout.strip()
                
                # Handle empty list
                if output == "@as []":
                    return []
                
                # Parse Python-like list syntax
                try:
                    # Safe eval alternative
                    uuids = eval(output, {"__builtins__": {}}, {})
                    if isinstance(uuids, list):
                        return [str(u) for u in uuids]
                except Exception:
                    pass
                
                # Manual parsing as fallback
                uuids = []
                for match in re.finditer(r"'([^']+)'", output):
                    uuids.append(match.group(1))
                return uuids
                
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            self.log(f"Failed to get enabled extensions: {e}")
        
        return []
    
    def _discover_extension(self, uuid: str) -> Optional[ExtensionInfo]:
        """
        Discover information about a single extension.
        
        Args:
            uuid: Extension UUID (e.g., "dash-to-dock@micxgx.gmail.com")
        
        Returns:
            ExtensionInfo or None if not found
        """
        self.log(f"Discovering extension: {uuid}")
        
        # Determine extension type and path
        ext_path, source = self._find_extension_path(uuid)
        
        if not ext_path:
            self.log(f"  Extension path not found for {uuid}")
            return ExtensionInfo(
                uuid=uuid,
                name=uuid.split('@')[0],
                source="unknown",
            )
        
        # Parse metadata
        metadata = self._read_metadata(ext_path)
        
        # Get settings from dconf
        settings = self._get_extension_settings(uuid)
        
        # Build ExtensionInfo
        ext_info = ExtensionInfo(
            uuid=uuid,
            name=metadata.get("name", uuid.split('@')[0]),
            version=str(metadata.get("version", "unknown")),
            description=metadata.get("description", ""),
            source=source,
            download_url=metadata.get("url"),
            settings=settings,
            metadata=metadata if self.verbose else {},
            compatible_shell=metadata.get("shell-version", [None])[0] if isinstance(metadata.get("shell-version"), list) else None,
        )
        
        self.log(f"  Found: {ext_info.name} (v{ext_info.version}) from {source}")
        
        return ext_info
    
    def _find_extension_path(self, uuid: str) -> Tuple[Optional[Path], str]:
        """
        Find extension directory and determine source.
        
        Returns:
            Tuple of (path, source) where source is "user", "system", or "apt"
        """
        # Check user extensions first
        user_path = self.USER_EXTENSIONS_DIR / uuid
        if user_path.exists():
            return user_path, "user"
        
        # Check system extensions
        system_path = self.SYSTEM_EXTENSIONS_DIR / uuid
        if system_path.exists():
            # Check if it's from an APT package
            if self._is_apt_extension(uuid):
                return system_path, "apt"
            return system_path, "system"
        
        return None, "unknown"
    
    def _is_apt_extension(self, uuid: str) -> bool:
        """Check if extension is installed via APT."""
        try:
            result = subprocess.run(
                ["dpkg", "-S", f"{uuid}/metadata.json"],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.returncode == 0
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        return False
    
    def _read_metadata(self, ext_path: Path) -> Dict[str, Any]:
        """Read extension metadata.json."""
        metadata_file = ext_path / "metadata.json"
        
        if not metadata_file.exists():
            return {}
        
        try:
            with open(metadata_file, 'r', encoding='utf-8') as f:
                content = f.read()
                # Handle potential BOM
                if content.startswith('\ufeff'):
                    content = content[1:]
                return json.loads(content)
        except json.JSONDecodeError as e:
            self.log(f"  Warning: Failed to parse metadata.json: {e}")
            return {}
        except Exception as e:
            self.log(f"  Warning: Failed to read metadata: {e}")
            return {}
    
    def _get_extension_settings(self, uuid: str) -> Dict[str, Any]:
        """
        Get extension settings from dconf/GSettings.
        
        Extensions typically use schemas like:
        - org.gnome.shell.extensions.{extension-name}
        """
        settings = {}
        
        # Try to determine schema from UUID
        schema_base = self._uuid_to_schema(uuid)
        
        # Get list of schemas this extension might use
        possible_schemas = [
            f"org.gnome.shell.extensions.{schema_base}",
            f"org.gnome.shell.extensions.{uuid.split('@')[0].replace('-', '_')}",
        ]
        
        # Also check metadata for settings schema
        # Some extensions specify this in metadata
        
        for schema in possible_schemas:
            schema_settings = self._read_schema_settings(schema)
            if schema_settings:
                settings[schema] = schema_settings
        
        return settings
    
    def _uuid_to_schema(self, uuid: str) -> str:
        """Convert UUID to likely schema name."""
        # dash-to-dock@micxgx.gmail.com -> dash-to-dock
        base = uuid.split('@')[0]
        # Replace hyphens with underscores for schema naming
        return base.replace('-', '_')
    
    def _read_schema_settings(self, schema: str) -> Optional[Dict[str, Any]]:
        """Read all settings from a GSettings schema."""
        try:
            # First check if schema exists
            result = subprocess.run(
                ["gsettings", "list-schemas"],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode != 0 or schema not in result.stdout:
                return None
            
            # Get all keys in this schema
            keys_result = subprocess.run(
                ["gsettings", "list-keys", schema],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if keys_result.returncode != 0:
                return None
            
            settings = {}
            for key in keys_result.stdout.strip().split('\n'):
                if not key:
                    continue
                
                # Get the value
                val_result = subprocess.run(
                    ["gsettings", "get", schema, key],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                
                if val_result.returncode == 0:
                    value = val_result.stdout.strip()
                    # Try to parse the value
                    parsed_value = self._parse_gsettings_value(value)
                    settings[key] = parsed_value
            
            return settings if settings else None
            
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return None
    
    def _parse_gsettings_value(self, value: str) -> Any:
        """Parse a gsettings value string to Python type."""
        value = value.strip()
        
        # Boolean
        if value == "true":
            return True
        if value == "false":
            return False
        
        # String
        if value.startswith("'") and value.endswith("'"):
            return value[1:-1]
        
        # Double-quoted string
        if value.startswith('"') and value.endswith('"'):
            return value[1:-1]
        
        # Empty list
        if value == "@as []":
            return []
        
        # Try integer
        try:
            return int(value)
        except ValueError:
            pass
        
        # Try float
        try:
            return float(value)
        except ValueError:
            pass
        
        # Try to parse as list
        if value.startswith('[') and value.endswith(']'):
            try:
                return eval(value, {"__builtins__": {}}, {})
            except Exception:
                pass
        
        # Return as-is
        return value
    
    def _get_system_extensions(self) -> List[str]:
        """Get list of all system-installed extensions."""
        extensions = []
        
        if self.SYSTEM_EXTENSIONS_DIR.exists():
            for item in self.SYSTEM_EXTENSIONS_DIR.iterdir():
                if item.is_dir():
                    extensions.append(item.name)
        
        return extensions


# =============================================================================
# Restoration Engine
# =============================================================================

class GnomeExtensionRestore:
    """Restoration engine for GNOME Shell extensions."""
    
    def __init__(self, verbose: bool = False, dry_run: bool = False):
        self.verbose = verbose
        self.dry_run = dry_run
        
    def log(self, message: str):
        """Print verbose output."""
        if self.verbose:
            print(f"[RESTORE] {message}")
    
    def restore(self, config: Dict[str, Any]) -> Tuple[bool, List[str]]:
        """
        Restore extensions from configuration.
        
        Args:
            config: Configuration dictionary with extensions list
        
        Returns:
            Tuple of (success, warnings)
        """
        warnings = []
        extensions = config.get("extensions", [])
        
        if not extensions:
            self.log("No extensions to restore")
            return True, warnings
        
        print(f"Restoring {len(extensions)} extensions...")
        
        # Group by source
        user_extensions = [e for e in extensions if e.get("source") == "user"]
        apt_extensions = [e for e in extensions if e.get("source") == "apt"]
        
        # Restore APT extensions first
        for ext in apt_extensions:
            success, msg = self._restore_apt_extension(ext)
            if not success:
                warnings.append(msg)
        
        # Restore user extensions
        for ext in user_extensions:
            success, msg = self._restore_user_extension(ext)
            if not success:
                warnings.append(msg)
        
        # Apply settings
        for ext in extensions:
            self._apply_extension_settings(ext)
        
        return True, warnings
    
    def _restore_apt_extension(self, ext: Dict) -> Tuple[bool, str]:
        """Restore an APT-installed extension."""
        uuid = ext.get("uuid", "unknown")
        name = ext.get("name", uuid)
        
        self.log(f"Installing APT extension: {name}")
        
        if self.dry_run:
            print(f"[DRY RUN] Would install {uuid} via apt")
            return True, ""
        
        # Try to find the package name
        # Common patterns: gnome-shell-extension-{name}, {name}-extension
        package_names = [
            f"gnome-shell-extension-{name.lower().replace(' ', '-')}",
            f"gnome-shell-extension-{uuid.split('@')[0]}",
        ]
        
        for pkg in package_names:
            try:
                result = subprocess.run(
                    ["apt-get", "install", "-y", pkg],
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                if result.returncode == 0:
                    return True, ""
            except (subprocess.TimeoutExpired, FileNotFoundError):
                pass
        
        return False, f"Could not install APT extension {uuid}"
    
    def _restore_user_extension(self, ext: Dict) -> Tuple[bool, str]:
        """
        Restore a user-installed extension.
        
        This is challenging because extensions.gnome.org requires
        browser-based installation. We provide multiple strategies.
        """
        uuid = ext.get("uuid")
        name = ext.get("name", uuid)
        version = ext.get("version")
        
        self.log(f"Restoring user extension: {name} ({uuid})")
        
        if self.dry_run:
            print(f"[DRY RUN] Would install {uuid} from extensions.gnome.org")
            return True, ""
        
        # Check if already installed
        ext_path = Path.home() / ".local/share/gnome-shell/extensions" / uuid
        if ext_path.exists():
            self.log(f"  Extension already installed: {uuid}")
            return True, ""
        
        # Method 1: Try gnome-extensions CLI
        try:
            result = subprocess.run(
                ["gnome-extensions", "install", uuid],
                capture_output=True,
                text=True,
                timeout=30
            )
            if result.returncode == 0:
                self.log(f"  Installed via gnome-extensions CLI")
                return True, ""
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        
        # Method 2: Download from extensions.gnome.org directly
        try:
            success = self._download_from_ego(uuid, version)
            if success:
                self.log(f"  Downloaded from extensions.gnome.org")
                return True, ""
        except Exception as e:
            self.log(f"  Download failed: {e}")
        
        # Method 3: Provide manual instructions
        url = ext.get("download_url") or f"https://extensions.gnome.org/extension/{self._uuid_to_ego_id(uuid)}/"
        
        print(f"\n⚠️  Could not auto-install extension: {name}")
        print(f"   Please install manually from: {url}")
        print(f"   UUID: {uuid}")
        
        return False, f"Manual installation required for {uuid}"
    
    def _uuid_to_ego_id(self, uuid: str) -> str:
        """
        Convert UUID to extensions.gnome.org extension ID.
        
        Unfortunately there's no direct mapping, but we can try common patterns.
        """
        # This is a best-effort mapping
        # Real implementation would need a lookup table or API
        return "search"
    
    def _download_from_ego(self, uuid: str, version: Optional[str]) -> bool:
        """
        Download and install extension from extensions.gnome.org.
        
        Note: This requires knowing the extension ID on EGO, which
        is not the same as the UUID. The EGO API can look this up.
        """
        # This is a simplified implementation
        # Real implementation would need to:
        # 1. Query EGO API to get extension ID from UUID
        # 2. Download the ZIP for the appropriate version
        # 3. Extract to ~/.local/share/gnome-shell/extensions/
        
        import urllib.request
        import zipfile
        
        ext_dir = Path.home() / ".local/share/gnome-shell/extensions" / uuid
        
        # Try to download (requires extension ID, which we don't have)
        # This is where an EGO API lookup would happen
        
        return False
    
    def _apply_extension_settings(self, ext: Dict):
        """Apply extension settings via gsettings."""
        settings = ext.get("settings", {})
        
        if not settings:
            return
        
        uuid = ext.get("uuid")
        self.log(f"Applying settings for {uuid}")
        
        if self.dry_run:
            print(f"[DRY RUN] Would apply settings for {uuid}")
            return
        
        for schema, values in settings.items():
            for key, value in values.items():
                try:
                    # Convert Python value to gsettings format
                    gval = self._to_gsettings_value(value)
                    
                    subprocess.run(
                        ["gsettings", "set", schema, key, gval],
                        capture_output=True,
                        timeout=5
                    )
                except Exception as e:
                    self.log(f"  Failed to set {schema}.{key}: {e}")
    
    def _to_gsettings_value(self, value: Any) -> str:
        """Convert Python value to gsettings string format."""
        if isinstance(value, bool):
            return "true" if value else "false"
        if isinstance(value, str):
            return f"'{value}'"
        if isinstance(value, (list, tuple)):
            return str(list(value))
        return str(value)


# =============================================================================
# Configuration Generation
# =============================================================================

def generate_pdrx_config(result: DiscoveryResult) -> Dict[str, Any]:
    """
    Generate PDRX v2.0 configuration from discovery result.
    
    Returns:
        Configuration dictionary ready for YAML serialization
    """
    config = {
        "pdrx": {
            "version": "2.0",
            "generated_by": "gnome-extensions-discovery",
            "generated_at": result.timestamp,
            "gnome_shell_version": result.gnome_shell_version,
        },
        "desktop": {
            "environment": "gnome",
            "gnome": {
                "extensions": [ext.to_dict() for ext in result.extensions]
            }
        }
    }
    
    if result.warnings:
        config["_warnings"] = result.warnings
    
    return config


def to_yaml(data: Any, indent: int = 0) -> str:
    """Simple YAML serializer (for prototype - use PyYAML in production)."""
    lines = []
    prefix = "  " * indent
    
    if isinstance(data, dict):
        for key, value in data.items():
            if key.startswith("_"):
                # Comment out warnings
                lines.append(f"# {key}: {value}")
                continue
            
            if isinstance(value, (dict, list)) and value:
                lines.append(f"{prefix}{key}:")
                lines.append(to_yaml(value, indent + 1))
            elif isinstance(value, list):
                lines.append(f"{prefix}{key}: []")
            elif isinstance(value, str):
                # Quote strings with special characters
                if any(c in value for c in [':', '#', '{', '}', '[', ']', ',', '&', '*', '!', '|', '>', "'", '"', '%', '@', '`']):
                    escaped = value.replace('"', '\\"')
                    lines.append(f'{prefix}{key}: "{escaped}"')
                else:
                    lines.append(f"{prefix}{key}: {value}")
            elif isinstance(value, bool):
                lines.append(f"{prefix}{key}: {str(value).lower()}")
            elif value is None:
                lines.append(f"{prefix}{key}: null")
            else:
                lines.append(f"{prefix}{key}: {value}")
    
    elif isinstance(data, list):
        for item in data:
            if isinstance(item, dict):
                # Check if we can use inline format
                if len(item) <= 3 and all(isinstance(v, (str, int, float, bool)) for v in item.values()):
                    items_str = ", ".join(f"{k}: {to_yaml(v, 0).strip()}" for k, v in item.items())
                    lines.append(f"{prefix}- {items_str}")
                else:
                    first = True
                    for k, v in item.items():
                        if first:
                            if isinstance(v, (dict, list)):
                                lines.append(f"{prefix}- {k}:")
                                lines.append(to_yaml(v, indent + 2))
                            else:
                                lines.append(f"{prefix}- {k}: {to_yaml(v, 0).strip()}")
                            first = False
                        else:
                            if isinstance(v, (dict, list)) and v:
                                lines.append(f"{prefix}  {k}:")
                                lines.append(to_yaml(v, indent + 2))
                            else:
                                lines.append(f"{prefix}  {k}: {to_yaml(v, 0).strip()}")
            else:
                lines.append(f"{prefix}- {to_yaml(item, 0).strip()}")
    
    else:
        return str(data)
    
    return '\n'.join(lines)


# =============================================================================
# CLI Interface
# =============================================================================

def cmd_discover(args):
    """Run discovery and output results."""
    print("=" * 60)
    print("PDRX GNOME Extensions Discovery")
    print("=" * 60)
    
    discovery = GnomeExtensionDiscovery(verbose=args.verbose)
    result = discovery.discover()
    
    # Generate configuration
    config = generate_pdrx_config(result)
    
    # Output
    if args.format == "yaml":
        output = to_yaml(config)
    else:
        output = json.dumps(config, indent=2)
    
    if args.output:
        with open(args.output, 'w') as f:
            f.write(output)
        print(f"\n✓ Configuration written to: {args.output}")
    else:
        print("\n" + "=" * 60)
        print("Discovered Configuration:")
        print("=" * 60)
        print(output)
    
    # Print summary
    print("\n" + "=" * 60)
    print("Summary:")
    print(f"  Extensions discovered: {len(result.extensions)}")
    print(f"  GNOME Shell version: {result.gnome_shell_version}")
    
    user_exts = [e for e in result.extensions if e.source == "user"]
    apt_exts = [e for e in result.extensions if e.source == "apt"]
    system_exts = [e for e in result.extensions if e.source == "system"]
    
    print(f"  User extensions: {len(user_exts)}")
    print(f"  APT extensions: {len(apt_exts)}")
    print(f"  System extensions: {len(system_exts)}")
    
    if result.warnings:
        print(f"\n  Warnings ({len(result.warnings)}):")
        for w in result.warnings:
            print(f"    ⚠️  {w}")
    
    if result.errors:
        print(f"\n  Errors ({len(result.errors)}):")
        for e in result.errors:
            print(f"    ❌ {e}")
    
    return 0 if not result.errors else 1


def cmd_restore(args):
    """Restore extensions from configuration."""
    print("=" * 60)
    print("PDRX GNOME Extensions Restore")
    print("=" * 60)
    
    # Load configuration
    if args.config:
        with open(args.config, 'r') as f:
            if args.config.endswith('.json'):
                config = json.load(f)
            else:
                # For YAML, we'd use PyYAML in production
                import yaml
                config = yaml.safe_load(f)
    else:
        print("Error: --config required for restore")
        return 1
    
    # Extract extensions config
    extensions_config = config.get("desktop", {}).get("gnome", {})
    
    restorer = GnomeExtensionRestore(
        verbose=args.verbose,
        dry_run=args.dry_run
    )
    
    success, warnings = restorer.restore(extensions_config)
    
    print("\n" + "=" * 60)
    if success:
        print("✓ Restore completed")
    else:
        print("⚠️  Restore completed with warnings")
    
    if warnings:
        print(f"\n  Warnings ({len(warnings)}):")
        for w in warnings:
            print(f"    ⚠️  {w}")
    
    return 0


def cmd_list(args):
    """List currently enabled extensions."""
    print("=" * 60)
    print("PDRX GNOME Extensions List")
    print("=" * 60)
    
    discovery = GnomeExtensionDiscovery(verbose=args.verbose)
    result = discovery.discover()
    
    print(f"\nGNOME Shell: {result.gnome_shell_version}")
    print(f"Enabled Extensions: {len(result.extensions)}\n")
    
    # Group by source
    sources = {}
    for ext in result.extensions:
        sources.setdefault(ext.source, []).append(ext)
    
    for source in ["apt", "user", "system", "unknown"]:
        if source in sources:
            exts = sources[source]
            print(f"\n{source.upper()} Extensions ({len(exts)}):")
            print("-" * 40)
            for ext in sorted(exts, key=lambda e: e.name):
                print(f"  {ext.name}")
                print(f"    UUID: {ext.uuid}")
                print(f"    Version: {ext.version}")
                if ext.settings:
                    print(f"    Settings: {len(ext.settings)} schema(s)")
                print()
    
    return 0


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="PDRX GNOME Extensions Discovery Module",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s discover                    # Discover and print to stdout
  %(prog)s discover -o extensions.yaml # Save to file
  %(prog)s discover -v                 # Verbose discovery
  %(prog)s list                        # List enabled extensions
  %(prog)s restore -c extensions.yaml  # Restore from config
        """
    )
    
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose output"
    )
    
    subparsers = parser.add_subparsers(dest="command", help="Commands")
    
    # Discover command
    discover_parser = subparsers.add_parser(
        "discover",
        help="Discover current GNOME extensions"
    )
    discover_parser.add_argument(
        "-o", "--output",
        help="Output file (default: stdout)"
    )
    discover_parser.add_argument(
        "-f", "--format",
        choices=["yaml", "json"],
        default="yaml",
        help="Output format (default: yaml)"
    )
    
    # List command
    list_parser = subparsers.add_parser(
        "list",
        help="List enabled extensions"
    )
    
    # Restore command
    restore_parser = subparsers.add_parser(
        "restore",
        help="Restore extensions from configuration"
    )
    restore_parser.add_argument(
        "-c", "--config",
        required=True,
        help="Configuration file to restore from"
    )
    restore_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without making changes"
    )
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        return 1
    
    commands = {
        "discover": cmd_discover,
        "list": cmd_list,
        "restore": cmd_restore,
    }
    
    return commands[args.command](args)


if __name__ == "__main__":
    sys.exit(main())
