#!/usr/bin/env bash

MIGRATION_ID="022-service-compositor-wants"
MIGRATION_TITLE="Wire inir.service to compositor instead of graphical-session.target"
MIGRATION_DESCRIPTION="Moves the inir.service wants link from graphical-session.target.wants/ to the detected compositor service (e.g. niri.service.wants/). Prevents inir from starting under KDE, GNOME, or other DEs."
MIGRATION_TARGET_FILE="~/.config/systemd/user/*.wants/inir.service"
MIGRATION_REQUIRED=true

_systemd_user_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

_detect_compositor_for_migration() {
  # Same logic as detect_compositor_service in scripts/inir.
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl --user cat niri.service &>/dev/null; then
      printf 'niri.service\n'
      return
    fi
    if systemctl --user cat 'wayland-wm@Hyprland.service' &>/dev/null; then
      printf 'wayland-wm@Hyprland.service\n'
      return
    fi
  fi
  printf 'graphical-session.target\n'
}

migration_check() {
  # Needs migration if a graphical-session.target.wants link exists
  # AND the correct compositor-specific link does NOT exist.
  local old_link="${_systemd_user_dir}/graphical-session.target.wants/inir.service"
  local target
  target="$(_detect_compositor_for_migration)"

  # No old link — nothing to migrate
  [[ -e "$old_link" || -L "$old_link" ]] || return 1

  # Old link exists and target is not graphical-session.target — needs migration
  if [[ "$target" != "graphical-session.target" ]]; then
    return 0
  fi

  # Target IS graphical-session.target (no compositor detected) — already correct
  return 1
}

migration_preview() {
  local target
  target="$(_detect_compositor_for_migration)"
  echo -e "${STY_RED}- graphical-session.target.wants/inir.service${STY_RST}"
  echo -e "${STY_GREEN}+ ${target}.wants/inir.service${STY_RST}"
  echo ""
  echo "This prevents iNiR from starting under KDE, GNOME, or other desktop environments."
}

migration_apply() {
  local target
  target="$(_detect_compositor_for_migration)"

  if [[ "$target" == "graphical-session.target" ]]; then
    # Can't improve — no compositor service found, keep existing link
    return 0
  fi

  local old_link="${_systemd_user_dir}/graphical-session.target.wants/inir.service"
  local new_wants_dir="${_systemd_user_dir}/${target}.wants"
  local service_file="${_systemd_user_dir}/inir.service"

  # Remove the old generic link first
  rm -f "$old_link"

  # Create the new compositor-specific wants link
  if [[ -f "$service_file" ]]; then
    mkdir -p "$new_wants_dir"
    ln -sf "$service_file" "$new_wants_dir/inir.service"
  fi

  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload >/dev/null 2>&1 || true
  fi
}
