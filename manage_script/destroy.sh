#!/bin/bash 
# *수정 필요* 

# 1. path 지정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # 현재 디렉터리를 절대 경로로 구함
# (결과 예시: /mnt/e/0.skill-study/terraform/Dev/manage_script)
echo "스크립트 디렉토리: ${SCRIPT_DIR}"
source "${SCRIPT_DIR}"/aws-env.sh

# 2. 스크립트 위치 기준으로 두 단계 위(../../)로 이동하여 최상위 루트 절대 경로를 구합니다.
# (결과 예시: /mnt/e/0.skill-study/terraform)
MY_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# aws-env 수행 -> 같은 디렉터리 위치 내에 aws-env.sh에 자격증명 정보 기입한 파일 생성

# 프로젝트 DIR 지정
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
echo "프로젝트 디렉토리: ${PROJECT_DIR}"

#3. 안전 장치 설정 + 사전 작업 디렉터리 점검
set -e

if [ ! -d "${PROJECT_DIR}" ]; then
    echo "❌ 오류: Target 디렉터리(${PROJECT_DIR})가 존재하지 않습니다."
    exit 1
fi

# 3. 람다 삭제
# - 근데 람다가 다른 리소스랑 의존성으로 연결되어있어서 다른 것도 삭제되고 람다 삭제됨.
# -> 처음엔 제대로 동작 안하는 줄 알았음... 
terraform -chdir="${PROJECT_DIR}" destroy \
    -var-file="dev.tfvars" \
    -target="aws_lambda_function.backend_lambda" \
    -auto-approve

echo "✔️ 람다 삭제 명령 완료!"

# * set -e랑 겹쳐서 사용 x --> 충돌 가능성 있음. 사전에 ㅇ오류 발생하면 중단하도록 설정
# if [ $? -eq 0 ]; then
#     echo "✔️ 람다 삭제 명령 성공."
# else
#     echo "❌ 람다 삭제 중 오류 발생. 스크립트를 중단합니다."
#     exit 1
# fi



# 4. 잠시 대기를 위한 progress 바
echo "ENI 오류를 피하기 위해 잠시 대기합니다."
# 10%부터 100%까지 10번 반복 (10, 20, 30... 100)
for i in {1..10}
do
    percent=$((i * 10))

    # 진행 바 두께 조절 (i만큼 =를 채우고, 나머지는 공백으로 채움)
    bar=$(printf "%-${i}s" "=" | tr ' ' '=')
    spaces=$(printf "%-$((10 - i))s" " ")

    # 핵심: \r로 커서를 맨 앞으로 보낸 뒤 덮어쓰기!
    # -n 옵션은 줄바꿈(\n)을 하지 말라는 뜻입니다.
    echo -ne "\r다음 작업을 위한 대기: [${bar}${spaces}] ${percent}%" 

    # 20초 대기 (20초 * 10번 = 총 200초)
    sleep 50
done

# 출력이 끝난 후 다음 프롬프트가 예쁘게 떨어지도록 한 줄 내려줍니다.
echo ""


# 5. 모두 삭제
echo "모두 삭제합니다. 승인 요청을 해주세요"
terraform -chdir="${PROJECT_DIR}" destroy -var-file=dev.tfvars
