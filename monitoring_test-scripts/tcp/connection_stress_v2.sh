#!/bin/bash
# ==============================================================================
# 연결 부하 단계별 테스트 및 지표 동시 수집 스크립트 (v2 - 3Point Monitoring)
# 부하 시점별 측정: Initial(시작) -> Middle(중간) -> Final(종료) 3단계 스냅샷
# ==============================================================================

LOG_FILE="connection_stress_v2_result.log"
TMP_RESULT="/tmp/curl_stress_tmp.log"

# 스크립트 시작 알림
echo "=====================================================================" | tee -a "$LOG_FILE"
echo " [단계별 부하 테스트 및 3점(시작/중간/종료) 지표 기록 시작] $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "=====================================================================" | tee -a "$LOG_FILE"

# 부하 단계 설정 (100 -> 500 -> 1000 -> 1500 -> 2000 -> 3000 -> 5000 -> 7000)
LOAD_STEPS=(100 500 1000 1500 2000 3000 5000 7000)

for count in "${LOAD_STEPS[@]}"; do
    echo "" | tee -a "$LOG_FILE"
    echo "=====================================================================" | tee -a "$LOG_FILE"
    echo ">>> [부하 단계 시작] 동시 요청 수: $count 개 [$(date '+%Y-%m-%d %H:%M:%S')]" | tee -a "$LOG_FILE"
    echo "=====================================================================" | tee -a "$LOG_FILE"

    # 임시 결과 파일 초기화
    > "$TMP_RESULT"

    # [New Conn/s 측정을 위한 사전 스냅샷]
    START_TIME=$(date +%s.%N 2>/dev/null || date +%s)
    OPENS_BEFORE=$(nstat -az 2>/dev/null | awk '/TcpActiveOpens/{a=$2} /TcpPassiveOpens/{p=$2} END{print a+p}')

    # 1. 병렬 부하 발생 시작 (xargs -P 200)
    seq 1 "$count" | xargs -I{} -P 200 curl --no-keepalive -s -w "%{http_code} %{time_total}\n" -o /dev/null "http://127.0.0.1/" >> "$TMP_RESULT" 2>&1 &
    CURL_PID=$!

    # -------------------------------------------------------------------------
    # [스냅샷 1/3] 부하 시작 직후 (Initial Point)
    # -------------------------------------------------------------------------
    echo "--- [1. 시작 직후 스냅샷 (Initial)] ---" | tee -a "$LOG_FILE"
    ss -ant '( sport = :80 )' | awk 'NR>1 {print $1}' | sort | uniq -c | tee -a "$LOG_FILE"
    nstat -az | grep -E 'Tcp(InSegs|OutSegs|ActiveOpens|PassiveOpens|CurrEstab)' | tee -a "$LOG_FILE"

    # -------------------------------------------------------------------------
    # [스냅샷 2/3] 부하 중간 진행 중 (Middle Point)
    # -------------------------------------------------------------------------
    sleep 0.3
    echo "--- [2. 중간 진행 중 스냅샷 (Middle)] ---" | tee -a "$LOG_FILE"
    ss -ant '( sport = :80 )' | awk 'NR>1 {print $1}' | sort | uniq -c | tee -a "$LOG_FILE"
    nstat -az | grep -E 'Tcp(InSegs|OutSegs|ActiveOpens|PassiveOpens|CurrEstab)' | tee -a "$LOG_FILE"
    mpstat -P ALL 1 2 | tee -a "$LOG_FILE"

    # -------------------------------------------------------------------------
    # 모든 부하 요청 완료 대기
    # -------------------------------------------------------------------------
    wait $CURL_PID

    # -------------------------------------------------------------------------
    # [스냅샷 3/3] 부하 완료 직후 (Final / Post-load Point)
    # -------------------------------------------------------------------------
    echo "--- [3. 부하 완료 직후 스냅샷 (Final)] ---" | tee -a "$LOG_FILE"
    ss -ant '( sport = :80 )' | awk 'NR>1 {print $1}' | sort | uniq -c | tee -a "$LOG_FILE"
    nstat -az | grep -E 'Tcp(InSegs|OutSegs|ActiveOpens|PassiveOpens|CurrEstab)' | tee -a "$LOG_FILE"

    # [New Conn/s 측정을 위한 사후 계산]
    END_TIME=$(date +%s.%N 2>/dev/null || date +%s)
    OPENS_AFTER=$(nstat -az 2>/dev/null | awk '/TcpActiveOpens/{a=$2} /TcpPassiveOpens/{p=$2} END{print a+p}')

    NEW_CONN_COUNT=$((OPENS_AFTER - OPENS_BEFORE))
    ELAPSED_SEC=$(awk -v start="$START_TIME" -v end="$END_TIME" 'BEGIN { dur=end-start; if(dur<=0) dur=0.001; printf "%.3f", dur }')
    NEW_CONN_PER_SEC=$(awk -v conn="$NEW_CONN_COUNT" -v dur="$ELAPSED_SEC" 'BEGIN { if(dur>0) printf "%.1f", conn/dur; else print 0 }')

    # 결과 요약 파싱
    TOTAL_REQ=$(wc -l < "$TMP_RESULT")
    OK_2XX=$(grep -c "^2" "$TMP_RESULT" 2>/dev/null || echo 0)
    ERR_5XX=$(grep -c "^5" "$TMP_RESULT" 2>/dev/null || echo 0)
    FAIL_000=$(grep -c "^000" "$TMP_RESULT" 2>/dev/null || echo 0)
    OTHER_CODE=$(grep -v -E "^(2|5|000)" "$TMP_RESULT" 2>/dev/null | awk '{print $1}' | sort | uniq -c | tr '\n' ' ')

    P95_RT=$(awk '{print $2}' "$TMP_RESULT" | sort -n | awk 'BEGIN{c=0} {a[c++]=$1} END{if(c>0) printf "%.2f ms", a[int(c*0.95)]*1000; else print "0 ms"}')
    AVG_RT=$(awk '{sum+=$2; c++} END{if(c>0) printf "%.2f ms", (sum/c)*1000; else print "0 ms"}' "$TMP_RESULT")
    POST_LOAD_TIME_WAIT=$(ss -ant '( sport = :80 )' | grep -c "TIME-WAIT" 2>/dev/null || echo 0)

    # 5. 해당 단계의 통합 결과 요약 리포트 출력
    echo "" | tee -a "$LOG_FILE"
    echo "---------------------------------------------------------------------" | tee -a "$LOG_FILE"
    echo " [단계 요약 리포트 - 요청 수: $count 개]" | tee -a "$LOG_FILE"
    echo "  - Total Requests      : $TOTAL_REQ" | tee -a "$LOG_FILE"
    echo "  - 2xx Success         : $OK_2XX" | tee -a "$LOG_FILE"
    echo "  - 5xx Errors          : $ERR_5XX" | tee -a "$LOG_FILE"
    echo "  - Curl Failure (000)  : $FAIL_000" | tee -a "$LOG_FILE"
    echo "  - Other Statuses      : ${OTHER_CODE:-None}" | tee -a "$LOG_FILE"
    echo "  - New Conn/s          : $NEW_CONN_PER_SEC conn/s (신규: $NEW_CONN_COUNT 개 / $ELAPSED_SEC 초)" | tee -a "$LOG_FILE"
    echo "  - Avg Response Time   : $AVG_RT" | tee -a "$LOG_FILE"
    echo "  - p95 Response Time   : $P95_RT" | tee -a "$LOG_FILE"
    echo "  - Post-load TIME_WAIT : $POST_LOAD_TIME_WAIT 개" | tee -a "$LOG_FILE"
    echo "---------------------------------------------------------------------" | tee -a "$LOG_FILE"

    echo ">>> 다음 부하 단계 진입 전 5초간 시스템 회복 대기..." | tee -a "$LOG_FILE"
    sleep 5
done

rm -f "$TMP_RESULT"

echo "" | tee -a "$LOG_FILE"
echo "=====================================================================" | tee -a "$LOG_FILE"
echo " [부하 테스트 전체 완료] $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "=====================================================================" | tee -a "$LOG_FILE"