# TIP
# ./Dev/monitoring_test-scripts/tcp/connection-basline_record.sh 2>&1 | tee -a result.txt 이런식으로 실행하고, 출력값 저장 가능. 

# Baseline 측정 함수
print_baseline() {
    echo "=========================================="
    echo " [Baseline Measurement] $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
    ss -s
    echo "[Nginx connection state]"
    ss -ant '( sport = :80 )' | awk 'NR>1 {print $1}' | sort | uniq -c
    echo "[TCP Statistics]"
    nstat -az | grep -E 'Tcp(InSegs|OutSegs|ActiveOpens|PassiveOpens|CurrEstab)'
    echo "=========================================="
}

# Ctrl+C 중단 또는 종료 시에도 마지막 Baseline 측정이 수행되도록 설정
cleanup() {
    echo -e "\n\n[측정 종료] 마지막 Baseline 상태를 측정합니다..."
    print_baseline
    exit 0
}
trap cleanup INT TERM

echo "=== 1. 시작 Baseline 측정 ==="
print_baseline

echo ""
echo "=== 2. 실시간 측정 시작 (총 5분 / CPU: 1초 간격, TCP 통계: 10초 간격) ==="
echo "중단하고 싶으면 Ctrl+C를 누르세요."
echo ""

# 총 5분 (300초) / 10초 주기 = 30회 반복
DURATION=300
INTERVAL=10
ITERATIONS=$((DURATION / INTERVAL))

for ((i=1; i<=ITERATIONS; i++)); do
    echo "--- [$(date '+%Y-%m-%d %H:%M:%S')] CPU Stats (주기 ${i}/${ITERATIONS}) ---"
    # mpstat: 1초 간격으로 10회 출력 (총 10초 소요)
    mpstat -P ALL 1 10
    
    echo ""
    echo "--- [$(date '+%Y-%m-%d %H:%M:%S')] TCP Statistics (10초 주기) ---"
    nstat -az | grep -E 'Tcp(InSegs|OutSegs|ActiveOpens|PassiveOpens|CurrEstab)'
    echo ""
done

echo "=== 3. 5분 측정 완료 ==="
cleanup