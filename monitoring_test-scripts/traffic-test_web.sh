#!/bin/bash
while true; do
  curl -s -o /dev/null http://localhost/
  curl -s -o /dev/null http://localhost/
  curl -s -o /dev/null http://localhost/not-found
  sleep 0.2
done