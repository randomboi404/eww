#!/usr/bin/env bash

current=$(eww get dockrev)
if [ "$current" = "true" ]; then
	eww update dockrev=false
	sleep 0.3
	eww close dock
else
	eww open dock
	eww update dockrev=true
	sleep 3
	eww update dockrev=false
	sleep 0.3
	eww close dock
fi
