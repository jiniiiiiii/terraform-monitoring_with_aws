#!/bin/bash
for i in {1..100}; do
    curl --no-keepalive -s -o /dev/null http://127.0.0.1/ &
done
wait