#!/bin/bash

print_json() {
	# Get brightness percentage as an integer
	bright=$(brightnessctl get)
	max=$(brightnessctl max)
	percent=$((bright * 100 / max))

	# Choose icon based on brightness level
	if [ "$percent" -le 33 ]; then
		icon="󰃞" # Low brightness
	elif [ "$percent" -le 66 ]; then
		icon="󰃟" # Medium brightness
	else
		icon="󰃠" # High brightness
	fi

	# Output JSON
	echo "{\"value\": $percent, \"icon\": \"$icon\"}"
}

# Emit once on start
print_json

# Watch for udev events related to backlight
# NOTE: this might not trigger perfectly on every brightness change, so polling can be a fallback
udevadm monitor --udev --subsystem-match=backlight | while read -r _; do
	print_json
done
