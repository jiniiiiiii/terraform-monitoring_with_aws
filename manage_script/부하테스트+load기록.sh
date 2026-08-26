#!/bin/bash

# 로그 파일 이름 설정
LOG_FILE="load_test.log"

echo "=========================================" | tee "$LOG_FILE"
echo " 부하 테스트 시작: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo " 대상: http://localhost/" | tee -a "$LOG_FILE"
echo "=========================================" | tee -a "$LOG_FILE"

for i in {1..300}; do
    # 현재 시간
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # curl 실행 및 결과 저장
    RESULT=$(curl -s -o /dev/null -w 'HTTP %{http_code} | %{time_total}s' http://localhost/)
    
    # 화면 출력과 동시에 로그 파일에 추가 저장
    echo "[$i/300] $TIMESTAMP - $RESULT" | tee -a "$LOG_FILE"
    
    sleep 0.5
done

echo "=========================================" | tee -a "$LOG_FILE"
echo " 부하 테스트 완료: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo " 결과가 $LOG_FILE 에 저장되었습니다." | tee -a "$LOG_FILE"
echo "=========================================" | tee -a "$LOG_FILE"
