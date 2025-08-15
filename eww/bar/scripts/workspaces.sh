#!/bin/bash

# Map numbers 1-10 to Kanji
declare -A kanji_map=(
	[1]="一" [2]="二" [3]="三" [4]="四" [5]="五"
	[6]="六" [7]="七" [8]="八" [9]="九" [10]="十"
)

ws() {
	local persistent=(1 2 3 9 10)
	local output=""

	workspace_data=$(hyprctl workspaces -j)
	current_workspace=$(hyprctl activeworkspace -j | jq -r '.id')

	# Get all workspace IDs from hyprctl (sorted ascending)
	mapfile -t all_ws_ids < <(echo "$workspace_data" | jq -r '.[].id' | sort -n)

	# Collect all workspaces to show:
	#  - Always show persistent
	#  - Include dynamic workspaces only if active or have windows
	declare -A show_ws=()
	for wsid in "${persistent[@]}"; do
		show_ws[$wsid]=1
	done
	for wsid in "${all_ws_ids[@]}"; do
		# If workspace is already persistent, skip (already included)
		if [[ " ${persistent[*]} " == *" $wsid "* ]]; then
			continue
		fi
		# Check windows count
		windows=$(echo "$workspace_data" | jq -r --argjson id "$wsid" '[.[] | select(.id == $id)] | .[0]?.windows // 0')

		# Show dynamic workspace if active or windows > 0
		if [[ "$current_workspace" == "$wsid" || "$windows" -gt 0 ]]; then
			show_ws[$wsid]=1
		fi
	done

	# Extract all keys from show_ws, sort ascending numerically
	mapfile -t ws_to_show < <(printf "%s\n" "${!show_ws[@]}" | sort -n)

	# Function to decide class
	get_class() {
		local wsid=$1
		local windows=$2

		if [[ "$current_workspace" == "$wsid" ]]; then
			echo "workspace-active"
		elif [[ " ${persistent[*]} " == *" $wsid "* ]]; then
			if [[ "$windows" -gt 0 ]]; then
				echo "workspace"
			else
				echo "workspace-empty"
			fi
		elif [[ "$windows" -gt 0 ]]; then
			echo "workspace"
		else
			echo ""
		fi
	}

	# Build output string for all workspaces to show in numeric order
	for wsid in "${ws_to_show[@]}"; do
		# Skip negative workspace IDs (Special Workspaces)
		if ((wsid < 0)); then
			continue
		fi

		windows=$(echo "$workspace_data" | jq -r --argjson id "$wsid" '[.[] | select(.id == $id)] | .[0]?.windows // 0')

		# Use Kanji labels for IDs 1-10
		if [[ "$wsid" -ge 1 && "$wsid" -le 10 ]]; then
			label="${kanji_map[$wsid]}"
		else
			label="$wsid"
		fi

		cls=$(get_class "$wsid" "$windows")

		# Append to output only if class is non-empty
		if [[ -n "$cls" ]]; then
			output+="(eventbox :class \"workspace-e\" :cursor \"pointer\" :onclick \"hyprctl dispatch workspace $wsid\" (label :class \"$cls\" :text \"$label\"))"
		fi
	done

	echo "(box :halign 'start' :orientation 'h' $output)"
}

XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

HYPRLAND_SIGNATURE_ACTUAL=$(ls -td "$XDG_RUNTIME_DIR/hypr/"*/ 2>/dev/null | head -n1 | xargs -r basename)

if [[ -z "$HYPRLAND_SIGNATURE_ACTUAL" ]]; then
	echo "No Hyprland socket found. Exiting."
	exit 1
fi

SOCKET="$XDG_RUNTIME_DIR/hypr/${HYPRLAND_SIGNATURE_ACTUAL}/.socket2.sock"

ws

stdbuf -oL socat -U - UNIX-CONNECT:"$SOCKET" | while read -r line; do
	case $line in
	"workspace>>"* | "createworkspace>>"* | "destroyworkspace>>"*)
		ws
		;;
	esac
done
