#!/bin/bash
# Fast Caps Lock status with multi-language i18n for hyprlock

lang_code=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/rhythm/language" 2>/dev/null || echo "es")
caps_text="Caps Lock"
if command -v rhythm-i18n >/dev/null 2>&1; then
    caps_text=$(rhythm-i18n "lock_caps_on" "Caps Lock" "$lang_code" 2>/dev/null || echo "Caps Lock")
elif [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/rhythm/i18n/${lang_code}/island.json" ]; then
    caps_text=$(jq -r '.lock_caps_on // "Caps Lock"' "${XDG_CONFIG_HOME:-$HOME/.config}/rhythm/i18n/${lang_code}/island.json" 2>/dev/null || echo "Caps Lock")
fi

is_caps_on=false
if grep -q '^1$' /sys/class/leds/*capslock*/brightness 2>/dev/null; then
    is_caps_on=true
elif command -v hyprctl >/dev/null 2>&1; then
    if hyprctl devices -j 2>/dev/null | jq -e '.keyboards[] | select(.capsLock == true)' >/dev/null 2>&1; then
        is_caps_on=true
    fi
fi

if $is_caps_on; then
    echo "󰘲  $caps_text"
else
    echo ""
fi
