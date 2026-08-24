#!/bin/bash
sudo tee /etc/promtail/config.yml <<'PROMTAIL_CONF'

# 1. Promtail 자체의 모니터링 포트
server:
  http_listen_port: 9080 # Promtail의 상태를 체크할 수 있는 포트
  grpc_listen_port: 0 # 안 쓸 거라 0으로 비활성화

# 2. 어디까지 읽었는지 기억하는 북마크(책갈피) 파일 --> 근데 ... 현재 환경 구성상 생성/삭제를 반복하고 있기 때문에 의미가 없을 수도 있음..
positions:
  filename: /tmp/positions.yaml
  # Promtail이 꺼졌다 켜져도 "아, 내가 아까 로그 파일 몇 번째 줄까지 읽었지?"를 기억하는 파일입니다.

# 3. 수집한 로그를 보낼 목적지 (Loki 주소/모니터링 서버의 주소)
clients:
  #- url: http://localhost:3100/loki/api/v1/push # Loki의 로그 수신 API endpoint
  # --> Promtail이 웹 서버 자기 자신에게 로그를 전송하려 하기 때문에 전송 실패(Connection Refused)가 발생
  # url은 실제 모니터링 서버의 private ip로 지정행야 함.
  - url: http://10.0.2.100:3100/loki/api/v1/push # 모니터링 서버 sg의 3100번 포트 열려있ㅇ어야 함. 다른 서버에서 받아와야 하니까.

# 4. 어떤 로그 파일을 어떻게 긁어올지(Scrape) 정의
scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: ssh_logs # Grafana에서 검색할 때 쓸 태그(라벨) 이름
          #__path__: /var/log/*.log # [가장 중요] 읽어올 로그 파일 경로 (예: /var/log/ 밑의 모든 .log 파일)
          __path__: /var/log/secure
          # dns 도 path 추가

      # 시스템 로그
      - targets:
          - localhost
        labels:
          job: ssh_system
          __path__: /var/log/messages
PROMTAIL_CONF