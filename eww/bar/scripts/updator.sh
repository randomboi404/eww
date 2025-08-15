#!/usr/bin/env sh

AUR_HELPER="paru"
UPDATES_DIR="/tmp/updates"
ICON="󰮯"
INTERVAL_MINUTES=10

# Exit early on snapshot boots
if grep -q 'subvol=@/.snapshots' /proc/cmdline; then
  exit
fi

mkdir -p "$UPDATES_DIR"

check_and_write_updates() {
  # Official repos
  ofc=$(CHECKUPDATES_DB=$(mktemp -u) checkupdates 2>/dev/null \
        | tee "$UPDATES_DIR/official_list" \
        | wc -l)
  echo "$ofc" > "$UPDATES_DIR/official"

  # AUR
  aur=$($AUR_HELPER -Qua 2>/dev/null \
        | grep -v '\[ignored\]' \
        | tee "$UPDATES_DIR/aur_list" \
        | wc -l)
  echo "$aur" > "$UPDATES_DIR/aur"

  # Flatpak
  if command -v flatpak >/dev/null 2>&1; then
    flatpak remote-ls --updates 2>/dev/null \
      | tee "$UPDATES_DIR/flatpak_list" >/dev/null
    fpk=$(wc -l < "$UPDATES_DIR/flatpak_list")
  else
    fpk=0
    : > "$UPDATES_DIR/flatpak_list"
  fi
  echo "$fpk" > "$UPDATES_DIR/flatpak"
}

boldify_ascii() {
  INPUT="$1"
  echo "$INPUT" | perl -CS -pe '
    s/([A-Z])/chr(ord($1) + 0x1D400 - ord("A"))/ge;
    s/([a-z])/chr(ord($1) + 0x1D41A - ord("a"))/ge;
  '
}

generate_json_output() {
  ofc=$(< "$UPDATES_DIR/official")
  aur=$(< "$UPDATES_DIR/aur")
  fpk=$(< "$UPDATES_DIR/flatpak")
  total=$((ofc + aur + fpk))

  if (( total == 0 )); then
    echo ""
    return
  fi

  tooltip=$(
    cat "$UPDATES_DIR"/{official_list,aur_list,flatpak_list} 2>/dev/null \
    | sed '/^$/d' \
    | while IFS= read -r line; do
        pkg="${line%% *}"
        rest="${line#* }"
        boldpkg=$(boldify_ascii "$pkg")
        printf '%s %s\n' "$boldpkg" "$rest"
      done \
    | sed -z 's/\n/\\n/g' \
    | sed -E 's|</?b>||g' \
    | sed -E 's|<span[^>]*>||g' \
    | sed -E 's|</span>||g'
  )

  # Remove trailing \n at end if any
  tooltip="${tooltip%\\n}"

  echo "{\"icon\": \"${ICON}\", \"count\": \"${total}\", \"tooltip\": \"$tooltip\"}"
}

# --- Main loop ---
while true; do
  check_and_write_updates
  generate_json_output
  sleep $((INTERVAL_MINUTES * 60))
done
