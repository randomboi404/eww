#!/bin/bash

if [[ -z $(eww active-windows | grep 'dash') ]]; then
	eww open dash && eww update dashrev=true
else
	eww update dashrev=false
	(sleep 0.5 && eww close dash) &
fi
