#!/bin/sh
# Вывод: name,util%,temp°C,vram_used_MiB,vram_total_MiB  (одна строка, или пусто)

if command -v nvidia-smi >/dev/null 2>&1; then
    out=$(nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total \
        --format=csv,noheader,nounits 2>/dev/null | head -n1)
    if [ -n "$out" ]; then
        echo "$out"
        exit 0
    fi
fi

# AMD (amdgpu)
for d in /sys/class/drm/card[0-9]*/device; do
    [ -r "$d/gpu_busy_percent" ] || continue
    util=$(cat "$d/gpu_busy_percent")
    t=$(cat "$d"/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1)
    mu=$(cat "$d/mem_info_vram_used" 2>/dev/null)
    mt=$(cat "$d/mem_info_vram_total" 2>/dev/null)
    echo "AMD GPU,$util,$(( ${t:-0} / 1000 )),$(( ${mu:-0} / 1048576 )),$(( ${mt:-0} / 1048576 ))"
    exit 0
done
