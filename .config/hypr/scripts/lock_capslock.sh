#!/bin/bash
# Fast Caps Lock status with emoji for hyprlock

if grep -q '^1$' /sys/class/leds/*capslock*/brightness 2>/dev/null; then
    echo "🔒 🔠 Bloq Mayús"
    exit 0
fi

if command -v hyprctl >/dev/null 2>&1; then
    if hyprctl devices -j 2>/dev/null | jq -e '.keyboards[] | select(.capsLock == true)' >/dev/null 2>&1; then
        echo "🔒 🔠 Bloq Mayús"
        exit 0
    fi
fi

echo ""
