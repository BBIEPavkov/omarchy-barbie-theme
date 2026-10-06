#!/bin/bash

# Installs the Barbie theme extras. Asks before each piece; run it again any
# time to add pieces you skipped. Undo with extras/uninstall.sh.

set -euo pipefail

EXTRAS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
HYPR_CONFIG="$HOME/.config/hypr/hyprland.lua"
MENU_CONFIG="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
USER_SHELL_CONFIG="$HOME/.config/omarchy/shell.toml"
CURSOR_THEME="barbie-hotpink-cursors"

ask() {
  gum confirm "$1"
}

install_plugins() {
  local id
  mkdir -p "$PLUGINS_DIR"
  for id in "$@"; do
    if [[ -e $PLUGINS_DIR/$id || -L $PLUGINS_DIR/$id ]]; then
      echo "$id is already installed"
      continue
    fi
    cp -r "$EXTRAS/plugins/$id" "$PLUGINS_DIR/$id"
  done

  omarchy-shell shell rescanPlugins >/dev/null
  for id in "$@"; do
    for _ in {1..40}; do
      omarchy-plugin-list --json | jq -e --arg id "$id" 'any(.[]; .id == $id)' >/dev/null && break
      sleep 0.05
    done
    # Each plugin is a clone of a built-in, so enabling it replaces that built-in.
    omarchy-plugin-enable "$id"
  done
}

install_hypr_module() {
  local name=$1
  cp "$EXTRAS/hypr/$name.lua" "$HOME/.config/hypr/$name.lua"
  grep -qxF "require(\"hypr.$name\")" "$HYPR_CONFIG" || printf '\nrequire("hypr.%s")\n' "$name" >>"$HYPR_CONFIG"
}

if ask "Install the Barbie lock screen? (floating hearts, shimmering logo, unlock confetti)"; then
  install_plugins emilypavkov.lock
fi

if ask "Install the Barbie bar? (script-font clock, heart on the current workspace, slightly taller bar)"; then
  install_plugins emilypavkov.clock emilypavkov.workspaces
  if [[ -f $USER_SHELL_CONFIG ]]; then
    echo "Left $USER_SHELL_CONFIG alone. For the taller bar, set [bar] size-horizontal = 30 and [font] base-size = 13 there."
  else
    printf '# Machine-level overrides on top of the active theme'"'"'s shell.toml.\n\n[bar]\nsize-horizontal = 30\n\n[font]\nbase-size = 13\n' >"$USER_SHELL_CONFIG"
  fi
fi

if ask "Install heart volume/brightness popups and heart notifications?"; then
  install_plugins emilypavkov.osd emilypavkov.notifications
fi

if ask "Install the hot pink cursor?"; then
  mkdir -p "$HOME/.local/share/icons"
  rm -rf "$HOME/.local/share/icons/$CURSOR_THEME"
  cp -r "$EXTRAS/cursors/$CURSOR_THEME" "$HOME/.local/share/icons/"
  install_hypr_module barbie_cursor
  gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
  hyprctl setcursor "$CURSOR_THEME" 24 >/dev/null
fi

if ask "Use rounded corners, a pink glow on the focused window, and bouncy window animations?"; then
  install_hypr_module barbie_windows
fi

if ask "Switch to the next Barbie wallpaper once a day?"; then
  mkdir -p "$HOME/.config/systemd/user"
  cp "$EXTRAS/systemd/barbie-daily-background.service" "$EXTRAS/systemd/barbie-daily-background.timer" "$HOME/.config/systemd/user/"
  systemctl --user daemon-reload
  systemctl --user enable --now barbie-daily-background.timer
fi

if ask "Install the pink heart terminal prompt? (replaces ~/.config/starship.toml; your current one is backed up)"; then
  if [[ -f $HOME/.config/starship.toml ]]; then
    cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak.$(date +%s)"
  fi
  cp "$EXTRAS/starship/starship.toml" "$HOME/.config/starship.toml"
fi

if ask "Change the launcher prompt to \"Where to, Barbie…\"?"; then
  mkdir -p "$(dirname "$MENU_CONFIG")"
  [[ -f $MENU_CONFIG ]] || printf '{\n}\n' >"$MENU_CONFIG"
  if ! grep -q 'barbie-extras begin' "$MENU_CONFIG"; then
    # Insert right after the opening brace; the menu ignores the trailing comma.
    awk -v block="$EXTRAS/menu/barbie-menu.jsonc" '
      { print }
      !done && /^\{/ { while ((getline line < block) > 0) print line; done = 1 }
    ' "$MENU_CONFIG" >"$MENU_CONFIG.tmp" && mv "$MENU_CONFIG.tmp" "$MENU_CONFIG"
  fi
fi

hyprctl reload >/dev/null
hyprctl configerrors

if ask "Set the boot and login screens to the BarbieOS logo? (asks for your password)"; then
  # Black background instead of the theme's, so the logo stands out.
  omarchy-plymouth-set "#000000" "#FF8EC8" "$EXTRAS/../unlock.png"
fi

echo "Done. Lock with 'omarchy system lock' to see the lock screen."
