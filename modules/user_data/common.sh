#!/bin/bash

# 공통 업데이트
dnf update -y

# 네임서버를 위한 NIC 변수로 지정
IFACE=$(ip route show default | awk '{print $5}')

# 한국 타임존 설정
sudo timedatectl set-timezone Asia/Seoul

# ==========================================
# swap 활성화 
# - ram 부족으로 패키지 설치 시 killed 예방
# ==========================================
if [ ! -f /swapfile ]; then
  sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
        # if=/dev/zero : 입력파일(if)로 0으로 가득 찬 특수 디바이스 장치를 지정함. 
        # of=/swapfile : 출력파일(of)로 /swapfile을 지정. 
        # bs=1M : 블록크기 단위는 1MB
        # count=1024 : 블록을 몇 개 생성할지 --> 즉 1기가 생성할거임. 
  sudo chmod 600 /swapfile    # 일반 유저는 읽기 제한. -> 설정 안하면 리눅스 커널 경고
  sudo mkswap /swapfile   # mkswap : 스왑 공간으로 사용할 수 있도록 포맷 초기화 
  sudo swapon /swapfile   # swapon : 즉시 가상 메모리로 활성화 시작
  echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab    # /fstab 에 등록 --> 재부팅 되어도 사용 가능하게끔
fi





# ==========================================
# node_exporter 설치 및 설정
# ==========================================
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
ExecStart=/usr/local/bin/node_exporter --collector.systemd   
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


# ==========================================
# promtail 설치 및 설정
# ==========================================
# 1. 설치를 위한 repo 추가 
wget -q -O gpg.key https://rpm.grafana.com/gpg.key
sudo rpm --import gpg.key

# - root 권한으로 실해되므로 >/dev/null 붙여서 출력 화면 깔끔하게
sudo tee /etc/yum.repos.d/grafana.repo >/dev/null <<EOF
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
EOF

# 설치
sudo dnf install promtail -y


# 4. 설정 파일 가져오기 및 구동
#sudo aws s3 cp s3://terraform-project-config/config-yml/promtail-config.yml /etc/promtail/config.yml
${promtail_config}


sudo systemctl enable --now promtail

