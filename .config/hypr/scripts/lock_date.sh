#!/bin/bash
# Localized date string for hyprlock with multi-language formatting

lang_code=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/rhythm/language" 2>/dev/null || echo "es")

LOCALE=""
if command -v rhythm-language >/dev/null 2>&1; then
    LOCALE=$(rhythm-language locale "$lang_code" 2>/dev/null || true)
fi

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/10-locale.conf"
if [ -z "$LOCALE" ] && [ -f "$CONFIG_FILE" ]; then
    # Prefer explicit LC_TIME over LANG
    LOCALE=$(grep -E '^LC_TIME=' "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"'"'")
    if [ -z "$LOCALE" ]; then
        LOCALE=$(grep -E '^LANG=' "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"'"'")
    fi
fi
[ -z "$LOCALE" ] && LOCALE="es_ES.UTF-8"

case "$lang_code" in
    ja|ko|zh-CN|zh-TW)
        LC_ALL="" LC_TIME="$LOCALE" date +"%Y年%m月%d日 (%A)" 2>/dev/null || date +"%Y-%m-%d (%A)"
        ;;
    de|da|no|sv|fi|is)
        LC_ALL="" LC_TIME="$LOCALE" date +"%A, %d. %B" 2>/dev/null || date +"%A, %d. %B"
        ;;
    *)
        LC_ALL="" LC_TIME="$LOCALE" date +"%A, %d %B" 2>/dev/null || date +"%A, %d %B"
        ;;
esac
