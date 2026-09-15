# 🛠️ Manage Scripts (인프라 운영 및 관리 도구)

이 디렉토리는 Terraform으로 배포된 AWS 인프라를 효율적으로 운영, 접속 및 정리하기 위한 유틸리티 스크립트 모음입니다.

---

## 📂 디렉터리 구조

```text
manage-script/
├── aws-env.sh         # [로컬 전용] AWS 인증 자격 증명 환경 변수 (Git 커밋 금지)
├── destroy.sh         # 의존성 꼬임 방지 및 안전한 인프라 일괄 삭제 스크립트
├── ssh-login.sh       # Bastion ProxyJump 기반 원클릭 SSH 자동 접속 스크립트
└── info.md            # 스크립트 사용 가이드 및 매뉴얼
```

---

## 📜 스크립트 상세 설명

### 1. `aws-env.sh` (AWS 자격 증명 설정)
* **용도**: 로컬 터미널에서 AWS CLI 및 Terraform 작업을 수행하기 위한 환경 변수를 설정합니다.
* **보안 주의**: 개인 Access Key와 Secret Key가 포함되므로 `.gitignore`에 등록되어 Git에 업로드되지 않습니다.
```bash
export AWS_ACCESS_KEY_ID="본인의_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="본인의_SECRET_KEY"
export AWS_DEFAULT_REGION="ap-northeast-3"
```

---

### 2. `destroy.sh` (안전한 인프라 정리 스크립트)
* **용도**: Lambda의 VPC ENI 해제 지연이나 리소스 간 의존성 문제로 인해 `terraform destroy`가 멈추거나 실패하는 현상을 방지합니다.
* **주요 동작**:
  1. 의존성이 높은 Lambda 및 EC2 리소스 선별적 우선 해제/삭제
  2. 잔여 보안 그룹 및 서브넷/VPC 자원의 순차적 클린업

---

### 3. `ssh-login.sh` (SSH 원클릭 접속 스크립트)
* **용도**: Public IP가 없는 프라이빗 서브넷(DB, Monitoring, DNS 등)의 EC2 인스턴스에 Bastion 서버를 거쳐 원클릭으로 접속합니다.
* **주요 기능**:
  * **자동 `ssh-agent` 활성화 및 키 등록**: `~/terraform-key.pem` 키를 메모리에 자동으로 로드하여 Bastion 서버에 개인키를 업로드하지 않고도 안전하게 접속(SSH Agent Forwarding)합니다.
  * **자동 IP 조회**: `terraform output`에서 Bastion 공인 IP와 각 대상 서버의 사설 IP(`ec2-pri-ip`)를 자동으로 파싱합니다.
  * **ProxyJump (`-J`) 지원**: 대상 서버 이름을 입력하면 Bastion을 징검다리 삼아 다이렉트로 접속합니다.

#### 💡 사용 방법
```bash
./manage-script/ssh-login.sh
```
1. `user (기본값: ec2-user)`: 엔터를 치면 기본 `ec2-user`로 자동 선택됩니다.
2. `ServerName`: 접속할 서버 이름을 입력합니다.
   * `bastion`: Bastion 공인 IP로 직접 접속
   * `web_01`, `web_03`, `db`, `monitor`, `internal_dns`, `vpn`: Bastion을 거쳐 해당 서버의 프라이빗 IP로 터널링 접속