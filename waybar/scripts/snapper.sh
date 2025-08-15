#!/usr/bin/env sh

# Only proceed if booted into a Btrfs snapshot
if grep -q 'subvol=@/.snapshots' /proc/cmdline; then
  # Extract "subvol=@/.snapshots/<number>/snapshot"
  raw=$(grep -o 'subvol=@/.snapshots/[0-9]\+/snapshot' /proc/cmdline)
  # Pull just the number
  SNAP_NUM=$(echo "$raw" | grep -o '[0-9]\+')
  notify-send "BTRFS Snapshot" "Booted into snapshot #$SNAP_NUM"
  echo "{\"text\": \" 󰰣 \", \"tooltip\": \"Booted into snapshot #$SNAP_NUM\"}"
fi
