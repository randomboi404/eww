#!/bin/bash

get_icon() {
	upower_output=$(upower -i $(upower -e | grep 'BAT'))
	state=$(echo "$upower_output" | grep "state" | awk '{print $2}')
	percent=$(echo "$upower_output" | grep "percentage" | awk '{print $2}' | sed 's/%//')

	if [[ "$state" == "charging" || "$state" == "fully-charged" ]]; then
		if ((percent > 80)); then
			echo ""
		else
			echo ""
		fi
	else
		if ((percent > 80)); then
			echo ""
		elif ((percent > 60)); then
			echo ""
		elif ((percent > 40)); then
			echo ""
		elif ((percent > 20)); then
			echo ""
		else
			echo ""
		fi
	fi
}

get_icon # Output current state immediately

upower --monitor | while read -r line; do
	get_icon # Output on every change event
done
