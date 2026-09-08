#!/bin/bash
# ================================================
# DB 서버용 Promtail 설정
# ================================================
sudo usermod -aG systemd-journal,adm promtail

sudo tee /etc/promtail/config.yml <<'PROMTAIL_CONF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://10.0.2.100:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: db_ssh_logs
          __path__: /var/log/secure

      - targets:
          - localhost
        labels:
          job: db_messages
          __path__: /var/log/messages

  - job_name: mariadb
    static_configs:
      - targets:
          - localhost
        labels:
          job: mariadb_logs
          __path__: /var/log/mariadb/*.log
PROMTAIL_CONF

sudo systemctl daemon-reload
sudo systemctl enable promtail
sudo systemctl restart promtail
