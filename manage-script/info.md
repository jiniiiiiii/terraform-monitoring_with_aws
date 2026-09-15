이 스크립트들은 테라폼으로 관리할 때 유용하게 해줍니다. 

디렉터리 구조
manage-script/
├── aws-env.sh
├── destroy.sh
├── info.md
└── ssh-login.sh

aws-env.sh 는 본인의 aws 크레덴셜을 적어서 생성합니다. 
git에는 올리지 않습니다. 

destory는 삭제시 의존성 문제 해결을 위한 삭제 스크립트 입니다. 
ssh-login.sh는 각종 서버로의 로그인을 편리하게 돕습니다. 