# pdrx - Portable Dynamic Reproducible X
# Makefile for installation

PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin

.PHONY: install install-user uninstall check

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
