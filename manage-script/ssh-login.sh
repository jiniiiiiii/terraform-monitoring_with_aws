#!/bin/bash
echo "==== 기본적인 셋팅을 시작합니다. ===="
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEV_DIR="${SCRIPT_DIR}/.."

# AWS 환경변수 로드 (파일이 있을 경우)
if [ -f "$SCRIPT_DIR/aws-env.sh" ]; then
    source "$SCRIPT_DIR/aws-env.sh"
fi

# 1. ssh-agent 실행
echo "1. ssh-agent를 실행합니다..."
eval $(ssh-agent -s) > /dev/null

# 2. 키 등록
echo "2. SSH 키를 등록 중입니다..."
chmod 400 ~/terraform-key.pem 2>/dev/null
ssh-add ~/terraform-key.pem

# 3. 사용자 입력 받기
echo "----------------------------------------"
echo "서버 정보를 입력 받습니다."
read -p "user (기본값: ec2-user): " user
user=${user:-ec2-user} # 엔터만 치면 기본값 ec2-user 사용

read -p "ServerName (예: bastion, web01, web03, db, monitor, internal_dns, vpn): " server_name
echo "----------------------------------------"
# 4. Bastion 공인 IP 추출
# 모든 서버는 bastion을 통해 경유해야 하므로, bastion의 ip를 추출함. 
echo "bastion IP 를 추출합니다. "
BASTION_IP=$(terraform -chdir="$DEV_DIR" output -json ec2-pub-ip | sed -n 's/.*"bastion":"\([^"]*\)".*/\1/p')

if [ -z "$BASTION_IP" ]; then
    echo "❌ Error: Bastion Public IP를 가져올 수 없습니다. terraform output을 확인하세요."
    exit 1
fi

# 5. 접속 분기
if [ "$server_name" == "bastion" ]; then
    echo "Bastion($BASTION_IP)으로 직접 접속합니다..."
    ssh "$user@$BASTION_IP"
else
    # 대상 서버의 Private IP 추출
    TARGET_IP=$(terraform -chdir="$DEV_DIR" output -json ec2-pri-ip | sed -n "s/.*\"$server_name\":\"\([^\"]*\)\".*/\1/p")
    
    if [ -z "$TARGET_IP" ]; then
        echo "❌ Error: '$server_name' 서버의 Private IP를 찾을 수 없습니다. (Dev/output.tf의 ec2-pri-ip 확인)"
        exit 1
    fi

    echo "Bastion($BASTION_IP)을 거쳐 $server_name($TARGET_IP)에 접속합니다..."
    ssh -J "$user@$BASTION_IP" "$user@$TARGET_IP"
fi
