#!/bin/bash

# 기록 파일 이름 지정
OUTPUT_FILE="기록.txt"

# 1. 기존 파일이 있다면 비우고 새로 작성 (누적하려면 >> 사용)
echo "=== uptime ===" > "$OUTPUT_FILE"
uptime >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE" # 빈 줄 추가

# 2. nproc 기록
echo "=== nproc ===" >> "$OUTPUT_FILE"
nproc >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 3. top 기록
echo "=== top -b -n 1 | head -20 ===" >> "$OUTPUT_FILE"
top -b -n 1 | head -20 >> "$OUTPUT_FILE"
