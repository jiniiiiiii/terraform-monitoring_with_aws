#!/bin/bash

# 1. 스크립트를 시행할 절대 경로 지정하기
# dirname : 디렉터리 명을 추출
# $0 : 특수변수, 현재

#(1)
echo "(1)dirname \"\$0\" 출력 결과"
dirname "$0"    # 현재 실행하는 파일 말고, 디렉터리명 출력
# ex) ./manage-script/practice.sh 라면 ./manage-script
# ex) ./Dev/manage-script/practice.sh 라면 ./Dev/manage-script
# ==> 아무튼 경로를 고정 시킴
echo""

echo "(2)cd \"\$(dirname \"\$0\")\" 수행 결과"
cd "$(dirname "$0")"  # (1)에서 출력 된 결과로 cd함
pwd # 결론적으로 dirname "$0" 값인데 절대 경로로 나옴. ==> && 으로 이어서 앞에꺼 출력 결과를 입력 값으로 받겠다는 뜻
echo""

echo "(3)앞에서 출력 값을 쉘 변수에 저장함"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo $SCRIPT_DIR
echo""
# 근데 사실 여기서는 cd: ./manage-script: No such file or directory
# 왜냐면 (2)단계에서 이미 이동했기 때문임. 

echo "(4)프로젝트 DIR 지정 DEV_DIR=\"\${SCRIPT_DIR}/..\""
DEV_DIR="${SCRIPT_DIR}/.."
echo $DEV_DIR # 출력에 /.. 이 그대로 나와도 컴퓨터는 한 칸 상위 폴더로 가라는걸 알아 들음. 

# ========================