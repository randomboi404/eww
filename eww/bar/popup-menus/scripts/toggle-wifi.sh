#!/bin/bash

if [[ -z $(eww active-windows | grep 'toggle-menu-wifi') ]]; then
    eww open toggle-menu-wifi && eww update tgwrev=true
else
    eww update tgwrev=false
    (sleep 0.2 && eww close toggle-menu-wifi) &
fi
