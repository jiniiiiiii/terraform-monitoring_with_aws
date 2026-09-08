#!/bin/bash
while true; do
    echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="

    ss -s

    echo "[Nginx connection state]"
    ss -ant '( sport = :80 )' \
      | awk 'NR>1 {print $1}' \
      | sort | uniq -c

    sleep 1
done | tee connection-monitor.log