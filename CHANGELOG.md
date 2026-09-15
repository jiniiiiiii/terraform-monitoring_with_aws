# 📜 Changelog (인프라 변경 & 아키텍처 개선 이력)

이 문서는 프로젝트의 아키텍처 변화, 테라폼 모듈 구조 개편, 장애/성능 이슈 해결 과정(Troubleshooting) 및 주요 변경 사항을 기록하는 체인지로그입니다.

---

## 📌 [2026-09-15] - Bastion 점프 호스트 구축, 2계층 서브넷 분리(Service/Manage) 및 모니터링 보안 강화

### 🎯 변경 목적 및 배경
1. **내부 서버 보안 격리**: DB, Monitoring(Grafana/Prometheus/Loki), Internal DNS 서버를 프라이빗 서브넷으로 완전 격리하고 Public IP 할당을 차단하여 외부 직접 공격 표면을 원천 차단.
2. **Bastion Host (Jump Box) 도입**: 프라이빗 자원에 대한 안전한 중앙 집중식 관리 및 SSH 접근 경로 단일화.
3. **보안 그룹 순환 참조(Cycle Dependency) 해소**: `bastion_sg`와 `monitor_sg` 간의 상호 참조로 인한 테라폼 빌드 오류 해결.
4. **운영 자동화 도구 고도화**: ProxyJump 및 ssh-agent 기반의 원클릭 서버 접속 유틸리티(`ssh-login.sh`) 구축.

---

### 📝 상세 변경 내역 (Keep a Changelog)

#### Added (신규 추가)
* **Bastion EC2 및 보안 그룹 구축**:
  * `main.tf`: `module.ec2_bastion` 추가 (`t3.micro`, 퍼블릭 관리 서브넷 `10.0.2.22` 할당)
  * `modules/user_data/bastion-server.tpl`: Bastion 기본 환경 설정 및 DNS 리졸버 설정 템플릿 생성
  * `sg.tf`: `aws_security_group.bastion_sg` 생성 (내 공인 IP로부터 22번 SSH 허용)
* **서브넷 모듈 출력 확장**:
  * `modules/subnet/outputs.tf`: `output "cidr_block"` 및 `output "cidr_blocks"` 추가로 보안그룹에서 서브넷 대역 동적 참조 지원
* **운영 및 접속 스크립트 고도화**:
  * `manage-script/ssh-login.sh` / `script/ssh-login.sh`: Bastion 공인 IP 및 대상 서버 사설 IP 자동 추출, `ssh-agent` 자동 활성화, ProxyJump(`-J`) 분기 접속 로직 구현
  * `manage-script/info.md`: 관리 스크립트 상세 설명 및 매뉴얼 작성

#### Changed (변경)
* **인프라 계층 구조 재배치 (Service Layer / Manage Layer)**:
  * **Service Layer**:
    * Public Subnet (`10.0.1.0/25`, `10.0.1.128/25`): ALB, `ec2_web_01` (`10.0.1.10`), `ec2_web_03` (`10.0.1.150`)
    * Private Subnet (`10.0.10.0/24`): `ec2_db` (`10.0.10.33`)
  * **Manage Layer**:
    * Public Subnet (`10.0.2.0/24`): `ec2_vpn_wireguard`, `ec2_bastion` (`10.0.2.22`)
    * Private Subnet (`10.0.20.0/24`): `ec2_mornitoring` (`10.0.20.100`), `ec2_internal_dns` (`10.0.20.53`)
* **Public IP 할당 비활성화**:
  * 내부 서버(`ec2_web_01`, `ec2_web_03`, `ec2_db`, `ec2_mornitoring`, `ec2_internal_dns`)의 `pub_ip_associate_bool`을 `false`로 설정하여 사설망 전용으로 전환
* **`output.tf` 갱신**:
  * `ec2-pub-ip`: Bastion 공인 IP 출력
  * `ec2-pri-ip` [신규]: 전체 서버들의 내부 통신용 사설 IP 일괄 출력 매핑 추가

#### Fixed (문제 해결 & 기술적 개선)
1. **`Cycle: aws_security_group.monitor_sg, aws_security_group.bastion_sg` 오류 해결**:
   * 모니터링 수집 포트(9100)의 인바운드 대역을 `security_groups = [aws_security_group.monitor_sg.id]`에서 **`cidr_blocks = [ module.subnet_pri_manage_a_2.cidr_block ]` (프라이빗 관리 서브넷)**으로 변경하여 순환 종속성을 해소하고 보안 최소 권한 원칙 충족.
2. **보안 그룹 내 리소스 ID 참조 오타 수정**:
   * `security_groups = [ aws_security_group.bastion_sg ]` 형태의 누락된 `.id` 속성을 `[ aws_security_group.bastion_sg.id ]`로 일괄 수정.

---

## 📌 [2026-09-14] - 서브넷 모듈화, 게이트웨이 분리 및 의존성 최적화

### 🎯 변경 목적 및 배경
* **기존 문제점**:
  1. 서브넷이 `modules/vpc/network.tf`에 하드코딩되어 있어 서브넷 하나를 추가/변경할 때마다 VPC 모듈 내부 코드, 변수, 라우팅 파일을 모두 뜯어고쳐야 하는 비효율 발생.
  2. `modules/vpc` 내부에 VPC, 서브넷, IGW, NAT GW, 라우팅이 강하게 결합되어 있어, 테라폼 삭제(`destroy`) 시 Lambda의 VPC ENI 해제 대기로 인해 전체 인프라 삭제가 10분 이상 지연되는 병목 현상 발생.
  3. RDS 서브넷 그룹 생성 시 Multi-AZ(최소 2개 AZ) 요건 미충족 에러 발생.

---

### 🏗️ 아키텍처 & 테라폼 프로젝트 구조 변경

#### 1. 테라폼 모듈 구조 개편 (Before vs After)

```text
[Before: 거대 단일 VPC 모듈]
Dev/
├── modules/
│   └── vpc/               # VPC + 서브넷 하드코딩 + IGW/NAT + 라우팅 연결이 한 통으로 결합
└── main.tf                # EC2만 모듈화되어 호출

[After: 껍데기 템플릿 기반 모듈 분리]
Dev/
├── modules/
│   ├── vpc/               # 순수 VPC 및 라우팅 테이블 껍데기만 유지
│   ├── subnet/            # [신규] EC2처럼 CIDR/AZ/이름을 넘겨받아 생성하는 서브넷 템플릿
│   └── ec2/               # EC2 인스턴스 공통 모듈
├── gw.tf                  # [신규] IGW, NAT GW, EIP, 기본 라우트(0.0.0.0/0)를 루트로 독립
├── main.tf                # 서브넷들을 EC2처럼 동적으로 선언 및 개별 리소스 연결
├── rds.tf                 # Multi-AZ 서브넷 그룹 구성
└── lambda.tf              # 개별 프라이빗 서브넷 모듈 직접 참조
```

---

### 📝 상세 변경 내역 (Keep a Changelog)

#### Added (신규 추가)
- **`modules/subnet` 모듈 생성**:
  - `subnet.tf`: `aws_subnet` 리소스 및 라우팅 테이블 연결(`aws_route_table_association`) 껍데기 템플릿 정의
  - `variables.tf`, `outputs.tf`: `subnet_id` 출력값 및 입력 변수 정의
- **`gw.tf` 신규 분리**:
  - `aws_internet_gateway` (IGW) 및 퍼블릭 기본 라우트(`0.0.0.0/0`)
  - `aws_nat_gateway` (NGW), `aws_eip` 및 프라이빗 기본 라우트(`0.0.0.0/0`)
- **Multi-AZ 대응 서브넷 추가**:
  - `module.subnet_pri_service_c_1` (`10.0.11.0/24`, `ap-northeast-3c`) 추가

#### Changed (변경)
- **서브넷 선언 방식 전환**:
  - `main.tf`에서 `module.subnet_pub_service_a_1`, `module.subnet_pub_service_c_1`, `module.subnet_pub_manage_a_2`, `module.subnet_pri_service_a_1`, `module.subnet_pri_service_c_1`, `module.subnet_pri_manage_a_2`를 직접 명시적으로 선언하도록 변경
- **리소스 간 서브넷 참조 방식 갱신**:
  - EC2 (`ec2_web`, `ec2_web_03`, `ec2_mornitoring`, `ec2_internal_dns`, `ec2_vpn_wireguard`, `ec2_db`): `module.subnet_xxx.subnet_id` 직접 참조
  - ALB (`alb.tf`): `subnets = [module.subnet_pub_service_a_1.subnet_id, module.subnet_pub_service_c_1.subnet_id]`
  - RDS (`rds.tf`): `subnet_ids = [module.subnet_pri_service_a_1.subnet_id, module.subnet_pri_service_c_1.subnet_id]` (Multi-AZ)
  - Lambda (`lambda.tf`): `subnet_ids = [module.subnet_pri_service_a_1.subnet_id, module.subnet_pri_service_c_1.subnet_id]`
- **`modules/vpc` 경량화**:
  - `network.tf` 및 `routing.tf`에서 하드코딩된 서브넷 및 association 제거

#### Fixed (문제 해결 & 기술적 개선)
1. **모듈 순환 참조(Cycle Dependency) 방지**:
   - NAT Gateway와 IGW를 `gw.tf`로 분리하여 `VPC 모듈 ↔ 서브넷 모듈` 간의 상호 의존성 사이클 완전 차단.
2. **테라폼 Destroy(삭제) 속도 대폭 개선**:
   - 거대 모듈의 의존성 결합을 느슨하게 풀어냄으로써, Lambda VPC ENI 해제 대기 중에도 다른 서브넷/EC2/라우팅 자원들이 병렬로 즉시 삭제되어 전체 삭제 소요 시간 10분 이상 단축.
3. **`DBSubnetGroupDoesNotCoverEnoughAZs` 에러 해결**:
   - 프라이빗 서브넷을 `ap-northeast-3a`와 `ap-northeast-3c`로 다중화하여 AWS RDS 요구 조건 충족.

---

## 📌 [2026-09-08] - 인프라 비용 최적화 & 구조 개편

### 🎯 변경 목적 및 배경
* Managed AWS RDS MySQL 8.0(`db.t3.micro`)의 24시간 상시 가동에 따른 클라우드 비용을 절감하기 위해 셀프호스팅 EC2 MySQL로 아키텍처 전환.

### 📝 상세 변경 내역

#### Added
- `modules/user_data/db-server.tpl`: MariaDB/MySQL 자동 설치, `bind-address = 0.0.0.0`, 유저 및 DB 자동 생성 부트스트랩 스크립트
- `sg.tf`: `aws_security_group.db_sg` 추가 (3306 MySQL, 22 SSH, 9100 Node Exporter)
- `promtail_db_config.sh`: EC2 DB 서버의 SSH, 시스템 및 DB 에러 로그를 Loki로 수집

#### Changed
- **Database 계층 전환**:
  - AWS RDS 인스턴스 코드를 주석 보관 처리하고, `main.tf`에 `module "ec2_db"` (`t3.micro`, IP `10.0.2.33`) 추가
- **Lambda Backend & SSM 파라미터 연결 대상 갱신**:
  - Lambda `DB_HOST` 환경 변수를 RDS 엔드포인트에서 `module.ec2_db.private_ip` (`10.0.2.33`)로 전환
- **내부 사설 DNS (`internal-dns-server.tpl`) 갱신**:
  - `db01.dev.internal` (`10.0.2.33`) 및 `bastion01.dev.internal` (`10.0.1.22`) 정방향/역방향(PTR) 레코드 등록
