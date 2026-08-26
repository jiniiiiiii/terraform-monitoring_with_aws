#!/bin/bash
LOG_FILE="upstream_result.txt"

for i in {1..300}; do
    # 현재 시간
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # curl 실행 및 결과 저장 -> 트래픽이랑 upstream이랑 같이 보고 싶을 때
    #RESULT=$(curl -s -o /dev/null -w 'HTTP %{http_code} | %{time_total}s' http://localhost/)
    RESULT=$(uptime)
    
    # 화면 출력과 동시에 로그 파일에 추가 저장
    echo "[$i/300] $TIMESTAMP - $RESULT" | tee -a "$LOG_FILE"
    
    sleep 5
done



===============================
#!/bin/bash
LOG_FILE="response-time-record.txt"


for i in {1..300}; do
    # 현재 시간
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # curl 실행 및 결과 저장 -> 트래픽이랑 upstream이랑 같이 보고 싶을 때
    #RESULT=$(curl -s -o /dev/null -w 'HTTP %{http_code} | %{time_total}s' http://localhost/)
    RESULT=$(curl -s -o /dev/null \
      -w 'status=%{http_code} time=%{time_total}s\n' \
      http://localhost/)
    
    # 화면 출력과 동시에 로그 파일에 추가 저장
    echo "[$i/300] $TIMESTAMP - $RESULT" | tee -a "$LOG_FILE"
    
    sleep 5
done