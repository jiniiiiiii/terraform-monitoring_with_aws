#!/bin/bash
# 단계적으로 부하주는 트래픽
echo "시작 시각: $(date)"
echo "=================================================="
echo "1단계 - 단일 연결 (30초)"
iperf3 -c web01.dev.internal -t 30

echo "2단계 - 병렬 연결 2 (30초)"
iperf3 -c web01.dev.internal -t 30 -P 2

echo "3단계 - 병렬 연결 4 (30초)"
iperf3 -c web01.dev.internal -t 30 -P 4

echo "종료 시각: $(date)"
