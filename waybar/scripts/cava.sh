#!/usr/bin/env bash

# Configuration
CPU_LIMIT=50
SCRIPT_PID=$$
TMP_DIR="/tmp"
TOOLTIP_CACHE_FILE="${TMP_DIR}/cava_tooltip_cache"
TOOLTIP_CACHE_TIMEOUT=3  # Update tooltip every N seconds

help_msg() {
  cat <<EOF
Usage: $(basename "$0") [stdout|waybar|hyprlock|tooltip]
  stdout   — plain-span output (for terminal)
  waybar   — outputs {"text":…,"tooltip":…} JSON endlessly (for Waybar)
  hyprlock — same as stdout, but with hyprlock vars
  tooltip  — prints only the tooltip text once then exits
EOF
  exit 1
}

declare -a COLORS IDLE_IDX

init_common() {
  local name="${cava_cmd:-stdout}"
  CFG="${TMP_DIR}/cava.${name}"

  # Kill old cava instances
  pkill -x cava >/dev/null 2>&1

  # Bar parameters
  BAR="${cava_bar:-▁▂▃▄▅▆▇█}"
  BAR_LEN=${#BAR}
  WIDTH=${cava_width:-$BAR_LEN}
  RANGE=${cava_range:-$((BAR_LEN - 1))}

  # Write a minimal Cava config:
  cat >"$CFG" <<EOF
    [general]
    bars = ${WIDTH}
    sleep_timer = 0.05
    framerate = 60

    [smoothing]
    integral = 85

    [input]
    method = pulse
    source = auto

    [output]
    method = raw
    raw_target = /dev/stdout
    data_format = ascii
    ascii_max_range = ${RANGE}
EOF

  # Load last N pywal colors
  local N=8
  mapfile -t ALLCOL < <(grep -E '^#([0-9a-fA-F]{6})$' ~/.cache/wal/colors)
  (( ${#ALLCOL[@]} )) || { echo "No wal colors"; exit 1; }
  local start=$(( ${#ALLCOL[@]} > N ? ${#ALLCOL[@]} - N : 0 ))
  WC=("${ALLCOL[@]:start}")

  # Build gradient & idle indices
  MID=$(( WIDTH / 2 ))
  for (( j=0; j<WIDTH; j++ )); do
    dist=$(( j < MID ? j : WIDTH - j - 1 ))
    idx=$(( dist * ${#WC[@]} / MID ))
    (( idx >= ${#WC[@]} )) && idx=$(( ${#WC[@]} - 1 ))
    COLORS[j]=${WC[$idx]}
    idle_idx=$(( RANGE - dist * RANGE / MID ))
    (( idle_idx<0 )) && idle_idx=0
    IDLE_IDX[j]=$idle_idx
  done

  # Prebuild a symmetric idle bar
  idle_str=""
  for (( j=0; j<WIDTH; j++ )); do
    ch="${BAR:${IDLE_IDX[j]}:1}"
    idle_str+="<span color=\"${COLORS[j]}\">$ch</span>"
  done
}

stdout() {
  init_common

  # Immediate idle frame
  printf '%s\n' "$idle_str"

  # Launch cava
  coproc CAVAPROC { stdbuf -oL cava -p "$CFG"; }
  cpulimit -p "$CAVAPROC_PID" -l $CPU_LIMIT &
  cpulimit -p "$SCRIPT_PID"   -l $CPU_LIMIT &

  while IFS=';' read -r -a levels <&"${CAVAPROC[0]}"; do
    # Silence?
    allzero=1
    for lv in "${levels[@]}"; do [[ $lv -ne 0 ]] && { allzero=0; break; }; done

    if (( allzero )); then
      printf '%s\n' "$idle_str"
    else
      out=""
      left=""
      right=""
      for (( j=0; j<WIDTH/2; j++ )); do
        lvl=${levels[j]:-0}
        (( lvl<0 )) && lvl=0
        (( lvl>RANGE )) && lvl=RANGE
        ch="${BAR:$lvl:1}"
      left+="<span color=\"${COLORS[j]}\">$ch</span>"
done

for (( j=WIDTH/2-1; j>=0; j-- )); do
  lvl=${levels[j]:-0}
  (( lvl<0 )) && lvl=0
  (( lvl>RANGE )) && lvl=RANGE
  ch="${BAR:$lvl:1}"
  right+="<span color=\"${COLORS[j]}\">$ch</span>"
done

bars="${left}${right}"
      printf '%s\n' "$out"
    fi
  done
}

# More efficient tooltip function that caches results
get_tooltip() {
  # Check if cached tooltip exists and is recent
  if [[ -f "$TOOLTIP_CACHE_FILE" ]]; then
    now=$(date +%s)
    file_time=$(stat -c %Y "$TOOLTIP_CACHE_FILE" 2>/dev/null || echo 0)

    if (( now - file_time < TOOLTIP_CACHE_TIMEOUT )); then
      # Use cached tooltip if recent
      cat "$TOOLTIP_CACHE_FILE"
      return
    fi
  fi

  # Get new tooltip and cache it
output=$(playerctl metadata --format '{{ title }} - {{ artist }}' 2>/dev/null)
if [ -n "$output" ]; then
  echo "$output" > "$TOOLTIP_CACHE_FILE"
else
  echo 'No media is currently playing' > "$TOOLTIP_CACHE_FILE"
fi
  cat "$TOOLTIP_CACHE_FILE"
}

waybar() {
  init_common

  # Launch cava
  coproc CAVAPROC { stdbuf -oL cava -p "$CFG"; }
  cpulimit -p "$CAVAPROC_PID" -l $CPU_LIMIT &
  cpulimit -p "$SCRIPT_PID"   -l $CPU_LIMIT &

  # Pre-format JSON template parts
  JSON_PREFIX='{"text":"'
  JSON_MIDDLE='","tooltip":"'
  JSON_SUFFIX='"}'

  # Get initial tooltip
  tooltip="$(get_tooltip)"
  last_tooltip_time=$(date +%s)

  while IFS=';' read -r -a levels <&"${CAVAPROC[0]}"; do
    # Check if we need to update tooltip
    now=$(date +%s)
    if (( now - last_tooltip_time >= TOOLTIP_CACHE_TIMEOUT )); then
      tooltip="$(get_tooltip)"
      last_tooltip_time=$now
    fi

    # Check for silence
    allzero=1
    for lv in "${levels[@]}"; do [[ $lv -ne 0 ]] && { allzero=0; break; }; done

    if (( allzero )); then
      bars="$idle_str"
    else
      out=""
      for (( j=0; j<WIDTH; j++ )); do
        if (( j <= MID )); then lvl=${levels[j]:-0}; else lvl=${levels[WIDTH-1-j]:-0}; fi
        (( lvl<0 ))   && lvl=0
        (( lvl>RANGE )) && lvl=RANGE
        ch="${BAR:$lvl:1}"
        out+="<span color=\"${COLORS[j]}\">$ch</span>"
      done
      bars="$out"
    fi

    # Escape quotes in tooltip and bars to ensure valid JSON
    safe_tooltip="${tooltip//\"/\\\"}"
    safe_bars="${bars//\"/\\\"}"
    printf "%s%s%s%s%s\n" "$JSON_PREFIX" "$safe_bars" "$JSON_MIDDLE" "$safe_tooltip" "$JSON_SUFFIX"
  done
}

tooltip() {
  output=$(playerctl metadata --format '{{ title }} - {{ artist }}' 2>/dev/null)
  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    printf 'No media is currently playing\n'
  fi
}

case "$1" in
  stdout)  stdout    ;;
  waybar)  cava_cmd=waybar && waybar ;;
  hyprlock)
    cava_cmd=hyprlock
    cava_bar="$CAVA_HYPRLOCK_BAR" \
    cava_width="$CAVA_HYPRLOCK_WIDTH" \
    cava_range="$CAVA_HYPRLOCK_RANGE"
    stdout    ;;
  *)       help_msg  ;;
esac

# Clean up on exit
trap 'rm -f "$TOOLTIP_CACHE_FILE"' EXIT

exit 0

