#!/bin/bash
# 1. install
sudo dnf install bind -y   # 확인 : named -v   --> BIND 9.18.49 (Extended Support Version) <id:>

# 설치 후 동작 --> 권한 오류 방지
${common_setting}

# 2. named.conf의 수정 사항
sudo tee /etc/named.conf<<FIN
${named_conf}
FIN
# sudo sed -i 's/127.0.0.1;/any; 10.0.1.53;/g' /etc/named.conf
# sudo sed -i 's/listen-on-v6/\/\/listen-on-v6/g' /etc/named.conf
# sudo sed -i 's/localhost/10.0.0.0\/16/g' /etc/named.conf
# sudo sed -i '/recursion yes;/a\        forwarders { 1.1.1.1; 10.0.0.2; };' /etc/named.conf

# 3. /etc/named.internal.zones 생성
sudo tee /etc/named.internal.zones<<FIN
zone "dev.internal" IN {
        type primary;
        file "dev.internal.zone";       // /var/named/terraform.internal.zone
        allow-update { none; };
};


//Reverse Zone
// - 보통 서브넷 전체 대역대를 관리하기 때문에 그렇게 쓰는게 나음. 
zone "1.0.10.in-addr.arpa" IN {
        type primary;
        file "10.0.1.rev";
        allow-update { none; };
};

zone "2.0.10.in-addr.arpa" IN {
        type primary;
        file "10.0.1.rev";
        allow-update { none; };
};
FIN

# 4 zone 파일 생성 (1)일반
#echo '\$TTL 3H' | sudo tee -a /var/named/dev.internal.zone  --> xxxx
echo '$TTL 3H' | sudo tee /var/named/dev.internal.zone
sudo tee -a /var/named/dev.internal.zone<<FIN
@       IN SOA dns01.dev.internal. admin.dev.internal. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
                                                                                   
                IN      NS      dns01.dev.internal.                                
dns01           IN      A       10.0.1.53                                          
                                                                                   
web01           IN      A       10.0.1.10                                          
web02           IN      A       10.0.1.11                                          
web03           IN      A       10.0.2.10

vpn01           IN      A       10.0.2.200
                                                                                   
monitor01       IN      A       10.0.2.100                                         
                                                                                   
backup01        IN      A       10.100.0.2  

db01            IN      A       10.0.2.33
bastion01       IN      A       10.0.1.22
FIN

# 4 zone 파일 생성 (2)rev
echo '$TTL 3H' | sudo tee /var/named/10.0.1.rev
sudo tee -a /var/named/10.0.1.rev<<FIN
@       IN SOA dns01.dev.internal. admin.dev.internal. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum

        IN      NS      dns01.dev.internal.
53      IN      PTR     dns01.dev.internal.
10      IN      PTR     web01.dev.internal.
11      IN      PTR     web02.dev.internal.
FIN

echo '$TTL 3H' | sudo tee /var/named/10.0.2.rev
sudo tee -a /var/named/10.0.2.rev<<FIN
@       IN SOA dns01.dev.internal. admin.dev.internal. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum

        IN      NS      dns01.dev.internal.
10      IN      PTR     web03.dev.internal.
22      IN      PTR     bastion01.dev.internal
33      IN      PTR     db01.dev.internal.
100     IN      PTR     monitor01.dev.internal.
200     IN      PTR     vpn01.dev.internal.
FIN

echo '$TTL 3H' | sudo tee /var/named/10.100.0.rev
sudo tee -a /var/named/10.0.1.rev<<FIN
@       IN SOA dns01.dev.internal. admin.dev.internal. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum

        IN      NS      dns01.dev.internal.
1       IN      PTR     vpn01.dev.internal.
2       IN      PTR     backup01.dev.internal.
FIN

# 5. 서비스 가동 
sudo named-checkconf /etc/named.conf
sudo systemctl enable --now named

# =========================================
# END. 내부 DNS 등록
sudo resolvectl dns $IFACE 10.0.1.53