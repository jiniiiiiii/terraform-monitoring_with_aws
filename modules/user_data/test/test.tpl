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
