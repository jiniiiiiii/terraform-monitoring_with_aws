#!/bin/bash
# 테스트하고자 하는 서버에서 cpu부하 + network 트래픽 상관관계 동시 확인 목적

LOG_FILE="system_perf.log"

# 화면 및 로그 파일 헤더 출력
HEADER="[Timestamp]         | Load Average (1m, 5m, 15m) | CPU (%us, %sy, %id, %si)     | HTTP Response"
echo "================================================================================================" | tee -a "$LOG_FILE"
echo "$HEADER" | tee -a "$LOG_FILE"
echo "================================================================================================" | tee -a "$LOG_FILE"

while true; do
    # 1. 타임스탬프
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # 2. uptime (로드 애버리지 추출)
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)

    # 3. top (CPU %user, %system, %idle, %softirq 추출)
    # ※ 대용량 네트워크 트래픽 인입 시 패킷 처리를 담당하는 %si(SoftIRQ)가 핵심 지표입니다.
    CPU_STAT=$(top -b -n 1 | grep "%Cpu(s)" | awk '{printf "us:%s sy:%s id:%s si:%s", $2, $4, $8, $12}')

    # 4. curl (HTTP 응답 코드 및 Latency 측정)
    # 대상 서버 localhost 대상 (타임아웃 2초 지정)
    HTTP_RES=$(curl -s -o /dev/null -m 2 -w "HTTP=%{http_code} time=%{time_total}s" http://localhost/ 2>/dev/null)
    if [ -z "$HTTP_RES" ]; then
        HTTP_RES="HTTP=TIMEOUT/FAIL"
    fi

    # 한 줄로 병합하여 화면 출력 및 파일 기록
    printf "[%s] | %-26s | %-28s | %s\n" \
        "$TIMESTAMP" "$LOAD_AVG" "$CPU_STAT" "$HTTP_RES" | tee -a "$LOG_FILE"

    sleep 1
done