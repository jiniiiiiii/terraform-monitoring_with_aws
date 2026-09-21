# AWS Infrastructure IaC (Dev Environment)

> 🔗 **주요 문서 바로가기**
> * 📜 **[CHANGELOG.md (아키텍처 변경 이력 & 패치노트)](./CHANGELOG.md)**
> * 🛠️ **[manage-script/info.md (인프라 운영 및 SSH 접속 스크립트 가이드)](./manage-script/info.md)**

이 프로젝트는 AWS 상에 고가용성 3-Tier 웹 애플리케이션 아키텍처 및 Bastion, WireGuard VPN, 중앙 집중형 모니터링(Prometheus/Grafana/Loki), 사설 DNS(Bind9) 시스템을 구축하기 위한 Terraform(테라폼) 코드입니다.

---

## 🏗️ 시스템 아키텍처 개요

전체 인프라는 **Service Layer(서비스 영역)**와 **Manage Layer(관리 영역)**로 명확히 분리되어 있으며, 공용 진입점(Public)과 안전한 내부망(Private)으로 2계층 격리되어 있습니다.

```mermaid
graph TD
    subgraph Internet
        User([외부 사용자])
        Admin([관리자 / 로컬 PC])
    end

    subgraph AWS VPC (10.0.0.0/16)
        subgraph Service Layer
            subgraph Service Public Subnets
                ALB[Application Load Balancer]
                Web1[Web Server 01 - 10.0.1.10 / AZ-a]
                Web3[Web Server 03 - 10.0.1.150 / AZ-c]
            end

            subgraph Service Private Subnet
                Lambda[AWS Lambda WAS Backend]
                DB[(EC2 MariaDB / MySQL - 10.0.10.33 / AZ-a)]
            end
        end

        subgraph Manage Layer
            subgraph Manage Public Subnet
                VPN[WireGuard VPN Server - AZ-a]
                Bastion[Bastion Jump Host - 10.0.2.22 / AZ-a]
            end

            subgraph Manage Private Subnet
                Monitor[Monitoring Server - 10.0.20.100 / AZ-a]
                DNS[Internal DNS Server - 10.0.20.53 / AZ-a]
            end
        end

        NAT[NAT Gateway]
    end

    User -->|HTTP/HTTPS 80/443| ALB
    ALB --> Web1 & Web3
    Web1 & Web3 --> Lambda
    Lambda --> DB
    
    Admin -->|SSH 22| Bastion
    Admin -->|UDP 51820| VPN
    Bastion -.->|ProxyJump SSH| Web1 & Web3 & DB & Monitor & DNS
    Monitor -->|Scrape 9100| Web1 & Web3 & DB & Bastion & DNS & VPN
    Service_Private & Manage_Private -.->|Outbound Internet| NAT
```

### 1. Network & Load Balancing
* **VPC & Subnet**: `modules/subnet` 공통 템플릿 모듈을 통해 `main.tf`에서 필요한 가용 영역(AZ-a, AZ-c) 및 CIDR 대역을 동적으로 선언합니다.
* **Gateways & Routing**: 인터넷 게이트웨이(IGW), NAT 게이트웨이(NGW), EIP 및 기본 라우팅(`0.0.0.0/0`)이 `gw.tf`로 분리되어 모듈 간 순환 의존성 없이 유연하게 트래픽을 처리합니다.
* **Application Load Balancer (ALB)**: 외부 HTTP/HTTPS 트래픽을 수신하여 다중 AZ 퍼블릭 서브넷의 Web 인스턴스들로 부하를 분산합니다.

### 2. Compute (EC2 & 모듈화)
* **Web Server**: 다중 가용영역(AZ-a, AZ-c)에 분산 배치되며, ALB 타겟 그룹에 자동으로 등록됩니다.
* **Bastion Jump Host**: 프라이빗 서브넷에 위치한 내부 자원들에 안전하게 접근하기 위한 단일 SSH 진입점(`10.0.2.22`)입니다.
* **Monitoring Server**: Prometheus, Grafana, Loki를 구동하는 전용 모니터링 서버(`10.0.20.100`)입니다.
* **Internal DNS Server**: `dev.internal` 도메인 해석을 담당하는 Bind9 기반 사설 DNS 네임서버(`10.0.20.53`)입니다.
* **WireGuard VPN Server**: VPC 내부 자원 및 사설 도메인에 로컬 PC에서 안전하게 접근할 수 있는 VPN 터널을 제공합니다.
* **Database Server**: 비용 효율성을 위해 프라이빗 서브넷에 셀프호스팅된 EC2 MariaDB/MySQL(`10.0.10.33`, `t3.micro`) 인스턴스입니다.

### 3. Serverless Backend (WAS)
* **AWS Lambda**: Python 3.11 런타임 기반의 백엔드 API 서버입니다. 다중 AZ 프라이빗 서브넷 내부에서 안전하게 실행되며, Function URL 및 API Gateway를 통해 프론트엔드와 통신합니다.

---

## 📂 프로젝트 폴더 구조

```text
Dev/
├── modules/
│   ├── vpc/                 # VPC 본체 및 라우팅 테이블 껍데기 모듈
│   ├── subnet/              # 서브넷 생성, CIDR 출력 및 라우팅 테이블 자동 연결 모듈
│   ├── ec2/                 # EC2 인스턴스 공통 배포 및 ALB 타겟그룹 조건부 연결 모듈
│   └── user_data/           # 인스턴스 초기화 템플릿 (.tpl) 및 Promtail 쉘 스크립트
├── manage-script/           # [신규] 인프라 운영, 삭제 및 SSH 접속 자동화 스크립트
│   ├── aws-env.sh           # AWS 인증 자격 증명 환경 변수 (Git 제외)
│   ├── destroy.sh           # 의존성 꼬임 방지 안전 인프라 삭제 스크립트
│   ├── ssh-login.sh         # Bastion ProxyJump 기반 SSH 원클릭 접속 스크립트
│   └── info.md              # 관리 스크립트 매뉴얼 및 가이드
├── monitoring_test-scripts/ # 모니터링 및 알람 시스템 검증용 부하/장애 테스트 스크립트
├── gw.tf                    # Internet Gateway, NAT Gateway, EIP 및 기본 라우팅 경로
├── alb.tf                   # Application Load Balancer 및 리스너/타겟그룹 설정
├── main.tf                  # 서브넷 동적 선언, EC2 인스턴스 배포 등 메인 오케스트레이션
├── rds.tf                   # Multi-AZ RDS 서브넷 그룹 백업 보관 (미사용)
├── lambda.tf                # WAS Lambda 함수, VPC Config 및 Function URL 설정
├── sg.tf                    # 보안 그룹(Security Group) 방화벽 규칙 정의
├── ssm.tf                   # AWS Systems Manager Parameter Store 설정 (민감 정보 관리)
├── provider.tf              # AWS Provider 및 S3 Remote Backend 설정
├── variables.tf             # 전역 변수 정의
├── dev.tfvars               # [로컬 전용] 개발 환경 변수 값 정의 (Git 커밋 금지)
├── CHANGELOG.md             # 아키텍처 개편 및 변경 이력 상세 기록 (패치노트)
└── README.md                # 인프라 전체 가이드 및 매뉴얼
```

---

## 🔑 서버 접속 방법 (SSH with Bastion)

프라이빗 서브넷에 위치한 내부 서버들(DB, Monitoring, DNS 등)은 공인 IP가 없으므로 Bastion 서버를 거쳐 접속해야 합니다.

### 1. 운영 스크립트 이용 (추천 ⭐)
`manage-script/ssh-login.sh`를 실행하면 `ssh-agent` 등록과 Bastion ProxyJump가 자동으로 수행됩니다:
```bash
./manage-script/ssh-login.sh
# 1. user: 엔터 (기본값: ec2-user)
# 2. ServerName: db (또는 web_01, monitor, internal_dns, bastion)
```

### 2. 수동 ProxyJump 명령어 이용
```bash
# 내 PC의 pem 키 하나로 Bastion을 거쳐 내부 서버(10.0.10.33)로 다이렉트 접속
ssh -i ~/terraform-key.pem -J ec2-user@<Bastion_Public_IP> ec2-user@10.0.10.33
```

---

## 🔑 WireGuard VPN 접속 및 사용 방법

개발망(VPC Private Subnet)의 자원들과 내부 사설 도메인(`*.dev.internal`)에 로컬 PC에서 안전하게 접속하기 위해 VPN 터널을 이용합니다.

### 1. 클라이언트(사용자 PC) 키 생성
```bash
wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key
```

### 2. 클라이언트 설정 파일 작성 (`/etc/wireguard/wg0.conf`)
`/etc/wireguard/wg0.conf`를 생성하고 아래 설정 예시를 입력합니다:

```ini
[Interface]
# 로컬 가상 네트워크 인터페이스 정보
Address = 10.100.0.2/24
PrivateKey = <클라이언트 개인키>
# VPC 내부 사설 DNS 서버를 바라보도록 설정
DNS = 10.0.20.53

[Peer]
# VPN 서버의 공개키
PublicKey = <서버 공개키 (s_pub_key)>
# VPN 서버의 공인(Public) IP와 포트
Endpoint = <VPN 서버 퍼블릭 IP>:51820
# VPN 터널을 통해 전송할 목적지 네트워크 대역 (VPC CIDR 및 VPN 가상 대역)
AllowedIPs = 10.0.0.0/16, 10.100.0.0/24
# 연결 유지 주기 (NAT 세션 끊김 방지)
PersistentKeepalive = 25
```

### 3. 접속 테스트
1. WireGuard 클라이언트에서 `활성화(Activate)` 버튼을 클릭합니다.
2. 터널이 가동되면 터미널에서 내부 사설 DNS 해석이 올바르게 진행되는지 검증합니다:
   ```bash
   nslookup web01.dev.internal
   # 10.0.1.10으로 해석되면 정상입니다.
   ```

---

## 🛠️ User Data 초기화 스크립트 설명

`modules/user_data/` 디렉토리에 위치한 `.tpl` 템플릿들은 EC2 인스턴스가 최초 부팅(부트스트랩)될 때 필요한 패키지와 설정을 자동으로 적용합니다.

* **`common.sh`**: Swap 메모리 2GB 자동 할당, Node Exporter 설치, Promtail 로그 수집기 설정 등 공통 의존성 처리.
* **`bastion-server.tpl`**: 점프 호스트용 기본 패키지 및 사설 DNS(`10.0.20.53`) 리졸버 설정.
* **`web-server.tpl`**: Nginx 웹 데몬 구동 및 로컬 웹 로그(Access/Error) 수집 설정.
* **`db-server.tpl`**: MariaDB/MySQL 자동 설치, `bind-address = 0.0.0.0` 원격 접속 허용 및 초기 DB/유저 생성.
* **`monitor-server.tpl`**: Prometheus, Grafana, Loki 다운로드 및 systemd 서비스 등록.
* **`internal-dns-server.tpl`**: Bind9 사설 DNS 네임서버(`dev.internal`) 구성 (정방향/역방향 PTR 레코드 관리).
* **`vpn-server.tpl`**: WireGuard VPN 데몬 기동, 트래픽 포워딩(NAT) 설정 및 VPC 내부 라우팅 연동.

---

## 🧪 모니터링 검증 및 부하 테스트 스크립트 (`monitoring_test-scripts/`)

`monitoring_test-scripts/` 디렉토리는 Prometheus, Grafana, Loki 대시보드와 Alert Manager를 검증하기 위해 인위적 부하 및 장애 상황을 유발하는 테스트 스크립트 모음입니다.

* **`cpu-load-check_uptime.sh`**: 서버의 `uptime` 및 웹 응답 속도/상태 코드를 지속적으로 캡처하여 로그 파일에 기록합니다.
* **`cpu-load-test_with-web-traffic.sh`**: 웹 서버로 연속적인 HTTP 요청을 발송하며 응답 시간 및 상태 코드를 기록하는 부하 테스트 스크립트입니다.
* **`disk-state-record.sh`**: 디스크 용량(`df`), 아이노드(`df -i`), 블록 디바이스(`lsblk`), 상위 사용량 디렉토리(`du`), I/O 성능(`iostat`)을 주기적으로 로그로 남깁니다.
* **`disk-write-state_check.sh`**: 지속적인 디스크 쓰기 동작을 유발하며 디스크 메트릭 변화 및 상태를 체크합니다.
* **`memory_make-oom_test.sh`**: `systemd-run`을 통해 메모리 상한을 600MB로 제약한 뒤 Python으로 메모리를 할당하여 강제로 OOM(Out of Memory) 장애 상황을 유발합니다.
* **`traffic-test_web.sh`**: 로컬 웹 서버에 정상 200 OK 및 404 Not Found 요청 트래픽을 지속적으로 생성합니다.

---

## 🚀 시작하기 (How to Run)

### 1. 사전 준비 사항
* **AWS CLI** 설치 및 자격 증명(Access Key/Secret Key) 구성
* **Terraform CLI** (v1.2 이상 권장) 설치
* **S3 Bucket 생성**: 테라폼 상태 파일(`terraform.tfstate`)을 저장할 원격 S3 버킷 사전 생성 (`provider.tf` 참고)

### 2. 환경 변수 파일 생성 (`dev.tfvars`)
로컬 환경에서 테라폼을 배포할 때 입력할 변수를 설정하기 위해 `dev.tfvars` 파일을 생성하고 값을 기입합니다.
> [!IMPORTANT]
> 이 파일은 패스워드 및 개인 IP를 담고 있으므로 절대 Git에 커밋되지 않도록 주의해야 합니다. (`.gitignore`로 자동 제외됨)

```hcl
db_username  = "admin"
db_password  = "보안이_강력한_패스워드"
my_public_ip = "본인의_퍼블릭_IP_대역/32"
project      = "my-project"
```

### 3. 테라폼 배포 명령어

**초기화 (S3 백엔드 및 모듈/프로바이더 로드)**
```bash
terraform init
```

**인프라 변경 계획 확인**
```bash
terraform plan -var-file="dev.tfvars"
```

**인프라 실제 배포**
```bash
terraform apply -var-file="dev.tfvars"
```

---

## 🔒 보안 주의사항 (Security)

1. **상태 파일 보호 (`*.tfstate`)**: State 파일에는 DB 비밀번호 등 민감 정보가 평문으로 포함됩니다. 원격 S3 Backend를 활용해 안전하게 격리 보관하십시오.
2. **Access Key 노출 금지**: 절대 AWS 자격 증명이나 Key Pair(`.pem`)를 프로젝트 내에 저장하거나 Git에 커밋하지 마십시오.
3. **Security Groups 최소 권한 원칙**: SSH(22), Grafana(3000), Prometheus(9090)는 `var.my_public_ip` 변수를 통해 지정된 IP에서만 인바운드를 허용하십시오.

