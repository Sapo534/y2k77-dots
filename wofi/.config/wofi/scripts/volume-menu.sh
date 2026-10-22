#!/bin/bash
# Меню громкости через pamixer
current=$(pamixer --get-volume)

chosen=$(printf "🔊 Громкость: %s%%\n🔇 Mute toggle\n➕ +5%%\n➖ -5%%" "$current" | wofi --dmenu --prompt "Звук:")

case "$chosen" in
"🔇 Mute toggle") pamixer -t ;;
"➕ +5%") pamixer -i 5 ;;
"➖ -5%") pamixer -d 5 ;;
*) exit 0 ;;
esac
