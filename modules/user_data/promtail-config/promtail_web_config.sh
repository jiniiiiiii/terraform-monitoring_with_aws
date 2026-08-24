#!/bin/bash
# ================================================
# 권한 수정
# ================================================
# 1. promtail이 로그를 읽기 위해 권한 부여 --> adm 그룹에 추가 
sudo usermod -aG systemd-journal,adm promtail

# 2. 권한 부여 -  acl 도 설정
# - /var/log 이하 모든 파일/디렉토리에 promtail 읽기 권한 부여
sudo setfacl -R -m u:promtail:rx /var/log/nginx

# mask 값도 설정 
sudo setfacl -m m::rx /var/log/nginx

# - 향후 /var/log 내에 새 파일/폴더가 생성되어도 promtail 읽기 권한을 자동으로 상속받도록 설정 (Default ACL)
# -d, -m : default mask
sudo setfacl -R -d -m u:promtail:rx /var/log/nginx

# ================================================
# 파일 생성
# ================================================
sudo tee /etc/promtail/config.yml<<FIN
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
          job: nginx_logs # Grafana에서 검색할 때 쓸 태그(라벨) 이름
          #__path__: /var/log/*.log # [가장 중요] 읽어올 로그 파일 경로 (예: /var/log/ 밑의 모든 .log 파일)
          __path__: /var/log/nginx/*.log
          # dns 도 path 추가

#      - targets:
#          - localhost
#        labels:
#          job: web_system
#          __path__: /var/log/messages
FIN

# 5. 데몬 재시작
sudo systemctl daemon-reload
sudo systemctl enable promtail
sudo systemctl restart promtail