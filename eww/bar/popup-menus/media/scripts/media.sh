#!/usr/bin/env bash

CACHE_BASE="/tmp/playerctl_cache_base"
CACHE_LAST="/tmp/playerctl_cache_last"

SKIP_FIRST=1 # Number of initial reads to skip if media is playing and position is weird
has_skipped=0

playerctl metadata \
	--format $'{{title}}\x1F{{artist}}\x1F{{album}}\x1F{{mpris:artUrl}}\x1F{{position}}\x1F{{mpris:length}}\x1F{{status}}' \
	--follow 2>/dev/null | while IFS=$'\x1F' read -r title artist album artUrl position length status; do

	# Blank artist/cover fallback as before
	[[ -z "$artist" ]] && artist="-x-x-x-"
	[[ -z "$artUrl" || "$artUrl" == '""' ]] && artUrl="$HOME/.config/eww/assets/pfp.png"

	# Convert usec (microseconds) to seconds, rounded
	pos_sec=$(((position + 500000) / 1000000))
	len_sec=$(((length + 500000) / 1000000))

	# 1. Smart startup: skip first event if playing and at start/end (prevents glitches)
	if [[ "$has_skipped" -lt $SKIP_FIRST ]]; then
		if [[ "$status" == "Playing" && ($pos_sec -le 2 || $pos_sec -ge $((len_sec - 2))) && $len_sec -gt 10 ]]; then
			((has_skipped++))
			continue
		fi
	fi

	# 2. If stopped: clear cache and output 'No Media'
	if [[ "$status" != "Playing" && "$status" != "Paused" ]]; then
		rm -f "$CACHE_BASE" "$CACHE_LAST"
		jq -n -c '{
        title: "No Media is Currently Playing",
        artist: "-x-x-x-",
        album: "",
        artUrl: "'"$HOME/.config/eww/cover"'",
        position: 0,
        positionStr: "",
        length: 0,
        lengthStr: "",
        status: "Stopped"
    }'
		continue
	fi

	# 3. Paused state: cache logic (unchanged from your script)
	if [[ "$status" == "Paused" ]]; then
		if [[ ! -f "$CACHE_BASE" ]]; then
			echo "$pos_sec" >"$CACHE_BASE"
			use_pos_sec=$pos_sec
		elif [[ ! -f "$CACHE_LAST" ]]; then
			base_pos=$(cat "$CACHE_BASE")
			diff=$((pos_sec - base_pos))
			((diff < 0)) && diff=$((-diff))
			if ((diff <= 3)); then
				echo "$pos_sec" >"$CACHE_LAST"
				use_pos_sec=$base_pos
			else
				echo "$pos_sec" >"$CACHE_BASE"
				use_pos_sec=$pos_sec
			fi
		else
			last_pos=$(cat "$CACHE_LAST")
			diff=$((pos_sec - last_pos))
			((diff < 0)) && diff=$((-diff))
			if ((diff <= 3)); then
				echo "$pos_sec" >"$CACHE_LAST"
				base_pos=$(cat "$CACHE_BASE")
				use_pos_sec=$base_pos
			else
				echo "$pos_sec" >"$CACHE_BASE"
				echo "$pos_sec" >"$CACHE_LAST"
				use_pos_sec=$pos_sec
			fi
		fi
	else
		# Playing: clear caches/use live positions
		rm -f "$CACHE_BASE" "$CACHE_LAST"
		use_pos_sec=$pos_sec
	fi

	# Format time
	pos_mins=$((use_pos_sec / 60))
	pos_secs=$((use_pos_sec % 60))
	positionStr=$(printf "%d:%02d" "$pos_mins" "$pos_secs")
	len_mins=$((len_sec / 60))
	len_secs=$((len_sec % 60))
	lengthStr=$(printf "%d:%02d" "$len_mins" "$len_secs")

	jq -n -c \
		--arg title "$title" \
		--arg artist "$artist" \
		--arg album "$album" \
		--arg artUrl "$artUrl" \
		--arg position "$use_pos_sec" \
		--arg positionStr "$positionStr" \
		--arg length "$len_sec" \
		--arg lengthStr "$lengthStr" \
		--arg status "$status" \
		'{
    title: $title,
    artist: $artist,
    album: $album,
    artUrl: $artUrl,
    position: ($position|tonumber),
    positionStr: $positionStr,
    length: ($length|tonumber),
    lengthStr: $lengthStr,
    status: $status
}'
done
