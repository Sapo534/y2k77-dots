#!/bin/bash
# Меню питания через wofi

chosen=$(printf "  Выключить\n  Перезагрузить\n  Выйти\n  Заблокировать\n  Отмена" |
  wofi --dmenu --prompt "Питание:" --width 300 --height 250)

case "$chosen" in
"  Выключить") systemctl poweroff ;;
"  Перезагрузить") systemctl reboot ;;
"  Выйти") hyprctl dispatch exit ;;
"  Заблокировать") hyprlock ;; # или swaylock / gtklock
*) exit 0 ;;                   # Отмена или закрытие — ничего не делаем
esac
