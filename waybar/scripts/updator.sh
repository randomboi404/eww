#!/usr/bin/env sh

AUR_HELPER="paru"
UPDATES_DIR="/tmp/updates"

# Exit early on snapshot boots
if grep -q 'subvol=@/.snapshots' /proc/cmdline; then
  exit
fi

mkdir -p "$UPDATES_DIR"

# --- functions to update & cache ---
check_and_write_updates() {
  # Official repos
  ofc=$(CHECKUPDATES_DB=$(mktemp -u) checkupdates \
        | tee "$UPDATES_DIR/official_list" \
        | wc -l)
  echo "$ofc" > "$UPDATES_DIR/official"

  # AUR
  aur=$($AUR_HELPER -Qua \
        | grep -v '\[ignored\]' \
        | tee "$UPDATES_DIR/aur_list" \
        | wc -l)
  echo "$aur" > "$UPDATES_DIR/aur"

  # Flatpak
  if command -v flatpak >/dev/null 2>&1; then
    flatpak remote-ls --updates \
      | tee "$UPDATES_DIR/flatpak_list" >/dev/null
    fpk=$(wc -l < "$UPDATES_DIR/flatpak_list")
  else
    fpk=0
    : > "$UPDATES_DIR/flatpak_list"
  fi
  echo "$fpk" > "$UPDATES_DIR/flatpak"

  total=$((ofc + aur + fpk))
}

read_updates_from_files() {
  if [[ -f "$UPDATES_DIR/official" && -f "$UPDATES_DIR/aur" && -f "$UPDATES_DIR/flatpak" ]]; then
    ofc=$(< "$UPDATES_DIR/official")
    aur=$(< "$UPDATES_DIR/aur")
    fpk=$(< "$UPDATES_DIR/flatpak")
    total=$((ofc + aur + fpk))
    return 0
  else
    check_and_write_updates
    return 1
  fi
}

# On 'up', try to reuse cache; otherwise always refresh
if [[ "$1" == "up" ]]; then
  read_updates_from_files
else
  check_and_write_updates
fi

(( total == 0 )) && exit

case "$1" in
  text)
    tooltip=$(
      cat "$UPDATES_DIR"/{official_list,aur_list,flatpak_list} 2>/dev/null \
        | sed '/^$/d' \
        | sed -z 's/\n/\\n/g' \
        | sed -E "s/(^|\\\\n)([^ ]+)([^\\\\n]*)/\1\2<span color='#ff6699'>\3<\/span>/g" \
        | sed -E 's/^(.*)\\n(.*)$/\1\2/'
    )
    echo "{\"text\": \"${total}\", \"tooltip\": \"<b>${tooltip}</b>\"}"
    exit
    ;;
  img)
    echo "󰮯"
    exit
    ;;
esac

# Interactive upgrade popup
if [[ "$1" != "up" ]] || (( total == 0 )); then
  exit
fi

trap 'pkill waybar && hyprctl dispatch exec waybar' EXIT

kitty --title "System Update" bash -lc "
fastfetch

printf '[Official]  %d \n' $ofc
printf '[AUR]       %d \n' $aur
printf '[Flatpak]   %d \n' $fpk

(( $ofc > 0 )) && sudo pacman -Syu
(( $aur > 0 )) && $AUR_HELPER -Sua
(( $fpk > 0 )) && flatpak update --noninteractive

read -n 1 -p 'Press any key to continue...'
"
