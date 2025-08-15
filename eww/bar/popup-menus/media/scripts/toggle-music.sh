#!/bin/bash

if [[ -z $(eww active-windows | grep 'media') ]]; then
	eww open media && eww update mediarev=true
else
	eww update mediarev=false
	(sleep 0.2 && eww close media) &
fi
