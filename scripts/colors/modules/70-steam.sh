#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/module-runtime.sh"
COLOR_MODULE_ID="steam"

main() {
  local enable_adwsteam
  enable_adwsteam=$(config_bool '.appearance.wallpaperTheming.enableAdwSteam' false)
  [[ "$enable_adwsteam" == 'true' ]] || exit 0
  "$SCRIPT_DIR/apply-adwsteam-theme.sh"
}

main "$@"
