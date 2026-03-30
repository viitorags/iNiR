#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/module-runtime.sh"
COLOR_MODULE_ID="steam"

# Resolve the AdwSteamGtk binary: native install preferred, flatpak as fallback.
resolve_adwsteam_cmd() {
  if command -v adwsteamgtk &>/dev/null; then
    printf 'adwsteamgtk'
    return 0
  fi
  if command -v flatpak &>/dev/null && flatpak list --app 2>/dev/null | grep -q 'io.github.Foldex.AdwSteamGtk'; then
    printf 'flatpak run io.github.Foldex.AdwSteamGtk'
    return 0
  fi
  return 1
}

main() {
  local adwsteam_cmd
  if ! adwsteam_cmd="$(resolve_adwsteam_cmd)"; then
    log_module "AdwSteamGtk not found (neither native nor flatpak)"
    exit 0
  fi

  local color_theme
  color_theme=$(config_json '.appearance.wallpaperTheming.adwSteamColorTheme // "adwaita"' "adwaita")

  log_module "applying Adwaita for Steam with color_theme=$color_theme"
  # shellcheck disable=SC2086
  $adwsteam_cmd -i -o "color_theme:${color_theme}"
}

main "$@"
