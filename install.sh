#!/usr/bin/env bash
# pdrx installer - One-line install script
# Usage: curl -fsSL https://github.com/stefan-hacks/pdrx/releases/latest/download/install.sh | bash

set -euo pipefail

REPO="stefan-hacks/pdrx"
INSTALL_DIR="${HOME}/.local/bin"
MAN_DIR="${HOME}/.local/share/man/man1"

echo "━━━ Installing pdrx ━━━"

# Detect latest version
echo "[INFO] Detecting latest release..."
LATEST_URL=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/') || {
    echo "[ERROR] Failed to detect latest release"
    exit 1
}

TAG="${LATEST_URL}"
echo "[INFO] Latest version: ${TAG}"

# Create directories
mkdir -p "${INSTALL_DIR}" "${MAN_DIR}"

# Download binary
echo "[INFO] Downloading pdrx..."
BINARY_URL="https://github.com/${REPO}/releases/download/${TAG}/pdrx"
if ! curl -fsSL "${BINARY_URL}" -o "${INSTALL_DIR}/pdrx"; then
    echo "[ERROR] Failed to download pdrx binary"
    exit 1
fi
chmod +x "${INSTALL_DIR}/pdrx"
echo "[SUCCESS] Installed binary to ${INSTALL_DIR}/pdrx"

# Download manpage
echo "[INFO] Downloading manpage..."
MANPAGE_URL="https://github.com/${REPO}/releases/download/${TAG}/pdrx.1"
if curl -fsSL "${MANPAGE_URL}" -o "${MAN_DIR}/pdrx.1" 2>/dev/null; then
    echo "[SUCCESS] Installed manpage to ${MAN_DIR}/pdrx.1"
else
    echo "[WARNING] Manpage download failed (optional)"
fi

# Update PATH if needed
if ! echo "$PATH" | grep -q "${INSTALL_DIR}"; then
    echo ""
    echo "━━━ PATH Configuration ━━━"
    echo "${INSTALL_DIR} is not in your PATH."
    echo ""
    
    # Add to shell configs
    for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
        if [ -f "$rc" ]; then
            if ! grep -q "${INSTALL_DIR}" "$rc" 2>/dev/null; then
                echo "[INFO] Adding ${INSTALL_DIR} to PATH in ${rc}"
                printf '\n# Added by pdrx installer\nexport PATH="$PATH:%s"\n' "${INSTALL_DIR}" >> "$rc"
            fi
        fi
    done
    
    echo ""
    echo "[INFO] Run: source ~/.bashrc  # or restart your terminal"
fi

echo ""
echo "━━━ Installation Complete ━━━"
echo "Version: $(${INSTALL_DIR}/pdrx --version 2>/dev/null || echo 'unknown')"
echo ""
echo "Next steps:"
echo "  1. Run: source ~/.bashrc"
echo "  2. Run: pdrx init"
echo ""
echo "Documentation: man pdrx  # or pdrx --help"
