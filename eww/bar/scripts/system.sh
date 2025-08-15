#!/bin/bash

while true; do
	# CPU frequency (GHz)
	freq=$(awk '/cpu MHz/ {printf "%.2f", $4 / 1000; exit}' /proc/cpuinfo)

	# CPU usage (% whole number)
	usage=$(top -bn1 | awk '/Cpu\(s\):/ {printf "%d", 100 - $8}')

	# Memory usage in form "used / total GB"
	mem=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {used=(total - $2)/1024/1024; printf "%.2f / %d GB", used, int((total/1024/1024)+0.5)}' /proc/meminfo)

	# Output JSON
	echo "{\"cpufreq\": \"${freq} GHz\", \"cpu_usage\": ${usage}, \"meminfo\": \"${mem}\"}"

	sleep 1
done
