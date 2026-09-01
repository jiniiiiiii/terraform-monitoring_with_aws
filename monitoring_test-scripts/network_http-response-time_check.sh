#!/bin/bash
# 네트워크 상태 + 응답시간 지연 확인

# 종료 시 백그라운드 프로세스 정리
cleanup() {
    echo ""
    echo "=========================================="
    echo "모니터링을 종료하고 프로세스를 정리합니다."
    echo "=========================================="
    kill $PID_SAR $PID_CURL 2>/dev/null
    exit 0
}
trap cleanup SIGINT SIGTERM

echo "=========================================="
echo "모니터링 시작 (종료하려면 Ctrl + C 입력)"
echo " - SAR 로그  : sar_traffic.log"
echo " - CURL 로그 : curl_latency.log"
echo "=========================================="

# 1. sar 백그라운드 실행
sar -n DEV 1 | awk '{ system("printf \"[" strftime("%Y-%m-%d %H:%M:%S") "] \""); print }' >> sar_traffic.log 2>&1 &
PID_SAR=$!

# 2. curl 백그라운드 실행
(
  while true; do
    printf "[$(date '+%Y-%m-%d %H:%M:%S')] "
    curl -s -o /dev/null -w "HTTP %{http_code} | time_total: %{time_total}s\n" http://localhost/
    sleep 0.5
  done
) >> curl_latency.log 2>&1 &
PID_CURL=$!

# 백그라운드 작업 대기
wait