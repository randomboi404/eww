#!/bin/bash

if [[ -z $(eww active-windows | grep 'toggle-menu-bt') ]]; then
    /usr/bin/eww open toggle-menu-bt && /usr/bin/eww update tgbrev=true
else
    /usr/bin/eww update tgbrev=false
    (sleep 0.2 && /usr/bin/eww close toggle-menu-bt) &
fi
