# Formula/pdrx.rb
#
# Homebrew tap formula for pdrx — Portable Dynamic Reproducible gnu/linuX.
#
# Install stable (latest tagged release):
#   brew tap stefan-hacks/pdrx https://github.com/stefan-hacks/pdrx
#   brew install pdrx
#
# Install HEAD (latest commit on main):
#   brew install --HEAD pdrx
#
# Upgrade to the latest release:
#   brew upgrade pdrx
#
# The sha256 below is updated automatically by .github/workflows/release.yml
# every time a new tag is pushed.  Do NOT edit it by hand.

class Pdrx < Formula
  desc "Imperative install/remove with automatic declarative config sync across Linux distros"
  homepage "https://github.com/stefan-hacks/pdrx"

  # ── Stable release (updated by GitHub Actions on every git tag) ────────────
  url "https://github.com/stefan-hacks/pdrx/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "6d9ac2bb907d8b82b85493af15fcf0f9077a884a16be98665733babe58ab4e14"
  version "1.5.0"
  license "MIT"

  # ── HEAD – always the very tip of main ────────────────────────────────────
  head "https://github.com/stefan-hacks/pdrx.git", branch: "main"

  # Pure Bash – no compiled dependencies.
  # bash 3.2 ships with macOS; Linux distros have bash 4+.
  # No bottle block needed (script installs as-is on any arch/OS).

  def install
    bin.install "pdrx"
    man1.install "pdrx.1"
  end

  def post_install
    ohai "Run `pdrx init` to initialise your declarative config."
    ohai "Then `pdrx sync` to capture your existing packages."
  end

  test do
    # --version must print "pdrx <semver>" and exit 0
    assert_match(/\Apdrx \d+\.\d+\.\d+/, shell_output("#{bin}/pdrx --version"))
    # --help must mention the init command
    assert_match "init", shell_output("#{bin}/pdrx --help")
  end
end
