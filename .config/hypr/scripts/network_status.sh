#!/bin/bash
# Ultra-fast network status for hyprlock (<20ms, zero network latency)

lang_code=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/rhythm/language" 2>/dev/null || echo "es")
CONN_STR="Connected"
DISCONN_STR="Disconnected"
if command -v rhythm-i18n >/dev/null 2>&1; then
    CONN_STR=$(rhythm-i18n "lock_connected" "Connected" "$lang_code")
    DISCONN_STR=$(rhythm-i18n "lock_disconnected" "Disconnected" "$lang_code")
fi

wifi_ssid=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep ':802-11-wireless' | cut -d: -f1 | head -n1)

if [ -n "$wifi_ssid" ]; then
    echo "WiFi: $wifi_ssid"
    exit 0
fi

eth_conn=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep ':802-3-ethernet' | cut -d: -f1 | head -n1)
if [ -n "$eth_conn" ]; then
    echo "Ethernet"
    exit 0
fi

for iface in /sys/class/net/*; do
    name=$(basename "$iface")
    [ "$name" = "lo" ] && continue
    if [ "$(cat "$iface/operstate" 2>/dev/null)" = "up" ]; then
        if [[ "$name" =~ ^wl ]]; then
            echo "WiFi"
        else
            echo "$CONN_STR"
        fi
        exit 0
    fi
done

echo "$DISCONN_STR"
