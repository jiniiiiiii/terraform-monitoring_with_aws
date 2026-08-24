#!/bin/bash
# 모니터링 서버
${common_setting}
#=======================================
# 프로메테우스 설치
#=======================================
sudo dnf install git -y

# 1. 설치  & 압축 해제
wget https://github.com/prometheus/prometheus/releases/download/v3.5.5/prometheus-3.5.5.linux-amd64.tar.gz
tar -zxf prometheus-3.5.5.linux-amd64.tar.gz
cd prometheus-3.5.5.linux-amd64

# 실행 -> 포그라운드 실행 방법
# ./prometheus \
#   --config.file=prometheus.yml

# 2. 실행 파일 시스템 바이너리 경로로 이동 (필요한 파일 이동)
sudo cp prometheus /usr/local/bin/
sudo cp promtool /usr/local/bin/

sudo mkdir -p /etc/prometheus
#sudo cp prometheus.yml /etc/prometheus/ # ==> 기본 파일 사용 할 때

# 3. config.yml 파일 생성
sudo tee /etc/prometheus/user-prometheus.yml <<'PROMETHEUS_CONF'
${prometheus_setting}
PROMETHEUS_CONF




#아래 no such 라고 뜸.  --> console관련된건 3.0 이전 버전에서 사용되던 것. 
#sudo cp -r consoles /etc/prometheus/
#sudo cp -r console_libraries /etc/prometheus/

# 4. 데이터 저장 디렉토리 생성 및 권한 설정 
sudo mkdir -p /var/lib/prometheus
sudo chown -R ec2-user:ec2-user /etc/prometheus /var/lib/prometheus


# 5. systemd 생성
sudo tee /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
User=ec2-user
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/user-prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 6. systemd 데몬 재로드 및 서비스 시작/자동 등록
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

#=======================================
# 그라파나 설치 
#=======================================
# 1. GPG 키 가져오기
wget -q -O gpg.key https://rpm.grafana.com/gpg.key
sudo rpm --import gpg.key

#2. yum 레포에 추가
# - root 권한으로 실해되므로 >/dev/null 붙여서 출력 화면 깔끔하게
# - common.sh.tpl에서 공통적으로 레포 추가하기 때문에 필요 x
# sudo tee /etc/yum.repos.d/grafana.repo >/dev/null <<EOF
# [grafana]
# name=grafana
# baseurl=https://rpm.grafana.com
# repo_gpgcheck=1
# enabled=1
# gpgcheck=1
# gpgkey=https://rpm.grafana.com/gpg.key
# sslverify=1
# EOF

# 3. 설치 
sudo dnf install grafana -y


# 4. 그라파나 설정 파일 저장할 곳 만들어야 함. 
sudo mkdir -p /var/lib/grafana/dashboards
sudo chown grafana:grafana /var/lib/grafana/dashboards

# s3에서 json 가져오기
#aws s3 cp s3://terraform-project-config/dashboard-json /var/lib/grafana/dashboards/ --recursive
# - 오류시 에러 로그 추가
if ! aws s3 cp s3://terraform-project-config/dashboard-json /var/lib/grafana/dashboards/ --recursive; then
echo "Dashboard download failed"
exit 1
fi

# 5. dashboard.yml 설정파일 생성
sudo tee /etc/grafana/provisioning/dashboards/dashboard.yaml <<'GRAFANA_DASHBOARD'
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
    
    # 재시작 안해도 json 변경시 dashboadr 갱신
    updateIntervalSeconds: 10
GRAFANA_DASHBOARD

# 6. DataSource.yml 생성
sudo tee /etc/grafana/provisioning/datasources/prometheus-loki.yaml <<'GRAFANA_DATASOURCE'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    # editable: false # datasource를 프로비저닝으로 관리할 때


  - name: Loki
    type: loki
    access: proxy
    url: http://localhost:3100
    jsonData:
      maxLines: 1000  #grafana탐색 화면에서 한 번에 가져올 최대 로그 라인 수
GRAFANA_DATASOURCE

# 7. 실행 등록
sudo systemctl enable --now grafana-server

#=======================================
# loki install
#=======================================
# 1. 설치 
sudo dnf install loki -y

# 2. 설정 파일 수정 -> 파일 디렉토리 만들기. 근데 있어서 안 만들어도 될 듯. 
# sudo mkdir -p /etc/promtail
#sudo vi /etc/promtail/config.yml

# 3. 설정 파일 작성 -> 코드가 너무 길어질 것 같아서 이건 s3로 보내기...  --> 추후에. 일단 local변수 이용
#sudo aws s3 cp s3://terraform-project-config/config-yml/loki-config.yml /etc/loki/config.yml
# *** yaml 파일은 출력 선언을 통해 넣어줘야 함. 
sudo tee /etc/loki/config.yml <<'EOF'
${loki_config}
EOF

sudo systemctl enable --now loki 

# =========================================
# END. 내부 DNS 등록
sudo resolvectl dns $IFACE 10.0.1.53