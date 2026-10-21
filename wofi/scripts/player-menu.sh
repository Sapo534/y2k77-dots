#!/bin/bash
# Меню управления плеером через playerctl

player_status=$(playerctl status 2>/dev/null)
# Если плеер не запущен, можно ничего не делать или показать уведомление
if [[ -z "$player_status" ]]; then
  notify-send "Player" "Нет активного плеера"
  exit 1
fi

# Формируем пункты меню в зависимости от статуса
if [[ "$player_status" == "Playing" ]]; then
  toggle_item="⏸  Пауза"
else
  toggle_item="▶  Воспроизвести"
fi

chosen=$(printf "%s\n⏭  Следующий\n⏮  Предыдущий\n🔀  Перемешать\n🔁  Цикл\n⏹  Стоп" "$toggle_item" | wofi --dmenu --prompt "Плеер:" --width 250 --height 200)

case "$chosen" in
"⏸  Пауза" | "▶  Воспроизвести") playerctl play-pause ;;
"⏭  Следующий") playerctl next ;;
"⏮  Предыдущий") playerctl previous ;;
"🔀  Перемешать") playerctl shuffle toggle ;;
"🔁  Цикл")
  # Циклическое переключение режимов
  current_loop=$(playerctl loop)
  case "$current_loop" in
  "None") playerctl loop Track ;;
  "Track") playerctl loop Playlist ;;
  "Playlist") playerctl loop None ;;
  esac
  ;;
"⏹  Стоп") playerctl stop ;;
esac
