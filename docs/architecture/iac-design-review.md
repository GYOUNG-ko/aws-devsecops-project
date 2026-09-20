# Architecture Proposal: IaC 설계 검토

검토일: 2026-09-17. 아래 최초 검토 기록은 보존한다. 사용자 후속 요청으로 일부 개선을 코드에 반영했으며 AWS 적용/State 이동은 하지 않았다. 최신 구현 범위는 문서 끝의 Implementation Update를 참조한다.
검토 대상: 최신 로컬 소스. GitHub는 업데이트되지 않았다는 사용자 설명에 따라 비교 기준으로 사용하지 않음.

## 판단
`terraform/modules`에 구현을 두고 `live`에 환경별 입력과 Terragrunt 실행 단위를 두는 구조는 유효하다. 현재 평가는 **실무 방식의 골격을 갖춘 단일 dev 환경 코드이며, 팀 운영을 위한 경계와 변경 절차는 미완성**이다.
10개 임시 module validate PASS는 module schema 검증이지 10개 Terragrunt unit 전체 dependency plan 성공이나 production readiness가 아니다.

## 유지할 부분
- VPC/EKS/DB/storage의 별도 State는 수명과 장애 영향 범위를 분리하는 데 적합함.
- root의 backend/provider 실행 설정 공통화와 module별 required_providers 분리는 적절함.
- dependency outputs를 입력으로 전달하는 기본 방향은 적절함.
- AWS 인프라 Terraform/Terragrunt, Kubernetes workload Argo CD 소유 방향 유지.
- 작은 ECR module이나 local module source 자체는 오류가 아님. 재사용 횟수나 파일 개수보다 계약/수명/검증 가치로 판단.

## Review Findings
모든 항목은 코드 정적 검토 결과다. IAC-001의 실행 오류 수정과 달리 아래 설계 변경은 미적용이다.

| ID | Status / Severity / Type | Component | Problem / Evidence | Root Cause / Impact | Recommended Fix | Changed Files / Validation / Re-validation |
| --- | --- | --- | --- | --- | --- | --- |
| ARCH-001 | OPEN / Medium / Operational Risk | Network ownership | vpc/main.tf는 VPC/subnet/IGW/route table을 data로 읽고 NAT/endpoint만 resource로 관리 | 기존 네트워크 참조와 전체 network 관리의 계약이 불분명. 이 저장소만으로 VPC 자체를 복구할 수 없음 | shared network를 외부 소유로 명시하고 IDs를 입력받거나, 관리 이관을 별도 import/migration 계획으로 제안 | 코드 변경 없음; data/resource inventory 확인; 실제 소유자 NOT VERIFIED |
| ARCH-002 | OPEN / Medium / Operational Risk | DB/EKS lifecycle | live/dev/rds/terragrunt.hcl에서 EKS node SG를 dependency로 읽고 DB module이 ingress rule까지 소유 | DB 유지보수 plan이 EKS state output 가용성에 결합. EKS 삭제가 DB 자동 삭제를 뜻하지는 않지만 독립 운영을 방해 | RDS 본체/DB SG는 data unit에 유지하고 EKS↔DB ingress를 별도 연결 unit으로 분리 검토; 한 ingress rule의 소유자는 반드시 하나 | 코드 변경 없음; dependency 코드 확인; EKS 제거/재생성 시 DB 독립 plan은 향후 검증 |
| ARCH-003 | OPEN / Medium / Operational Risk | Account identity | github-actions-ecr/main.tf가 계정의 GitHub OIDC provider와 특정 repository role을 함께 생성 | 계정 공용 identity를 앱별 module이 소유. 동일 계정에 두 번째 앱을 배치하면 중복 생성 충돌 가능 | OIDC provider는 account 공용 unit에서 한 번 관리하고 role module에는 ARN 입력. 기존 provider 소유 State 먼저 확인 | 코드 변경 없음; resource/trust 코드 확인; 다중 앱 시나리오 미실행 |
| ARCH-004 | OPEN / Medium / Operational Risk | IRSA boundary | irsa module에 aws-test/s3-reader와 PMS role이 동거; bucket은 root local 문자열로 전달 | 테스트와 서비스 IAM의 변경/폐기 수명 혼합. S3 배포와 IAM 권한 계약이 코드 dependency에 표현되지 않음 | 테스트 IAM과 PMS IAM 실행 단위 분리 검토. 관리 중인 storage output을 계약으로 연결하거나 독립 이름 계약의 이유/배포 gate 명시. 문자열 IAM ARN 자체는 AWS 오류가 아님 | 코드 변경 없음; unit inputs/outputs 확인; 분리 시 State 이동 별도 검토 |
| ARCH-005 | OPEN / Medium / Misconfiguration | Environment contract | EKS module tags에 dev/project 하드코딩; root에 PMS bucket/region/backend 상수; account guard 없음 | dev 복사 확장 시 잘못된 tags/account/region 대상 위험. dev 하나인 지금 폴더가 얕다는 것 자체는 결함 아님 | module은 tags/환경 입력, live는 환경 값 소유. provider allowed_account_ids 및 계정별 실행 role 검토. 실제 두 번째 계정/환경 도입 시 계층 확장 | 코드 변경 없음; 정적 확인; 다중 환경 검증 미실행 |
| ARCH-006 | OPEN / Medium / Operational Risk | Reproducibility | EKS external module ~>21.0; 명시적인 실행 도구 버전 정책 없음 | provider lock이 external module 버전까지 고정하지 않음. 새 init 시 선택 버전 변동 가능 | 검증한 EKS module 정확 버전 채택과 upgrade PR 절차; OpenTofu/Terragrunt 실행 버전 고정 및 required_version 기준 정의 | 코드 변경 없음; 공식 lock 문서와 코드 확인; 새 환경 재현성 검증 미실행 |
| ARCH-007 | OPEN / Medium / Operational Risk | IaC review pipeline | 현재 workflow는 PMS 앱 CI; atlantis.yaml/repos.yaml 모두 0 byte | 공통 module 변경의 영향 unit 탐지/plan 검토 절차가 저장소에 없음. Atlantis EC2만으로 자동화 완성 아님 | fmt/HCL/module validation → 영향 unit plan → 검토된 apply 흐름. shared module/root 변경도 트리거. 외부 운영 자동화 존재 여부는 미확인 | 코드 변경 없음; workflow/파일 크기 확인; Atlantis 미구현 PENDING |
| ARCH-008 | OPEN / Low / Improvement | Terraform↔GitOps contract | ServiceAccount/controller manifest/CI에 account ARN 및 이름 수동 반복 | 계정/이름 변경 후 IaC output과 manifest 불일치 가능 | output 기반 환경 values/overlay 변경을 PR로 생성하고 계약 검사. Argo 관리 리소스를 Terraform Helm/Kubernetes provider로 중복 관리하지 않음 | 코드 변경 없음; 문자열 대조; 자동 전달 미구현 |

## Provider 수정에 대한 재평가
이전 수정은 타당하다. `required_providers`는 module의 요구사항이고 provider block은 실행 환경의 region/auth 설정이다. Terragrunt가 source를 실행 작업 디렉터리로 가져오므로 generated provider.tf와 versions.tf가 같은 root module에 놓인다. 이 중복을 제거한 것은 오류 수정이다.

8개 module에 유사 versions.tf가 있다는 것만으로 나쁜 중복은 아니다. 각각 독립적으로 검증할 수 있는 계약이다. 다만 공용 library로 배포한다면 최소 호환 버전과 실행 unit의 버전 제한을 구분할 수 있다. 현재는 이 디렉터리들이 Terragrunt에서 직접 실행되는 역할도 하므로 ~>6.0 + unit별 lock이 합리적인 절충이다. 단순 파일 수 축소를 위한 재통합은 권하지 않는다.

## 제안 구조와 이유
당장 폴더 이동을 하지 않고 다음 소유 계약부터 정한다.

- Network: 기존 VPC의 외부 소유자, 참조 ID, NAT/endpoint 소유 범위 명시.
- Account identity: GitHub OIDC provider처럼 계정 공용 리소스.
- Cluster: EKS와 cluster 수명의 IAM.
- Application data: PMS S3, RDS. cluster보다 오래 유지 가능한 State.
- Application identity / connectivity: PMS IRSA 및 EKS↔DB 접근 연결. 작은 리소스라도 독립 수명 때문에 분리할 수 있음.
- GitOps: Kubernetes desired state. IaC output 전달은 검토 가능한 환경 설정 변경으로 연결.

두 번째 계정/리전 도입 시에만 `live/<account>/<region>/<env>/<unit>` 및 account/region/env 설정 파일을 고려한다. 단일 dev 상태에서 불필요한 platform/apps/component 계층이나 별도 module repository를 먼저 만들 필요는 없다. local source monorepo를 유지하되 공통 module 변경 시 모든 소비 unit 검증이 필요하다.

## Architecture Proposal 영향
- 현재 구조: 서비스/기술별 10 unit, root 공통 backend, data 조회 기반 network, 일부 공용/앱 리소스 혼재.
- 문제점: 소유권·수명 경계, 환경값, 재현성, 변경 검토의 부족.
- 제안 구조: 위 소유 계약에 따른 경계 조정. EKS/ALB/ArgoCD/GitHub Actions/ECR/별도 Atlantis EC2/NAT/TLS 방향 유지.
- 변경 이유: cluster 교체와 data 보존을 독립 운영하고 다중 앱/환경으로 확장할 때 충돌 방지.
- 장점: 책임과 rollback 범위가 명확하고 변경 영향 검증이 가능.
- 단점: 연결 unit/output 계약과 migration 절차가 늘어남. 과도한 state 분리는 plan/state 운영비를 증가시킴.
- 비용 영향: 제안 자체는 신규 AWS 서비스/상시 자원 불필요. CI 실행 및 엔지니어 유지보수 시간은 늘 수 있음. AWS 재생성 유발 변경은 허용하지 않음.
- 보안 영향: 계정 guard, 공용 IAM 소유 및 접근권한 review 개선. State가 분리되어도 backend IAM이 동일하면 접근권한 분리 효과는 없음.
- 운영 영향: 기존 state key 및 resource address 보존이 우선. `path_relative_to_include()` 때문에 폴더 이동은 backend key 변경을 유발할 수 있음. unit/module 분리는 plan만 보고 수행하지 말고 별도 migration 설계/승인/검증 필요.

## 우선순위와 검증 기준
1. 현재 경로/State 유지: ownership 문서, module의 dev 하드코딩 제거 계획, 버전 정책, 계정 guard, IaC CI 설계.
2. 다음 실제 변경에 맞춰: 공용 OIDC, 테스트/PMS IAM, DB↔EKS 연결 경계 조정 제안.
3. 다중 환경이 필요해질 때: account/region/env 계층 확장과 module release 전략.

각 제안은 수정 후 validate에 더해 모든 영향 unit의 기존 state 기반 plan에 예상하지 않은 destroy/replacement가 없어야 한다. 새 clone/init 재현, 잘못된 계정 차단, DB 단독 plan, GitOps ARN 계약 등을 시나리오로 검증한다.

## 공식 근거
- [Terraform provider requirements](https://developer.hashicorp.com/terraform/language/providers/requirements): module별 provider 요구사항과 provider 실행 설정 구분.
- [Terraform module composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition): 평평한 조합과 외부 dependency 입력.
- [Terraform dependency lock](https://developer.hashicorp.com/terraform/language/files/dependency-lock): provider lock과 remote module 버전 관리 구분.
- [Terragrunt blocks](https://docs.terragrunt.com/reference/hcl/blocks/): generate/remote_state/dependency 기반 구성.

위 문서는 기능/설계 원칙의 근거이며, 이 프로젝트의 경계와 우선순위 판단은 로컬 코드에 대한 검토자의 제안이다.


## Implementation Update — 2026-09-17

사용자 승인 범위: 실무 업무별 분류 및 수명/환경 확장 개선 수행.

- ARCH-002: RDS에서 EKS 의존성 제거, `eks-database-access`가 연결만 소유. mock plan으로 DB 독립성과 접근 범위 검증 완료.
- ARCH-003: 계정 공용 `live/shared/github-oidc` 추가, 앱 role은 provider ARN 소비. shared provider 생성/State 이관은 미실행.
- ARCH-004: test `irsa`와 서비스 `pms-irsa` 분리, PMS는 storage output 소비. 기존 역할 이름/권한 범위 유지.
- ARCH-005: account/region/dev 환경 설정 분리, module의 dev 태그 입력화, account guard 추가. 단일 dev 경로 유지.
- ARCH-006: 도구 실행 버전과 EKS module 버전 고정, lockfile readonly 검증. EKS 내부 transitive module의 범위 의존성까지 고정하는 것은 upstream 정책에 남아 있으므로 전체 공급망의 byte-for-byte 재현을 주장하지 않음.
- ARCH-007: credentials 없는 IaC CI, unit contract/DAG/State key 검사, PR/CODEOWNERS 및 업무 워크스페이스 추가. 실제 GitHub 실행/branch protection, Atlantis 서버 구현은 PENDING.
- ARCH-008: Terraform→GitOps는 문서화된 PR 전달 계약 유지, 자동화는 PENDING.
- ARCH-001: 신규 사실 — Windows legacy VPC State에 12개 관리 instance가 남음. State 소유권 정리는 IAC-003으로 추적하며 배포 preflight가 이를 차단.

AWS 서비스/Network topology 변경 없음. 신규 unit은 State 관리 단위이며 신규 상시 AWS 서비스를 도입하지 않는다. 비용 증가는 로컬/CI 검증 시간에 한정된다. 기존 AWS 이름/규칙 범위 유지가 의도이며 실제 apply 전 State 소유권 확인과 기존/신규 unit 양쪽 plan이 필요하다.

[업무 협업 절차](../operations/team-workflow.md), [State 및 분리 적용 절차](../operations/iac-maintenance.md)를 참조한다.
