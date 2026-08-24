#!/bin/bash
#vpn 서버
${common_setting}

=======================================
wireguard 설치 및 설정
=======================================
sudo dnf install wireguard-tools iptables -y
sudo mkdir -p /etc/wireguard


umask 077

# 1. 설정
sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
[Interface]
Address = 10.100.0.1/24         # 서버의 VPN IP 주소
#SaveConfig = true                       # WireGuard 종료 시 설정을 저장 (선택 사항)
PrivateKey = ${s_pri_key}    # 서버의 비밀키 (wg genkey로 생성)
ListenPort = 51820                                              # 서버가 수신 대기할 포트

# NAT 설정 및 트래픽 포워딩을 위한 iptables 규칙 
# 이거 설정 안해주면 내부 서버 -> 외부 로의 통신이 안될 수도 있음?? 
# ** 각각 이해하기 필수 **
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT

[Peer]
PublicKey = ${c_pub_key}        # 클라이언트의 공개키
AllowedIPs = 10.100.0.2/32               
EOF

sudo chmod 600 /etc/wireguard/wg0.conf

# 2. forward 설정 하기 
# (1). 임시 활성화 
sudo sysctl -w net.ipv4.ip_forward=1

# (2). 영구 활성화
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-wireguard.conf
sudo sysctl -p

# (3). 상태 확인
sudo cat /proc/sys/net/ipv4/ip_forward

# 3. 서비스 동작 시키기
sudo wg-quick up wg0
#sudo systemctl enable wg-quick@wg0
sudo wg show

#=======================================
# 맨 마지막 dns 설정
#=======================================
sudo resolvectl dns $IFACE 10.0.1.53