#!/bin/bash
# crond에 등록 권장
# 로그가 저장될 파일 경로 (날짜별로 분리하려면: disk_monitor_$(date +%Y%m%d).log)
LOG_FILE="/home/ec2-user/disk_monitor.log"
# 또는 일반 사용자 홈 디렉터리에 저장 시:
# LOG_FILE="/home/ec2-user/disk_monitor.log"

{
  echo "======================================================"
  echo "TIMESTAMP: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "======================================================"

  echo "[df -h]"
  echo "$(df -h)"
  echo ""

  echo "[df -i]"
  echo "$(df -i)"
  echo ""

  echo "[lsblk]"
  echo "$(lsblk)"
  echo ""

  echo "[du -xhd2 /home /var /tmp (Top 30)]"
  echo "$(du -xhd2 /home /var /tmp 2>/dev/null | sort -hr | head -30)"
  echo ""

  echo "----------------------------------------------------"
  echo "[iostat -xz 1 2]"
  echo "$(iostat -xz 1 1)"
  echo ""
  echo ""
} >> "$LOG_FILE" 2>&1