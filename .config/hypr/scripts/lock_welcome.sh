#!/bin/bash
# Localized welcome string for hyprlock

lang_code=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/rhythm/language" 2>/dev/null || echo "es")
catalog="${XDG_CONFIG_HOME:-$HOME/.config}/rhythm/i18n/${lang_code}/island.json"

welcome="Welcome back, ${USER:-User}"
if command -v rhythm-i18n >/dev/null 2>&1; then
    str=$(rhythm-i18n "lock_welcome" "Welcome back, \$USER" "$lang_code" 2>/dev/null || echo "")
    if [ -n "$str" ]; then
        welcome="${str//\$USER/${USER:-User}}"
    fi
else
    catalog="${XDG_CONFIG_HOME:-$HOME/.config}/rhythm/i18n/${lang_code}/island.json"
    [ -f "$catalog" ] || catalog="$HOME/hyprland/.config/rhythm/i18n/${lang_code}/island.json"
    if [ -f "$catalog" ]; then
        str=$(jq -r '.lock_welcome // empty' "$catalog" 2>/dev/null)
        if [ -n "$str" ]; then
            welcome="${str//\$USER/${USER:-User}}"
        fi
    fi
fi

echo "$welcome"
