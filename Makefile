# Makefile — pdrx
#
# Targets:
#   install         Copy pdrx to ~/.local/bin + man page
#   uninstall       Remove pdrx from ~/.local/bin
#   shellcheck      Run shellcheck on the pdrx script
#   test            Functional self-tests (no external PMs needed)
#   formula-sha     Print the sha256 for the latest tagged release tarball
#   release TAG=X   Tag + push — triggers GitHub Actions to cut a release
#                   and update the Homebrew formula automatically
#   clean           Remove build artefacts

SCRIPT      := pdrx
MANPAGE     := pdrx.1
INSTALL_DIR := $(HOME)/.local/bin
MAN_DIR     := $(HOME)/.local/share/man/man1
FORMULA     := Formula/pdrx.rb

.PHONY: all install uninstall shellcheck test formula-sha release clean

all: shellcheck

# ── Install ──────────────────────────────────────────────────────────────────

install:
	@mkdir -p "$(INSTALL_DIR)" "$(MAN_DIR)"
	@install -m 0755 "$(SCRIPT)" "$(INSTALL_DIR)/$(SCRIPT)"
	@gzip -c "$(MANPAGE)" > "$(MAN_DIR)/$(MANPAGE).gz"
	@echo "Installed $(INSTALL_DIR)/$(SCRIPT)"
	@echo "Man page:  $(MAN_DIR)/$(MANPAGE).gz"
	@echo "Run: pdrx init"

uninstall:
	@rm -f "$(INSTALL_DIR)/$(SCRIPT)" "$(MAN_DIR)/$(MANPAGE).gz"
	@echo "Uninstalled $(INSTALL_DIR)/$(SCRIPT)"

# ── Quality ───────────────────────────────────────────────────────────────────

shellcheck:
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not found; install via apt/brew"; exit 1; }
	shellcheck --severity=style "$(SCRIPT)"
	@echo "shellcheck: OK"

test:
	@echo "=== pdrx functional tests ==="
	@TMPDIR=$$(mktemp -d); \
	 trap 'rm -rf "$$TMPDIR"' EXIT; \
	 PDRX_HOME="$$TMPDIR" bash $(SCRIPT) init -q; \
	 PDRX_HOME="$$TMPDIR" bash $(SCRIPT) --version; \
	 PDRX_HOME="$$TMPDIR" bash $(SCRIPT) status; \
	 PDRX_HOME="$$TMPDIR" bash $(SCRIPT) list; \
	 PDRX_HOME="$$TMPDIR" bash $(SCRIPT) backup test; \
	 PDRX_HOME="$$TMPDIR" bash $(SCRIPT) generations; \
	 PDRX_HOME="$$TMPDIR" bash $(SCRIPT) -n apply; \
	 PDRX_HOME="$$TMPDIR" bash $(SCRIPT) -y clean all; \
	 echo "All tests passed."

test-full:
	@bash test_suite.sh

test-debian:
	@echo "=== Testing in Debian container ==="
	@docker run --rm -v "$(PWD):/pdrx" -w /pdrx debian:12-slim bash -c \
	 "apt-get update && apt-get install -y shellcheck bash && bash test_suite.sh"

test-fedora:
	@echo "=== Testing in Fedora container ==="
	@docker run --rm -v "$(PWD):/pdrx" -w /pdrx fedora:latest bash -c \
	 "dnf install -y shellcheck bash && bash test_suite.sh"

test-arch:
	@echo "=== Testing in Arch container ==="
	@docker run --rm -v "$(PWD):/pdrx" -w /pdrx archlinux:latest bash -c \
	 "pacman -Sy --noconfirm shellcheck bash && bash test_suite.sh"

test-all: test-debian test-fedora test-arch
	@echo "=== All cross-distro tests completed ==="

# ── Homebrew formula maintenance ──────────────────────────────────────────────

# Print the sha256 you need to paste into Formula/pdrx.rb for a given tag.
# Usage:
#   make formula-sha              (uses the latest git tag)
#   make formula-sha TAG=v1.5.0
formula-sha:
	$(eval TAG ?= $(shell git describe --tags --abbrev=0 2>/dev/null))
	@if [ -z "$(TAG)" ]; then \
	  echo "No git tag found. Run: make formula-sha TAG=v1.5.0"; exit 1; \
	fi
	@URL="https://github.com/stefan-hacks/pdrx/archive/refs/tags/$(TAG).tar.gz"; \
	 echo "Fetching $$URL ..."; \
	 SHA=$$(curl -fsSL "$$URL" | sha256sum | awk '{print $$1}'); \
	 echo ""; \
	 echo "  url \"$$URL\""; \
	 echo "  sha256 \"$$SHA\""; \
	 echo "  version \"$$(echo $(TAG) | sed 's/^v//')\""; \
	 echo ""; \
	 echo "Paste the lines above into $(FORMULA)."

# Tag a release and push — GitHub Actions handles the rest.
# Usage: make release TAG=v1.6.0
release:
	@if [ -z "$(TAG)" ]; then echo "Usage: make release TAG=v1.6.0"; exit 1; fi
	@echo "Tagging $(TAG) ..."
	@VERSION="$$(echo $(TAG) | sed 's/^v//')"; \
	 sed -i "s/^VERSION=.*/VERSION=\"$$VERSION\"/" $(SCRIPT); \
	 git add $(SCRIPT); \
	 git commit -m "chore: bump version to $(TAG)" 2>/dev/null || true
	git tag -a "$(TAG)" -m "Release $(TAG)"
	git push origin main
	git push origin "$(TAG)"
	@echo "Tag $(TAG) pushed. GitHub Actions will create the release and update the formula."

# ── Misc ─────────────────────────────────────────────────────────────────────

clean:
	@rm -f *.tmp
	@echo "Clean."
