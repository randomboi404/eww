#!/usr/bin/env bash

case "$1" in
a) GOV="reset" ;;
pw) GOV="powersave" ;;
pf) GOV="performance" ;;
*)
	echo "Usage: $0 {a|pw|pf}"
	exit 1
	;;
esac

export DISPLAY=:0
export XAUTHORITY=$HOME/.Xauthority

eww update poprev=false
pkexec auto-cpufreq --force "$GOV"
