# AWS Infrastructure IaC (Dev Environment)

> 🔗 **주요 문서 바로가기**
> * 📜 **[CHANGELOG.md (아키텍처 변경 이력 & 패치노트)](./CHANGELOG.md)**
> * 🛠️ **[manage-script/info.md (인프라 운영 및 SSH 접속 스크립트 가이드)](./manage-script/info.md)**

이 프로젝트는 AWS 상에 고가용성 3-Tier 웹 애플리케이션 아키텍처 및 Bastion, WireGuard VPN, 중앙 모니터링(Prometheus/Grafana/Loki), 사설 DNS(Bind9) 시스템을 구축하기 위한 Terraform(테라폼) 코드입니다.

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
                VPN[WireGuard VPN - AZ-a]
                Bastion[Bastion Jump Host - 10.0.2.22 / AZ-a]
            end

            subgraph Manage Private Subnet
                Monitor[Monitoring Server - 10.0.20.100 / AZ-a]
                DNS[Internal DNS Server - 10.0.20.53 / AZ-a]
            end
        end

        NAT[NAT Gateway]
    end

    User -->|HTTP/HTTPS| ALB
    ALB --> Web1 & Web3
    Web1 & Web3 --> Lambda
    Lambda --> DB
    
    Admin -->|SSH 22| Bastion
    Admin -->|UDP 51820| VPN
    Bastion -.->|ProxyJump SSH| Web1 & Web3 & DB & Monitor & DNS
    Monitor -->|Scrape 9100| Web1 & Web3 & DB & Bastion & DNS & VPN
    Service_Private & Manage_Private -.->|Outbound| NAT
```

### 1. 계층별 서브넷 및 리소스 분리
* **Service Layer**:
  * **Public Subnets (`10.0.1.0/25`, `10.0.1.128/25`)**: Application Load Balancer(ALB) 및 Nginx Web 서버(`Web_01`, `Web_03`) 분산 배치 (Multi-AZ).
  * **Private Subnet (`10.0.10.0/24`)**: 안전하게 격리된 셀프호스팅 EC2 MariaDB(`10.0.10.33`) 및 Serverless Lambda WAS Backend.
* **Manage Layer**:
  * **Public Subnet (`10.0.2.0/24`)**: 외단 접속 관문인 WireGuard VPN 및 Bastion 점프 호스트(`10.0.2.22`).
  * **Private Subnet (`10.0.20.0/24`)**: 중앙 집중형 통합 모니터링 서버(Grafana/Prometheus/Loki `10.0.20.100`) 및 사설 DNS(`10.0.20.53`).

### 2. Network & Security (최소 권한 보안 설계)
* **공격 표면 최소화**: DB, 모니터링, DNS는 공인 IP(Public IP) 할당을 차단(`pub_ip_associate_bool = false`)하여 사설망에 완전 격리.
* **Bastion Jump Host**: 내부 모든 서버의 SSH(22) 포트는 오직 Bastion 보안 그룹(`bastion_sg.id`)을 통해서만 인바운드를 허용.
* **모니터링 순환 참조 방지**: Node Exporter(9100) 포트 인바운드는 보안 그룹 상호 참조 대신 프라이빗 관리 서브넷(`10.0.20.0/24`) 대역으로 제한하여 Terraform Cycle 문제를 원천 해결.

---

## 📂 프로젝트 폴더 구조

```text
Dev/
├── modules/
│   ├── vpc/                 # VPC 본체 및 라우팅 테이블 껍데기 모듈
│   ├── subnet/              # 서브넷 생성, CIDR 출력 및 라우팅 연결 모듈
│   ├── ec2/                 # EC2 인스턴스 배포 및 ALB 타겟그룹 조건부 연결 모듈
│   └── user_data/           # 인스턴스 초기화 템플릿 (.tpl) 및 Promtail 설정
├── manage-script/           # [신규] 인프라 운영, 삭제 및 SSH 접속 자동화 스크립트
│   ├── aws-env.sh           # AWS 인증 자격 증명 (Git 제외)
│   ├── destroy.sh           # 의존성 꼬임 방지 안전 삭제 스크립트
│   ├── ssh-login.sh         # Bastion ProxyJump 기반 SSH 원클릭 접속 스크립트
│   └── info.md              # 스크립트 매뉴얼 및 가이드
├── monitoring_test-scripts/ # 모니터링 및 알람 시스템 검증용 부하/장애 테스트 스크립트
├── gw.tf                    # Internet Gateway, NAT Gateway, EIP 및 기본 라우팅 경로
├── alb.tf                   # Application Load Balancer 및 리스너/타겟그룹 설정
├── main.tf                  # 서브넷 동적 선언, EC2 인스턴스 배포 등 메인 오케스트레이션
├── rds.tf                   # RDS Multi-AZ 서브넷 그룹 백업 보관 (미사용)
├── lambda.tf                # WAS Lambda 함수, VPC Config 및 Function URL 설정
├── sg.tf                    # 보안 그룹(Security Group) 방화벽 규칙 정의
├── ssm.tf                   # AWS Systems Manager Parameter Store 설정
├── provider.tf              # AWS Provider 및 S3 Remote Backend 설정
├── variables.tf             # 전역 변수 정의
├── dev.tfvars               # [로컬 전용] 개발 환경 변수 값 정의 (Git 커밋 금지)
├── CHANGELOG.md             # 아키텍처 개편 및 변경 이력 상세 기록 (패치노트)
└── README.md                # 인프라 전체 가이드 및 매뉴얼
```

---

## 🔑 서버 접속 방법 (SSH with Bastion)

프라이빗 서브넷에 위치한 내부 서버들은 Bastion 서버를 거쳐 접속해야 합니다.

### 1. 운영 스크립트 이용 (추천 ⭐)
`manage-script/ssh-login.sh`를 실행하면 `ssh-agent` 등록과 Bastion ProxyJump가 자동으로 수행됩니다:
```bash
./manage-script/ssh-login.sh
# 1. user: 엔터 (기본값 ec2-user)
# 2. ServerName: db (또는 web_01, monitor, internal_dns, bastion)
```

### 2. 수동 ProxyJump 명령어 이용
```bash
# 내 PC의 pem 키 하나로 Bastion을 거쳐 내부 서버(10.0.10.33)로 다이렉트 접속
ssh -i ~/terraform-key.pem -J ec2-user@<Bastion_Public_IP> ec2-user@10.0.10.33
```

---

## 🛠️ User Data 초기화 스크립트 설명

`modules/user_data/` 디렉토리에 위치한 `.tpl` 템플릿들은 EC2 인스턴스가 최초 부팅될 때 필요한 패키지와 설정을 자동으로 적용합니다.

* **`common.sh`**: Swap 메모리 구성, Node Exporter 설치, Promtail 로그 수집기 설정 등 공통 초기화 스크립트.
* **`bastion-server.tpl`**: 점프 호스트용 기본 패키지 및 사설 DNS 리졸버 설정.
* **`web-server.tpl`**: Nginx 웹 데몬 구동 및 로컬 웹 로그 수집.
* **`db-server.tpl`**: MariaDB/MySQL 자동 설치, 원격 접속 허용 및 초기 DB/유저 생성.
* **`monitor-server.tpl`**: Prometheus, Grafana, Loki 다운로드 및 systemd 서비스 등록.
* **`internal-dns-server.tpl`**: Bind9 사설 DNS 네임서버(`dev.internal`) 구성.
* **`vpn-server.tpl`**: WireGuard VPN 데몬 기동 및 VPC 내부 라우팅 설정.

---

## 🚀 시작하기 (How to Run)

### 1. 사전 준비 사항
* **AWS CLI** 설치 및 자격 증명 구성
* **Terraform CLI** (v1.2 이상 권장) 설치
* **S3 Bucket 생성**: 테라폼 상태 파일(`terraform.tfstate`) 저장용 원격 버킷

### 2. 환경 변수 파일 작성 (`dev.tfvars`)
```hcl
db_username  = "admin"
db_password  = "보안이_강력한_패스워드"
my_public_ip = "본인의_퍼블릭_IP_대역/32"
project      = "my-project"
```

### 3. 배포 명령어
```bash
# 초기화
terraform init

# 변경 계획 확인
terraform plan -var-file="dev.tfvars"

# 인프라 배포
terraform apply -var-file="dev.tfvars"
```

---

## 📜 변경 이력 및 문서 링크

* 📋 상세 패치노트 및 아키텍처 개선 과정: **[CHANGELOG.md](./CHANGELOG.md)**
* 🛠️ 운영 및 접속 스크립트 매뉴얼: **[manage-script/info.md](./manage-script/info.md)**
