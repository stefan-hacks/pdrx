run_apply() {
  require_initialized
  log_header "Apply: reproduce declared system state"

  local APPLY_PACKAGES=false
  local APPLY_SYSTEMD=false
  local APPLY_DESKTOP=false
  local APPLY_DOTFILES=false
  local APPLY_ALL=true
  local PARALLEL=false

  while [ $# -gt 0 ]; do
    case "$1" in
      --packages) APPLY_PACKAGES=true; APPLY_ALL=false; shift ;;
      --systemd)  APPLY_SYSTEMD=true;  APPLY_ALL=false; shift ;;
      --desktop)  APPLY_DESKTOP=true;  APPLY_ALL=false; shift ;;
      --dotfiles) APPLY_DOTFILES=true; APPLY_ALL=false; shift ;;
      --parallel) PARALLEL=true; shift ;;
      *) shift ;;
    esac
  done

  # If no selective flags were given, apply everything (backward compat)
  if [ "$APPLY_ALL" = "true" ]; then
    APPLY_PACKAGES=true
    APPLY_SYSTEMD=true
    APPLY_DESKTOP=true
    APPLY_DOTFILES=true
  fi

  # ── Packages ──
  if [ "$APPLY_PACKAGES" = "true" ]; then
    # Sources MUST be wired up before package install
    _apply_sources 2>/dev/null || true
    if [ "$PARALLEL" = "true" ]; then
      _run_apply_parallel
    else
      _run_apply_sequential
    fi
  fi

  # ── Dotfiles ──
  # Deploy ALL files under DOTFILES_DIR, not just tracked-dotfiles.
  # This ensures newly-added files in the repo are synced even if they
  # were never individually tracked.
  if [ "$APPLY_DOTFILES" = "true" ]; then
    if [ -d "$DOTFILES_DIR" ]; then
      log_header "Applying dotfiles"
      local count=0
      while IFS= read -r -d '' src; do
        local rel="${src#"$DOTFILES_DIR"/}"
        local dest="$HOME/$rel"
        if [ -f "$src" ]; then
          mkdir -p "$(dirname "$dest")"
          if [ "${DRY_RUN:-false}" = "true" ]; then
            log_info "[dry-run] would deploy dotfile: $rel"
          else
            if [ -L "$dest" ] && [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$src" 2>/dev/null)" ]; then
              log_debug "Dotfile already deployed: $rel"
            else
              rm -f "$dest" 2>/dev/null || true
              ln -sf "$src" "$dest" 2>/dev/null || cp "$src" "$dest"
              log_info "Deployed dotfile: $rel"
              count=$((count + 1))
            fi
          fi
        fi
      done < <(find "$DOTFILES_DIR" -type f -print0 2>/dev/null)
      log_success "Dotfiles applied: $count deployed"
    fi
  fi

  # ── Desktop state ──
  if [ "$APPLY_DESKTOP" = "true" ]; then
    run_restore_desktop 2>/dev/null || true
  fi

  # ── Systemd units ──
  if [ "$APPLY_SYSTEMD" = "true" ]; then
    run_apply_systemd 2>/dev/null || true
  fi

  # ── Hooks ──
  if [ "$APPLY_ALL" = "true" ]; then
    run_apply_hooks
  fi

  log_action "apply" "" "" "ok" "$([ "$PARALLEL" = "true" ] && echo parallel || echo sequential)"
}
