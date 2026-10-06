#!/bin/bash

# Removes everything extras/install.sh added and brings back Omarchy's
# built-ins. Your starship.toml backup is left in place to restore by hand.

set -euo pipefail

HYPR_CONFIG="$HOME/.config/hypr/hyprland.lua"
MENU_CONFIG="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
CURSOR_THEME="barbie-hotpink-cursors"

for id in emilypavkov.lock emilypavkov.clock emilypavkov.workspaces emilypavkov.osd emilypavkov.notifications; do
  # Removing a clone switches back to the built-in it replaced.
  if [[ -e $HOME/.config/omarchy/plugins/$id ]]; then
    omarchy-plugin-remove "$id" --yes
  fi
done

if [[ -f $HOME/.config/systemd/user/barbie-daily-background.timer ]]; then
  systemctl --user disable --now barbie-daily-background.timer
  rm -f "$HOME/.config/systemd/user/barbie-daily-background."{service,timer}
  systemctl --user daemon-reload
fi

for name in barbie_cursor barbie_windows; do
  sed -i "/^require(\"hypr\.$name\")$/d" "$HYPR_CONFIG"
  rm -f "$HOME/.config/hypr/$name.lua"
done

if [[ -f $MENU_CONFIG ]]; then
  sed -i '/barbie-extras begin/,/barbie-extras end/d' "$MENU_CONFIG"
fi

if [[ $(gsettings get org.gnome.desktop.interface cursor-theme) == "'$CURSOR_THEME'" ]]; then
  gsettings reset org.gnome.desktop.interface cursor-theme
fi
rm -rf "$HOME/.local/share/icons/$CURSOR_THEME"

hyprctl reload >/dev/null
hyprctl configerrors

if gum confirm "Restore Omarchy's default boot and login screens? (asks for your password)"; then
  omarchy-plymouth-reset
fi

echo "Done. The taller-bar settings in ~/.config/omarchy/shell.toml and your starship.toml backups were left as-is."
