#!/bin/bash
# 모니터링 서버
sudo dnf update -y
#sudo dnf install git -y


# 설치
wget https://github.com/prometheus/prometheus/releases/download/v3.5.5/prometheus-3.5.5.linux-amd64.tar.gz

# 압축 해제
tar -zxf prometheus-3.5.5.linux-amd64.tar.gz

# 이동
cd prometheus-3.5.5.linux-amd64

# 실행 -> 포그라운드 실행 방법
./prometheus \
  --config.file=prometheus.yml