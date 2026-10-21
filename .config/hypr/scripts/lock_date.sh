#!/bin/bash
# Localized date string for hyprlock

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/10-locale.conf"
LOCALE="es_ES.UTF-8"
if [ -f "$CONFIG_FILE" ]; then
    val=$(grep -E '^(LANG|LC_TIME)=' "$CONFIG_FILE" | head -n1 | cut -d'=' -f2 | tr -d '"'"'")
    [ -n "$val" ] && LOCALE="$val"
fi

lang_code=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/rhythm/language" 2>/dev/null || echo "es")

case "$lang_code" in
    ja|ko|zh-CN|zh-TW)
        LC_TIME="$LOCALE" date +"%Y年%m月%d日 (%A)" 2>/dev/null || date +"%Y-%m-%d (%A)"
        ;;
    de|da|no|sv|fi|is)
        LC_TIME="$LOCALE" date +"%A, %d. %B" 2>/dev/null || date +"%A, %d. %B"
        ;;
    *)
        LC_TIME="$LOCALE" date +"%A, %d %B" 2>/dev/null || date +"%A, %d %B"
        ;;
esac
