#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEV_DIR="${SCRIPT_DIR}/.."
echo "${DEV_DIR}"

source "$SCRIPT_DIR/aws-env.sh"
read -p "user: " user
#user="$ec2-user"
read -p "ServerName: " server_name

#IP=$(terraform -chdir="$DEV_DIR" output -raw web-ec2-pub-ip("${server_name}"))
# jq 를 이용한 불러오기 -> 근데 jq 없다고 함. 분명 있댔는데.. 
#IP=$(terraform -chdir="$DEV_DIR" output -json web-ec2-pub-ip | jq -r."$server_name")

# sed를 사용하여 JSON 문자열에서 지정한 server_name의 IP만 정확히 추출
IP=$(terraform -chdir="$DEV_DIR" output -json ec2-pub-ip | sed -n "s/.*\"$server_name\":\"\([^\"]*\)\".*/\1/p")


ssh -i ~/terraform-key.pem "$user@$IP"
