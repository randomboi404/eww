#!/bin/bash

if [[ -z $(eww active-windows | grep 'toggle-cpu-profile') ]]; then
    eww open toggle-cpu-profile && eww update tgcrev=true
else
    eww update tgcrev=false
    (sleep 0.2 && eww close toggle-cpu-profile) &
fi
