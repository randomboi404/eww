#!/usr/bin/env sh
radeontop -d - -l 1 | grep -o 'gpu [0-9.]*%' | awk '{print int($2)}'
