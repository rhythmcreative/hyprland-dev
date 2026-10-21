#!/bin/bash
# Localized welcome string for hyprlock

lang_code=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/rhythm/language" 2>/dev/null || echo "es")
catalog="${XDG_CONFIG_HOME:-$HOME/.config}/rhythm/i18n/${lang_code}/island.json"

welcome="Welcome back, ${USER:-User}"
if [ -f "$catalog" ]; then
    str=$(jq -r '.lock_welcome // empty' "$catalog" 2>/dev/null)
    if [ -n "$str" ]; then
        welcome="${str//\$USER/${USER:-User}}"
    fi
fi

echo "$welcome"
