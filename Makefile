# pdrx - Portable Dynamic Reproducible gnu/linuX
# Makefile for installation

PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin

.PHONY: install install-user uninstall check shellcheck

install-user: ## Install to ~/.local/bin (default)
	@mkdir -p $(BINDIR)
	@cp -f pdrx $(BINDIR)/pdrx
	@chmod +x $(BINDIR)/pdrx
	@echo "Installed pdrx to $(BINDIR)/pdrx"
	@echo "Ensure $(BINDIR) is in your PATH. Run: pdrx init"

install: install-user ## Alias for install-user

uninstall: ## Remove pdrx
	@rm -f $(BINDIR)/pdrx
	@echo "Removed $(BINDIR)/pdrx"
	@echo "To remove config: rm -rf ~/.pdrx"

check: ## Basic syntax check
	@bash -n pdrx && echo "Syntax OK"

shellcheck: ## Run shellcheck on all Bash scripts
	@shellcheck pdrx install_manpage.sh 2>/dev/null || (echo "Install shellcheck to run this target"; exit 1)

release-tag: ## Show commands to create and push the version tag (needed for brew install)
	@V=$$(grep '^VERSION=' pdrx | cut -d'"' -f2); \
	echo "To fix 'Failed to download resource' for Homebrew, push the tag for this version:"; \
	echo "  git tag v$$V"; \
	echo "  git push origin v$$V"
