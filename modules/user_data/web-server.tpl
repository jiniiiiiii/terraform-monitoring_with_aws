#!/bin/bash
dnf install nginx -y

# 설치 후 동작 -> 권한 오류 방지 
${common_setting}

# 추가로 s3에서 index.html 가져오기
aws s3 sync s3://aws-saa-qbank.front-cicd /usr/share/nginx/html
sudo chown -R nginx:nginx /usr/share/nginx/html/*

# 템플릿 파일 안에서는 테라폼 리소스에 직접 접근할 수 없음. -> 조치 필요
# 템플릿 변수 사용
#LAMBDA_URL="$${aws_lambda_function_url.api-lambda-url.function_url}"
LAMBDA_URL="${lambda_url}"
LAMBDA_URL="$${LAMBDA_URL%/}"    
LAMBDA_DOMAIN=$(echo $LAMBDA_URL | sed -e 's|^https://||' -e 's|/||g') 

#cat <<'FIN' 이렇게 썼었는데 그냥 따옴표 없애기
cat <<FIN > /etc/nginx/default.d/api.conf
location /api/ {
    #root   /usr/share/nginx/html;
    #index  index.html index.htm
    
    # 프록시 설정
    proxy_pass $${LAMBDA_URL};
    proxy_set_header Host $${LAMBDA_DOMAIN};      #proxy pass 의 도메인으로 자동으로 변경되게 설정. $${LAMBDA_DOMAIN} 에서 변경
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;

    #헤더에 서버 이름 추가
    add_header X-Backend-Server "${server_name}" always;
}
FIN

# 기존 log_format main의 끝에 $request_time과 $upstream_response_time(WAS 응답시간)을 추가
sudo sed -i 's/"\$http_x_forwarded_for"/"\$http_x_forwarded_for" \$request_time \$upstream_response_time/g' /etc/nginx/nginx.conf

systemctl restart nginx

cat <<FIN > /home/ec2-user/restart-nginx.sh
#!/bin/bash
aws s3 cp s3://terraform-source/conf/nginx/api.conf /etc/nginx/default.d/api.conf

# 만약 s3에 파일이 없다면, 기본 생성
if [ ! -f /etc/nginx/default.d/api.conf ]; then
  echo "s3에 아직 기본 파일이 없음. 파일 생성합니다."
  echo " # checking for cicd pipeline . . . "  
  touch /etc/nginx/default.d/api.conf
fi
FIN
chmod +x /home/ec2-user/restart-nginx.sh
chown ec2-user:ec2-user /home/ec2-user/restart-nginx.sh

# nginx 시작
sudo systemctl enable --now nginx


# =========================================
# END. 내부 DNS 등록
sudo resolvectl dns $IFACE 10.0.1.53