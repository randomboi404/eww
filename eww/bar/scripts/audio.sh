#!/bin/bash

set -euo pipefail

# Utility: Get default sink name
get_default_sink() {
  pactl info | awk -F': ' '/Default Sink/ {print $2}'
}

# Utility: Get volume (average of channels in %) and mute status of a sink
get_sink_state() {
  local sink="$1"
  # Get volume as % average of channels
  local volume
  volume=$(pactl list sinks | awk -v sink="$sink" '
    $0 ~ "Sink #" {in_sink=0}
    $0 ~ "Name: " sink {in_sink=1}
    in_sink && /Volume:/ {
      # Extract all volume percentages, sum and count channels
      match($0, /([0-9]{1,3})%/, m)
      if (m[1]) {
        print m[1]
        exit
      }
    }
  ')

  # If above extraction fails fallback with more comprehensive logic
  if [[ -z "$volume" ]]; then
    # complex parsing with average of all channels
    volume=$(pactl list sinks | awk -v sink="$sink" '
    $0 ~ "Sink #" {in_sink=0; vol_sum=0; chan_count=0}
    $0 ~ "Name: " sink {in_sink=1}
    in_sink && /Volume:/ {
      for (i=1; i<=NF; i++) {
        if ($i ~ /[0-9]+%/) {
          gsub("%","",$i)
          vol_sum += $i
          chan_count++
        }
      }
    }
    END { if (chan_count>0) print int(vol_sum/chan_count); else print 0 }
    ')
  fi

  # Get mute status: yes/no
  local mute
  mute=$(pactl get-sink-mute "$sink" | awk '{print $2}')

  echo "$volume" "$mute"
}

# Utility: Get an icon based on mute/volume and device description
get_icon() {
  local mute="$1"
  local volume="$2"
  local device_desc="$3"

  if [[ "$mute" == "yes" ]]; then
    echo "󰝟"  # muted icon
    return
  fi

  # Device keywords mapped to emoji icons (partial)
  # Let’s detect some common device types in description (case-insensitive)
  local icon=""
  case "$device_desc" in
    *[Hh]eadphone*) icon="󰋋" ;;
    *[Hh]ands-free*) icon="󰋎" ;;
    *[Hh]eadset*) icon="󰋎" ;;
    *[Pp]hone*) icon="󰏲" ;;
    *[Pp]ortable*) icon="󰄝" ;;
    *[Cc]ar*) icon="󰄋" ;;
    *) 
      # Default icon based on volume level thresholds
      if (( volume == 0 )); then
        icon="󰖀"  # muted volume icon (alternative)
      elif (( volume <= 33 )); then
        icon="󰕾"
      elif (( volume <= 66 )); then
        icon="󰕿"
      else
        icon="󰕿"
      fi
      ;;
  esac

  echo "$icon"
}

# Output json with current icon and value
output_state_json() {
  local icon="$1"
  local volume="$2"

  # Volume with % sign as requested
  local value="${volume}%"

  printf '{"icon":"%s","value":"%s"}\n' "$icon" "$value"
}

# Print current state JSON from sink info
print_state() {
  local sink="$1"

  # Get sink info
  # We want desc for device description for icon choice
  local device_desc
  device_desc=$(pactl list sinks | awk -v sink="$sink" '
    $0 ~ "Sink #" {in_sink=0}
    $0 ~ "Name: " sink {in_sink=1}
    in_sink && /Description:/ {
      sub(/^ +Description: /,"")
      print $0
      exit
    }
  ')

  read -r volume mute < <(get_sink_state "$sink")
  local icon
  icon=$(get_icon "$mute" "$volume" "$device_desc")
  output_state_json "$icon" "$volume"
}

# Main logic

default_sink=$(get_default_sink)
if [[ -z "$default_sink" ]]; then
  echo '{"icon":"󰖁","value":"N/A"}'  # no sink found
  exit 1
fi

# Print initial state immediately
print_state "$default_sink"

# Listen to PulseAudio events and update when sink or sink input changes happen
pactl subscribe | while read -r line; do
  # Example events:
  # Event 'change' on sink #1
  # Event 'change' on sink-input #27
  # We'll refresh state on any Sink or Sink Input change

  if [[ "$line" =~ (sink|sink-input) ]]; then
    default_sink=$(get_default_sink)  # get default again, may have changed
    print_state "$default_sink"
  fi
done
