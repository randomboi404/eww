#!/usr/bin/bash

pkill -9 -f "$HOME/.config/eww/dock/scripts/toggle-dock.sh" || true
"$HOME/.config/eww/dock/scripts/toggle-dock.sh"
