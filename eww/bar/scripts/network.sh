#!/bin/bash

output_status_json() {
    # Get device list and statuses
    wifi_info=$(nmcli -t -f TYPE,STATE,DEVICE device)
    # Check if any device is disabled (nmcli device status: STATE=unavailable means disabled)
    disabled_count=$(nmcli -t -f STATE device | grep -c '^unavailable$')
    total_count=$(nmcli -t -f STATE device | wc -l)

    # Check if all devices are disabled
    if [[ "$disabled_count" -eq "$total_count" ]]; then
        icon="󰖪"
        status="disabled"
        name="Disabled"
        jq -nc --arg icon "$icon" --arg status "$status" --arg name "$name" \
            '{icon: $icon, status: $status, name: $name}'
        return
    fi

    icon="󰖪"
    status="disconnected"
    name="Disconnected"

    # Check for Wi-Fi connected
    while IFS=: read -r dev_type dev_state dev_name; do
        if [[ "$dev_type" == "wifi" && "$dev_state" == "connected" ]]; then
            icon=""
            status="wifi"
            ssid=$(nmcli -t -f ACTIVE,SSID dev wifi | awk -F: '$1 == "yes" {print $2; exit}')
            name="$ssid"
            jq -nc --arg icon "$icon" --arg status "$status" --arg name "$name" \
                '{icon: $icon, status: $status, name: $name}'
            return
        fi
    done <<< "$wifi_info"

    # Check for Ethernet connected
    while IFS=: read -r dev_type dev_state dev_name; do
        if [[ "$dev_type" == "ethernet" && "$dev_state" == "connected" ]]; then
            icon="󰈀"
            status="ethernet"
            name="Ethernet"
            jq -nc --arg icon "$icon" --arg status "$status" --arg name "$name" \
                '{icon: $icon, status: $status, name: $name}'
            return
        fi
    done <<< "$wifi_info"

    # Check for linked but not connected interfaces
    while IFS=: read -r dev_type dev_state dev_name; do
        if [[ "$dev_state" == "connected" ]]; then
            icon=""
            status="linked"
            name="Linked"
            jq -nc --arg icon "$icon" --arg status "$status" --arg name "$name" \
                '{icon: $icon, status: $status, name: $name}'
            return
        fi
    done <<< "$wifi_info"

    # If nothing above matched, return disconnected
    jq -nc --arg icon "$icon" --arg status "$status" --arg name "$name" \
        '{icon: $icon, status: $status, name: $name}'
}

# Initial output
output_status_json

# Listen for network changes and update
nmcli monitor | while read -r _; do
    output_status_json
done
