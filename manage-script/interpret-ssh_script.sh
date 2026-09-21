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
echo "============================="
echo "무작정 수행하면 에러가 나기 때문에, 존재하는지 if문을 통해 수행함"
if [ -f "$SCRIPT_DIR/aws-env.sh" ]; then
    source "$SCRIPT_DIR/aws-env.sh"
fi

echo " 1. ssh-agent 수행"
eval $(ssh-agent -s) > /dev/null

echo "2. 키 등록합니다"
chmod 400 ~/terraform-key.pem 2>/dev/null
echo " 오류는 출력되지 않게끔, 오류는 무시하고 수행하게끔 2>/dev/null"

# 기본적인 ssh-agent 등록 과정 완료
# 로그인하고자 하는 사용자 입력 받기

echo "서버 정보를 입력 받습니다. 기본값(공백) ec2-user"
read -p "user : " user  # [출력할 메시지] [변수명]
user=${user:-ec2-user}

read -p "서버명 입력 : " server_name

echo " 우리의 서버는 bastion을 경유해서 들어가야 함. "
echo "그래서 bastion을 알아내도록 함. "
# (1) 프로젝트 경로로 가서 terrafrom output 값을 가져옴 
BASTION_IP=$(terraform -chdir="$DEV_DIR" output -json ec2-pub-ip |\
 sed -n 's/.*"bastion":"\([^"]*\)".*/\1/p')

    # 이 결과 값에서 bastion으로 시작하는 부분만 찾아서 가져온다. 
    # -n : 일단 화면에 아무것도 출력하지 마 
    # s/A/B/ : A를 찾아서 B로 치환해라
    # s/A/B/p : 치환에 성공했으면 출력해라. -n과 같이 씀. 

    # .(아무글자) + *(0개 이상) + "bastion":" 이라는 글자 포함되는지
    # [^"]* : 큰 따옴표(")가 아닌 글자들 --> 큰 따옴표가 나오기 직전 = IP주소
    # \1 : 1번 기억상자에 보관 ? 

    # 간단하게 json 파싱 도구인 jq를 이용할 수도 있음. 근데 jq설치 안되어있는 경우도 있어. 
    # 추가? jq있으면 jq로, 없으면 sed로

# 출력한 bastion ip 에 대한 조건문 
if [ -z "$BASTION_IP" ]; then
    echo " Error: No Bastion IP" 
    exit 1
fi

# 접속 분기 . -> 접속하려는 서버가 bastion인가 아닌가
if [ "$server_name" == "bastion" ]; then
    echo " Bastion($BASTION_IP)로 접슨합니다"
    ssh "$user@$BASTION_IP"
else
    # 다른 대상 서버의 IP 추출
    TARGET_IP=$(terraform -chdir="$DEV_DIR" output -json ec2-pri-ip |\
    sed -n "s/.*\"$server_name\":"\([^\"]*\)\".*/\1/p")

    if [ -z "$TARGET_IP" ]; then
    # target _ ip 확인 
        echo "Error: '$server_name'을 찾을 수 없습니다. "
        exit 1
    fi

    # 로그인 하기 
    echo "bastion을 거쳐 $server_name으로 로그인 합니다. "
    ssh -J "$user@$BASTION_IP" "$user@#TARGET_IP"
fi

