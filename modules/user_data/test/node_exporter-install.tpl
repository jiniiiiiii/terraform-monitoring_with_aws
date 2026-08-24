#!/bin/bash
#모니터링 구축 과정 기록

# 1. node exporter 설치
wget https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz
tar xvfz node_exporter-1.10.2.linux-amd64.tar.gz

#원래 이 아래대로 하는게 정석적이지만.. 이렇게 하면 스크립트가 안 끝남. (종료가 안됨.) 
# 해결법 : systemd에 등록하기
#cd node_exporter-1.10.2.linux-amd64
#./node_exporter

# 2. 실행 파일을 시스템 바이너리 경로로 이동
sudo mv node_exporter-1.10.2.linux-amd64/node_exporter /usr/local/bin/

# 3. systemd 파일 생성
# - tee : 출력 결과를 파일과 화면에 동시에 
#   tee 파일명 저장할_결과
sudo tee /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=ec2-user
ExecStart=/usr/local/bin/node_exporter
Restart=always

#[Install] 서비스를 활성화 할 때, 리눅스가 어떻게 처리할지 정의하는 구역
[Install]
#다중 사용자 모드 -> 일반적인 정상상태가 되면, 서비스 자동 실행
WantedBy=multi-user.target
EOF

# 4. systemd 데몬 재로드 및 서비스 시작/자동 등록
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter