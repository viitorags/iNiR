#!/usr/bin/env python3
"""Sync SilentSDDM theme colors with current Material You palette.

Reads generated colors from matugen's colors.json and updates
the SilentSDDM inir.conf with matching accent/background colors.
Requires sudo to write to /usr/share/sddm/themes/silent/.
"""

import json
import os
import subprocess
import sys

THEME_DIR = "/usr/share/sddm/themes/silent"
CONF_FILE = os.path.join(THEME_DIR, "configs", "inir.conf")
STATE_DIR = os.path.join(
    os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")),
    "quickshell",
)
COLORS_JSON = os.path.join(STATE_DIR, "user", "generated", "colors.json")


def read_colors():
    """Read Material You colors from matugen's colors.json."""
    if not os.path.isfile(COLORS_JSON):
        return None
    with open(COLORS_JSON) as f:
        data = json.load(f)

    # matugen colors.json structure: { "colors": { "dark": { ... }, "light": { ... } } }
    dark = data.get("colors", {}).get("dark", {})
    if not dark:
        return None

    return {
        "accent": dark.get("primary", "#cac4d5"),
        "accent_fg": dark.get("on_primary", "#322e3c"),
        "bg": dark.get("background", "#0f0e0f"),
        "surface": dark.get("surface", "#141316"),
        "surface_container": dark.get("surface_container", "#201e22"),
        "outline": dark.get("outline_variant", "#49454f"),
        "fg": dark.get("on_background", "#e6e1e6"),
        "fg_dim": dark.get("on_surface_variant", "#938f99"),
    }


def update_conf(colors):
    """Update SilentSDDM config with new colors."""
    if not os.path.isfile(CONF_FILE):
        print(f"[sddm-sync] Config not found: {CONF_FILE}")
        return False

    with open(CONF_FILE) as f:
        content = f.read()

    replacements = {
        "AccentColor=": f'AccentColor="{colors["accent"]}"',
        "BackgroundColor=": f'BackgroundColor="{colors["bg"]}"',
        "FormBackgroundColor=": f'FormBackgroundColor="{colors["surface_container"]}"',
        "FormBorderColor=": f'FormBorderColor="{colors["outline"]}"',
        "LoginButtonBackgroundColor=": f'LoginButtonBackgroundColor="{colors["accent"]}"',
        "LoginButtonTextColor=": f'LoginButtonTextColor="{colors["accent_fg"]}"',
        "TextColor=": f'TextColor="{colors["fg"]}"',
        "PlaceholderColor=": f'PlaceholderColor="{colors["fg_dim"]}"',
        "SessionButtonColor=": f'SessionButtonColor="{colors["accent"]}"',
        "SystemButtonColor=": f'SystemButtonColor="{colors["accent"]}"',
        "DateColor=": f'DateColor="{colors["fg"]}"',
        "TimeColor=": f'TimeColor="{colors["fg"]}"',
    }

    lines = content.split("\n")
    new_lines = []
    for line in lines:
        replaced = False
        for prefix, replacement in replacements.items():
            if line.strip().startswith(prefix):
                new_lines.append(replacement)
                replaced = True
                break
        if not replaced:
            new_lines.append(line)

    new_content = "\n".join(new_lines)

    # Write via sudo
    try:
        proc = subprocess.run(
            ["sudo", "tee", CONF_FILE],
            input=new_content.encode(),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            timeout=5,
        )
        if proc.returncode == 0:
            print(f"[sddm-sync] Updated SDDM theme colors (accent: {colors['accent']})")
            return True
        else:
            print(f"[sddm-sync] Failed to write: {proc.stderr.decode().strip()}")
            return False
    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        print(f"[sddm-sync] Error: {e}")
        return False


def main():
    colors = read_colors()
    if colors is None:
        print("[sddm-sync] No colors available yet. Skipping.")
        return

    if not os.path.isdir(THEME_DIR):
        print("[sddm-sync] SilentSDDM not installed. Skipping.")
        return

    update_conf(colors)


if __name__ == "__main__":
    main()
