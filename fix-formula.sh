#!/usr/bin/env bash
# fix-formula.sh
#
# Run this ONCE from the root of your local pdrx repo to:
#   1. Create the v1.5.0 git tag (if it doesn't exist yet)
#   2. Compute the real sha256 of the release tarball
#   3. Patch Formula/pdrx.rb with the correct url / sha256 / version
#   4. Commit and push everything (tag + formula)
#
# Usage:
#   cd ~/path/to/pdrx
#   bash fix-formula.sh
#
# Requirements: git, curl (or wget), sha256sum (or shasum on macOS)

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
REPO="stefan-hacks/pdrx"
TAG="v1.6.0"
VERSION="${TAG#v}"
FORMULA="Formula/pdrx.rb"
BRANCH="main"
# ─────────────────────────────────────────────────────────────────────────────

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
NC=$'\033[0m'

info() { echo "${CYAN}[info]${NC} $*"; }
success() { echo "${GREEN}[ok]${NC}   $*"; }
warn() { echo "${YELLOW}[warn]${NC} $*"; }
die() {
  echo "${RED}[error]${NC} $*" >&2
  exit 1
}

# ── Sanity checks ─────────────────────────────────────────────────────────────
[ -f "pdrx" ] || die "Run this script from the root of the pdrx repo."
[ -f "$FORMULA" ] || die "$FORMULA not found."
command -v git >/dev/null 2>&1 || die "git not found."
if command -v curl >/dev/null 2>&1; then HAS_CURL=true; else HAS_CURL=false; fi
if command -v wget >/dev/null 2>&1; then HAS_WGET=true; else HAS_WGET=false; fi
"$HAS_CURL" || "$HAS_WGET" || die "curl or wget is required."

# sha256sum (Linux) or shasum -a 256 (macOS)
SHA_CMD=""
if command -v sha256sum >/dev/null 2>&1; then
  SHA_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  SHA_CMD="shasum -a 256"
else
  die "sha256sum / shasum not found."
fi

echo ""
echo "${BOLD}${CYAN}━━━ pdrx Homebrew formula fix ━━━${NC}"
echo ""

# ── Step 1: Make sure VERSION in the script matches ───────────────────────────
SCRIPT_VER=$(grep '^VERSION=' pdrx | head -1 | tr -d '"' | cut -d= -f2)
if [ "$SCRIPT_VER" != "$VERSION" ]; then
  warn "pdrx script has VERSION=\"$SCRIPT_VER\" but we're tagging $TAG."
  warn "Updating VERSION in the pdrx script to $VERSION ..."
  # Use sed that works on both GNU and BSD/macOS
  if sed --version >/dev/null 2>&1; then
    # GNU sed
    sed -i "s/^VERSION=.*/VERSION=\"${VERSION}\"/" pdrx
  else
    # BSD sed (macOS)
    sed -i '' "s/^VERSION=.*/VERSION=\"${VERSION}\"/" pdrx
  fi
  git add pdrx
  git commit -m "chore: set VERSION to ${VERSION}"
fi

# ── Step 2: Create the git tag if it doesn't exist ───────────────────────────
if git rev-parse "$TAG" >/dev/null 2>&1; then
  success "Tag $TAG already exists locally."
else
  info "Creating annotated tag $TAG ..."
  git tag -a "$TAG" -m "Release $TAG"
  success "Tag $TAG created."
fi

# ── Step 3: Push to GitHub (tag must exist on remote for the tarball URL to work) ─
info "Pushing branch $BRANCH and tag $TAG to origin ..."
git push origin "$BRANCH" --quiet
git push origin "$TAG" --quiet
success "Pushed. Waiting 3 s for GitHub to build the archive ..."
sleep 3

# ── Step 4: Compute sha256 of the release tarball ─────────────────────────────
TARBALL_URL="https://github.com/${REPO}/archive/refs/tags/${TAG}.tar.gz"
info "Fetching $TARBALL_URL ..."

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

if "$HAS_CURL"; then
  curl -fsSL "$TARBALL_URL" -o "$TMP"
else
  wget -qO "$TMP" "$TARBALL_URL"
fi

SHA256=$(${SHA_CMD} "$TMP" | awk '{print $1}')
success "sha256: $SHA256"

# ── Step 5: Patch Formula/pdrx.rb ─────────────────────────────────────────────
info "Patching $FORMULA ..."

# Build the expected URL line
NEW_URL="https://github.com/${REPO}/archive/refs/tags/${TAG}.tar.gz"

# Patch with sed (handles both GNU and BSD)
if sed --version >/dev/null 2>&1; then
  # GNU sed
  sed -i \
    -e "s|url \"https://github.com/${REPO}/archive/refs/tags/v[^\"]*\"|url \"${NEW_URL}\"|" \
    -e "s|sha256 \"[^\"]*\"|sha256 \"${SHA256}\"|" \
    -e "s|HOMEBREW_SHA256_PLACEHOLDER|${SHA256}|" \
    -e "s|version \"[^\"]*\"|version \"${VERSION}\"|" \
    "$FORMULA"
else
  # BSD sed (macOS)
  sed -i '' \
    -e "s|url \"https://github.com/${REPO}/archive/refs/tags/v[^\"]*\"|url \"${NEW_URL}\"|" \
    -e "s|sha256 \"[^\"]*\"|sha256 \"${SHA256}\"|" \
    -e "s|HOMEBREW_SHA256_PLACEHOLDER|${SHA256}|" \
    -e "s|version \"[^\"]*\"|version \"${VERSION}\"|" \
    "$FORMULA"
fi

echo ""
echo "${BOLD}Updated formula lines:${NC}"
grep -E 'url |sha256 |version ' "$FORMULA" | sed 's/^/  /'
echo ""

# ── Step 6: Commit and push the updated formula ───────────────────────────────
if git diff --quiet "$FORMULA"; then
  warn "Formula was already up to date — nothing to commit."
else
  info "Committing updated $FORMULA ..."
  git add "$FORMULA"
  git commit -m "chore: update homebrew formula to ${TAG}"
  git push origin "$BRANCH" --quiet
  success "Formula committed and pushed."
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "${BOLD}${GREEN}All done! To install the updated formula:${NC}"
echo ""
echo "  brew untap stefan-hacks/pdrx 2>/dev/null || true"
echo "  brew tap stefan-hacks/pdrx https://github.com/stefan-hacks/pdrx"
echo "  brew install pdrx"
echo ""
echo "Or if already tapped, just upgrade:"
echo "  brew update && brew upgrade pdrx"
echo ""
