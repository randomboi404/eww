#!/usr/bin/env sh

eww update notifhisrev=$(
	if [ "$(eww get notifhisrev)" = "true" ]; then
		echo false
		eww open history-frame
	else
		echo true
		eww close history-frame
	fi
)
