#!/bin/bash
set -e # 오류 발생 시 스크립트 즉시 중단

ENV_SCRIPT="/mnt/e/0.skill-study/terraform/script/aws-env.sh"

if [ -f "$ENV_SCRIPT" ]; then
    source "$ENV_SCRIPT"
    echo "aws 인증 자격 획득 완료"
else
    echo "오류: $ENV_SCRIPT 파일을 찾을 수 없습니다."
    exit 1
fi

echo "테라폼 수행 시작합니다...."
terraform apply -var-file=dev.tfvars -auto-approve
