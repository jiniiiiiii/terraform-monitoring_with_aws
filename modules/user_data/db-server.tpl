#!/bin/bash
# ==========================================
# 1. MariaDB Server 패키지 설치
# ==========================================
sudo dnf install -y mariadb105-server mariadb105

# ==========================================
# 2. 공통 환경 설정 (Swap, Node Exporter, Promtail)
# ==========================================
${common_setting}

# ==========================================
# 3. MariaDB 바인드 주소 및 인코딩 설정 (0.0.0.0 허용)
# ==========================================
sudo tee /etc/my.cnf.d/mariadb-server.cnf >/dev/null <<'EOF'
[mysqld]
bind-address = 0.0.0.0
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
EOF

# 서비스 시작 및 자동 실행 활성화
sudo systemctl enable --now mariadb

# ==========================================
# 4. 초기 데이터베이스 및 사용자 생성
# ==========================================
sudo mysql -e "CREATE DATABASE IF NOT EXISTS ${db_name} DEFAULT CHARACTER SET utf8mb4;"
sudo mysql -e "CREATE USER IF NOT EXISTS '${db_user}'@'%' IDENTIFIED BY '${db_password}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${db_user}'@'%' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"


# ==========================================
# 5. 테스트 스크립트 모듈 다운로드
# ==========================================
sudo dnf install git -y
git clone --depth 1 https://github.com/jiniiiiiii/terraform-monitoring_with_aws.git /tmp/repo
cp -r /tmp/repo/monitoring_test-scripts /home/ec2-user/
rm -rf /tmp/repo
chown -R ec2-user:ec2-user /home/ec2-user/monitoring_test-scripts
chmod +x -R /home/ec2-user/monitoring_test-scripts

# ==========================================
# 6. 내부 DNS 등록
# ==========================================
sudo resolvectl dns $IFACE 10.0.1.53
