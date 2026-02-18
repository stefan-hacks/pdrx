# Homebrew formula for pdrx - Portable Dynamic Reproducible gnu/linuX
# Install: brew tap stefan-hacks/pdrx https://github.com/stefan-hacks/pdrx && brew install pdrx
# Or with a dedicated tap repo (homebrew-pdrx): brew tap stefan-hacks/pdrx && brew install pdrx
#
# When releasing a new version, update url and sha256, then:
#   curl -sSL "https://github.com/stefan-hacks/pdrx/archive/refs/tags/vX.Y.Z.tar.gz" | shasum -a 256

class Pdrx < Formula
  desc "Portable Dynamic Reproducible gnu/linuX - reproducible Linux/macOS system setup"
  homepage "https://github.com/stefan-hacks/pdrx"
  url "https://github.com/stefan-hacks/pdrx/archive/refs/tags/v1.4.8.tar.gz"
  sha256 "d5558cd419c8d46bdc958064cb97f963d1ea793866414c025906ec15033512ed"
  license "MIT"
  head "https://github.com/stefan-hacks/pdrx.git", branch: "main"

  def install
    bin.install "pdrx"
    man1.install "pdrx.1"
  end

  test do
    assert_match "1.4.8", shell_output("#{bin}/pdrx -v")
    assert_match "pdrx", shell_output("#{bin}/pdrx --help", 0)
  end
end
