#!/bin/bash
# Менеджер буфера обмена через cliphist + wofi

cliphist list | wofi --dmenu --prompt "Буфер:" | cliphist decode | wl-copy
