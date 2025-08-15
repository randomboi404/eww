#!/bin/bash

print_bt_json() {
    powered=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')
    connected_any=$(bluetoothctl info 2>/dev/null | grep "Connected: yes")

    if [[ "$powered" != "yes" ]]; then
        icon="󰂲"
        status="off"
        connected=false
    elif [[ -n "$connected_any" ]]; then
        icon="󰂱"
        status="connected"
        connected=true
    else
        icon="󰂯"
        status="on"
        connected=false
    fi

    jq -nc --arg icon "$icon" --arg status "$status" --argjson connected "$connected" \
        '{icon: $icon, status: $status, connected: $connected}'
}

# Output initial state
print_bt_json

# React to events
bluetoothctl --monitor | while read -r _; do
    print_bt_json
done
