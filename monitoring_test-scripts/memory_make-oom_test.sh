#!/bin/bash
sudo systemd-run --scope \
  -p MemoryMax=600M \
  -p MemorySwapMax=0 \
  python3 -c '
import time
x = bytearray(600 * 1024 * 1024)
for i in range(0, len(x), 4096):
    x[i] = 1
print("allocated")
while True:
    time.sleep(10)
'