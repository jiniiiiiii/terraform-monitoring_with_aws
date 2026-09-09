#!/bin/bash
# 연결 부하 테스트 및 단계별 시스템 상태 동시 기록 스크립트
# 동시에 또 하나의 터미널에서 top으로 cpu부하 관측하면 좋음 

LOG_FILE="connection_step-stress_result.log"

echo "============= Baseline (평상시 상태) =============" | tee -a "$LOG_FILE"
for i in {1..9}; do
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[Baseline $i][$CURRENT_TIME] $(uptime)" | tee -a "$LOG_FILE"
    sleep 3
done

echo "============= 100 Connections (부하 가동 중 실시간 기록) =============" | tee -a "$LOG_FILE"
# 1. wrk 부하 테스트를 백그라운드(&)에서 60초간 실행
#wrk -t1 -c100 -d60s http://127.0.0.1/ >> "$LOG_FILE" 2>&1 &     # 이거 굳이 출력값 저장할 필요가 있나?
wrk -t1 -c100 -d60s http://127.0.0.1/
WRK_PID=$!

# 2. wrk가 100 커넥션 부하를 주는 60초 동안 3초 간격으로 uptime 상태 기록 (총 20회 = 60초)
for i in {1..20}; do
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[Stress $i][$CURRENT_TIME] $(uptime)" | tee -a "$LOG_FILE"
    sleep 3
done

# 3. 백그라운드 wrk 작업 완료 대기
wait $WRK_PID

echo "============= 300 Connections (부하 가동 중 실시간 기록) =============" | tee -a "$LOG_FILE"
# 1. wrk 부하 테스트를 백그라운드(&)에서 60초간 실행
#wrk -t1 -c100 -d60s http://127.0.0.1/ >> "$LOG_FILE" 2>&1 &     # 이거 굳이 출력값 저장할 필요가 있나?
wrk -t1 -c300 -d60s http://127.0.0.1/
WRK_PID=$!

# 2. wrk가 100 커넥션 부하를 주는 60초 동안 3초 간격으로 uptime 상태 기록 (총 20회 = 60초)
for i in {1..20}; do
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[Stress $i][$CURRENT_TIME] $(uptime)" | tee -a "$LOG_FILE"
    sleep 3
done

# 3. 백그라운드 wrk 작업 완료 대기
wait $WRK_PID

echo "============= 500 Connections (부하 가동 중 실시간 기록) =============" | tee -a "$LOG_FILE"
# 1. wrk 부하 테스트를 백그라운드(&)에서 60초간 실행
#wrk -t1 -c100 -d60s http://127.0.0.1/ >> "$LOG_FILE" 2>&1 &     # 이거 굳이 출력값 저장할 필요가 있나?
wrk -t1 -c500 -d60s http://127.0.0.1/
WRK_PID=$!

# 2. wrk가 100 커넥션 부하를 주는 60초 동안 3초 간격으로 uptime 상태 기록 (총 20회 = 60초)
for i in {1..20}; do
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[Stress $i][$CURRENT_TIME] $(uptime)" | tee -a "$LOG_FILE"
    sleep 3
done

# 3. 백그라운드 wrk 작업 완료 대기
wait $WRK_PID


echo "============= 1000 Connections (부하 가동 중 실시간 기록) =============" | tee -a "$LOG_FILE"
# 1. wrk 부하 테스트를 백그라운드(&)에서 60초간 실행
#wrk -t1 -c100 -d60s http://127.0.0.1/ >> "$LOG_FILE" 2>&1 &     # 이거 굳이 출력값 저장할 필요가 있나?
wrk -t1 -c1000 -d60s http://127.0.0.1/
WRK_PID=$!

# 2. wrk가 100 커넥션 부하를 주는 60초 동안 3초 간격으로 uptime 상태 기록 (총 20회 = 60초)
for i in {1..20}; do
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[Stress $i][$CURRENT_TIME] $(uptime)" | tee -a "$LOG_FILE"
    sleep 3
done

# 3. 백그라운드 wrk 작업 완료 대기
wait $WRK_PID


# 서버 상태보고 2000번 수행
# echo "============= 2000 Connections (부하 가동 중 실시간 기록) =============" | tee -a "$LOG_FILE"
# # 1. wrk 부하 테스트를 백그라운드(&)에서 60초간 실행
# #wrk -t1 -c100 -d60s http://127.0.0.1/ >> "$LOG_FILE" 2>&1 &     # 이거 굳이 출력값 저장할 필요가 있나?
# wrk -t1 -c2000 -d60s http://127.0.0.1/
# WRK_PID=$!

# # 2. wrk가 100 커넥션 부하를 주는 60초 동안 3초 간격으로 uptime 상태 기록 (총 20회 = 60초)
# for i in {1..20}; do
#     CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
#     echo "[Stress $i][$CURRENT_TIME] $(uptime)" | tee -a "$LOG_FILE"
#     sleep 3
# done

# # 3. 백그라운드 wrk 작업 완료 대기
# wait $WRK_PID


echo "============= Post-Stress (부하 종료 후 회복 상태) =============" | tee -a "$LOG_FILE"
for i in {1..10}; do
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[Recovery $i][$CURRENT_TIME] $(uptime)" | tee -a "$LOG_FILE"
    sleep 3
done
