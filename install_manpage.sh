#!/usr/bin/env bash
#
# install_manpage.sh - Install pdrx man page so "man pdrx" works
# Usage: ./install_manpage.sh [--user|--system]
#   --user   Install to ~/.local/share/man/man1 (default, no root)
#   --system Install to /usr/local/share/man/man1 (requires root)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
MANPAGE_SRC="${SCRIPT_DIR}/pdrx.1"
MAN_SECTION="man1"
PAGE_NAME="pdrx.1"

usage() {
  echo "Usage: $0 [--user|--system]"
  echo "  --user   Install to \$HOME/.local/share/man/man1 (default)"
  echo "  --system Install to /usr/local/share/man/man1 (requires root)"
  exit 0
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
fi

if [ ! -f "$MANPAGE_SRC" ]; then
  echo "Error: man page not found: $MANPAGE_SRC" >&2
  exit 1
fi

INSTALL_MODE="${1:---user}"
MANDIR=""

case "$INSTALL_MODE" in
  --user)
    MANDIR="${HOME:?}/.local/share/man/${MAN_SECTION}"
    ;;
  --system)
    MANDIR="/usr/local/share/man/${MAN_SECTION}"
    if [ "$(id -u)" -ne 0 ]; then
      echo "Error: --system requires root. Use: sudo $0 --system" >&2
      exit 1
    fi
    ;;
  *)
    echo "Error: unknown option '$INSTALL_MODE'" >&2
    usage
    ;;
esac

mkdir -p "$MANDIR"
cp -f "$MANPAGE_SRC" "$MANDIR/$PAGE_NAME"
chmod 644 "$MANDIR/$PAGE_NAME"
echo "Installed man page to $MANDIR/$PAGE_NAME"

# Update man database if available (so 'man pdrx' finds the page)
if command -v mandb >/dev/null 2>&1; then
  if [ "$INSTALL_MODE" = "--system" ]; then
    mandb -q 2>/dev/null || true
  else
    mandb -q -s "$HOME/.local/share/man" 2>/dev/null || true
  fi
elif command -v makewhatis >/dev/null 2>&1; then
  makewhatis "$MANDIR" 2>/dev/null || true
fi

# Remind user about MANPATH for --user install
if [ "$INSTALL_MODE" = "--user" ]; then
  USER_MAN_BASE="${HOME}/.local/share/man"
  if [ -n "${MANPATH:-}" ]; then
    if [[ ":$MANPATH:" != *":$USER_MAN_BASE:"* ]]; then
      echo ""
      echo "To use 'man pdrx' without setting MANPATH, ensure your man path includes:"
      echo "  $USER_MAN_BASE"
      echo "Add to your shell rc (e.g. .bashrc):"
      echo "  export MANPATH=\"\$HOME/.local/share/man:\$MANPATH\""
    fi
  else
    # Many systems search ~/.local/share/man by default; if not, user may need MANPATH
    echo ""
    echo "If 'man pdrx' does not work, add to your shell rc:"
    echo "  export MANPATH=\"\$HOME/.local/share/man:\$MANPATH\""
  fi
fi

echo "Done. Try: man pdrx"
