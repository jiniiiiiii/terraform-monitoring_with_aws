#!/bin/bash
# 그라파나 설치 스크립트

# 1. GPG 키 가져오기
wget -q -O gpg.key https://rpm.grafana.com/gpg.key
sudo rpm --import gpg.key

#2. yum 레포에 추가
sudo tee /etc/yum.repos.d/grafana.repo <<FIN
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
FIN

# 3. 설치 
sudo dnf install grafana -y

# 4. 실행 등록
sudo systemctl enable grafana-server
sudo systemctl start grafana-server


# 5. 그라파나 설정 파일 저장할 곳 만들어야 함. 
sudo mkdir -p /var/lib/grafana/dashboards

# 6. 대시보드.yml 설정파일 생성
sudo tee /etc/grafana/provisioning/dashboards/dashboard.yaml<<FIN
apiVersion: 1

providers:
  - name: "default"
    orgId: 1
    folder: ""
    type: file
    disableDeletion: false
    editable: true

    options:
      path: /var/lib/grafana/dashboards
FIN

# 7. DataSource.yml 생성ㅇㅇ
sudo tee /etc/grafana/provisioning/datasources/prometheus.yaml<<KFIN
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
FIN