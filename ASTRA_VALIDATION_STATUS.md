# ASTRA Validation Status

> 최신 상태 (2026-09-17): 업무별 작업 환경 및 module 수명 분리 코드 구현 완료. 13개 unit validate, mock plan 5개, State guard 테스트 5개 PASS. 실제 배포는 IAC-003 legacy VPC State 소유권과 IAC-002 bucket 복구 의도 확인 전 BLOCKED. 상세는 문서 끝 Maintenance Architecture Implementation Result를 기준으로 읽는다. 아래 이전 계획과 결과는 이력으로 보존한다.


## Project
AWS DevSecOps / PMS on EKS

## Last Updated
2026-09-17 (Asia/Seoul)

## Current Phase
1. Repository / Documentation

## Current Status
진행 중. Git 기준선 BLOCKED, 실제 AWS NOT VERIFIED.

## Validation Plan
Target: Repository, README, Architecture, Git 기준선.

Purpose: 과거 검증 기록과 현재 준비 코드를 구분하고 후속 검증 기준선을 확보한다.

Validation Method: 문서와 HCL/manifest 비교, 상대 링크 검사, Kustomize 렌더링, Git 상태 확인.

Command: `rg --files --hidden`, `cat`, `git status --short`, `command -v`, `kubectl kustomize kubernetes/app`, Python 상대 링크 검사.

Expected Result: 문서/코드 일치, 유효한 경로와 manifest, 조회 가능한 Git 기준선.

Failure Condition: 과거 결과를 현재 상태로 서술, 코드/문서 불일치, 누락 경로, Git metadata 부재.

## Validation Progress
1단계 진행 중. 2–14단계 PENDING.

## Completed Validations
초기 구조 및 문서 확인.

## Current Findings
- REPO-001: Git metadata 부재.
- DOC-001: 과거 nginx 기록과 현재 PMS 코드 혼재.

## Resolved Findings
없음.

## Changed Files
- ASTRA_VALIDATION_GUIDE.md: 사용자 프롬프트 원문으로 최초 생성.
- ASTRA_VALIDATION_STATUS.md: 계획과 진행 기록 최초 생성.

## Commands Executed
- `git status --short`: exit 128, not a git repository.
- `rg --files`, `cat`, `command -v`: 구조, 문서, 도구 확인.

## Validation Results
Git 및 AWS 기준선 NOT VERIFIED.

## Remaining Issues
문서 정합성 수정 및 재검증.

## Blocked Items
Git checkout 경로 부재.

## Next Action
최소 문서 수정 후 링크/Kustomize 회귀 검증 및 상태 기록.

---

# Phase 1 Result (2026-09-17)
이하 종료 기록이 위 초기 계획의 진행 상태를 갱신한다. 초기 기록은 보존한다.

## Current Phase
1. Repository / Documentation — 로컬 문서 검증 완료, Git 기준선 확보 대기.

## Current Status
BLOCKED (REPO-001). 전체 Validation 완료 아님.

## Validation Progress
| Phase | Status | Evidence / 범위 |
| --- | --- | --- |
| 1 Repository / Documentation | BLOCKED | 로컬 정합성 재검증 PASS, Git 이력/변경 비교 불가 |
| 2 Terraform / OpenTofu / Terragrunt | PENDING | validate/plan 미실행 |
| 3 VPC / Networking | PENDING | 코드 존재, AWS 미조회 |
| 4 IAM / IRSA | PENDING | 코드 존재, AWS 미조회 |
| 5 EKS | PENDING | 코드 존재, 클러스터 미조회 |
| 6 Kubernetes | PENDING | 로컬 렌더링만 PASS |
| 7 ALB / Ingress | PENDING | HTTP Ingress 코드 존재, 실제 흐름 미검증 |
| 8 ECR / GitHub Actions | PENDING | workflow/IAM/ECR 코드 존재 |
| 9 Argo CD / GitOps | PENDING | Application 존재, 과거 기록 재검증 안 함 |
| 10 Observability | PENDING | health probe 코드 존재, metrics/logs/alerts 운영 미검증 |
| 11 Security | PENDING | 권한/인증/TLS 후속 검증 필요 |
| 12 HA / Failure Recovery | PENDING | replicas/PDB 코드 존재, 장애 시험 미실행 |
| 13 Cost | PENDING | 비용 정책 문서만 확인 |
| 14 Documentation Consistency | PENDING | 전체 runtime 검증 후 최종 대조 필요 |

## Implemented / Pending Inventory
- 코드 존재: VPC, EKS, IRSA, PMS S3, ECR, GitHub OIDC, ALB controller IRSA, RDS, External Secrets, Atlantis EC2 모듈 및 10개 Terragrunt unit.
- 애플리케이션: Spring Boot backend, 정적 UI, PMS Deployment/Service/Ingress 및 Argo CD Application.
- Atlantis: 별도 private EC2 정의가 존재한다. 해당 모듈에 Public ALB 정의는 확인되지 않아 목표 아키텍처 구현 완료로 판단하지 않는다.
- TLS ACM/Route53, 중앙 관측성, 실제 장애 복구 시험: PENDING. 미구현 항목을 FAIL로 처리하지 않는다.
- NAT false는 코드의 입력값이다. EKS의 생성/삭제 여부, NAT 실제 존재 여부, 과거 import의 성공과 plan 수렴 여부는 NOT VERIFIED.

## Current Findings
### REPO-001
- Status: BLOCKED
- Severity: Medium
- Type: Operational Risk
- Component: Repository baseline
- Problem: 현재 폴더에서 Git branch, revision, 기존 변경 및 diff를 확인할 수 없다.
- Evidence: `git status --short` exit 128, `not a git repository (or any of the parent directories): .git`; 폴더 목록에 `.git` 없음.
- Root Cause: 이 작업 경로에서 Git metadata를 찾을 수 없음. 복사/동기화 원인은 미확인.
- Impact: 기존 변경 보존 여부를 Git 기준으로 비교하거나 GitOps 원본과의 일치를 증명할 수 없다.
- Recommended Fix: 실제 Git checkout 경로를 제공하고 해당 경로의 지침/status/diff부터 확인한다. 임의 git init/clone/commit/push는 하지 않는다.
- Changed Files: 없음 (상태 기록 제외).
- Validation Method: 올바른 checkout에서 `git status --short`, `git diff --stat`, `git log -5 --oneline`.
- Re-validation Result: BLOCKED — 현재 경로에서는 기준선 확보 불가. 외부 정보 필요에 따른 차단이며 3회 수정 실패가 아님.

## Resolved Findings
### DOC-001
- Status: RESOLVED (local documentation only)
- Severity: Medium
- Type: Documentation Issue
- Component: README / architecture records
- Problem: README가 PMS ServiceAccount를 아직 연결하지 않았다고 서술하고, 과거 nginx 실습 결과와 현재 PMS 준비 코드/실제 상태의 구분이 불명확함.
- Evidence: `kubernetes/app/deployment.yaml`은 `pms-backend`, `replicas: 2`, `serviceAccountName: pms-backend`; README는 current nginx와 미연결을 서술. NAT false 입력은 있으나 EKS 실제 상태의 증거는 없음.
- Root Cause: PMS 전환 후 과거 설명 일부가 남음.
- Impact: 과거 검증을 현재 배포 성공으로 오해하거나 활성화 전제를 잘못 판단할 수 있음.
- Recommended Fix: 현재 코드 참조로 설명을 수정하고 기존 nginx 결과에는 과거 기록임을 명시한다.
- Changed Files: README.md, docs/architecture/argocd-gitops.md, docs/architecture/eks-application-migration.md.
- Validation Method: README/manifest 대조, 상대 링크 검사, Kustomize 렌더링.
- Re-validation Result: PASS — 상대 링크 10개 유효, 리소스 8개 렌더링, PMS SA/replicas 참조 일치. 과거 기록 삭제 없음. Live 검증을 의미하지 않음.

## Completed Validations
- 폴더 구조, 기존 architecture/activation/cost 문서 및 핵심 설정 inventory 확인.
- 적용 가능한 상위 AGENTS.md 및 프로젝트 내 AGENTS.md를 찾지 못함.
- GUIDE/STATUS 부재 확인 후 초기 생성. GUIDE는 사용자 제공 프롬프트 원문 그대로 보존.
- DOC-001 최소 수정, 재검증 및 관련 로컬 manifest 회귀 확인 완료.

## Changed Files
1. ASTRA_VALIDATION_GUIDE.md — 신규 검증 규칙.
2. ASTRA_VALIDATION_STATUS.md — 신규 계획/증거/후속 작업.
3. README.md — SA 연결 및 실제 상태 구분, 과거 GitOps 기록 표시.
4. docs/architecture/argocd-gitops.md — 과거 실습 기록 표시 및 현재 절차 링크.
5. docs/architecture/eks-application-migration.md — 과거 실습 기록 표시 및 현재 절차 링크.
이 목록은 이번 세션의 쓰기 작업 기록이며 Git diff로 산출한 전체 변경 목록이 아니다.

## Commands Executed
| Command | Result | Important Output | Interpretation |
| --- | --- | --- | --- |
| `rg --files --hidden` 및 대상 파일 `cat` | PASS | HCL/modules/manifests/docs/workflow 존재 | 로컬 inventory만 확인 |
| `git status --short` | BLOCKED | exit 128, not a git repository | Git 기준선 없음 |
| `command -v terraform tofu terragrunt aws kubectl python3` | PASS (inventory) | tofu/terragrunt/aws/kubectl/python3 확인, terraform 미발견 | 설치 여부만 확인, 버전/인증 미검증 |
| `kubectl kustomize kubernetes/app` | PASS | exit 0, 8 resources | API 서버 호출 없는 manifest 생성 |
| Python relative link / manifest assertions | PASS | 10 links, missing=[], SA/replicas 일치 | 문서 변경의 로컬 회귀 확인 |
| 최초 Python Downloads glob | 중단 | 디렉터리 조회 지연, Ctrl-C | 알려진 정확한 파일 경로로 cp하여 복구 |
| 최초 문서 수정 Python | FAIL 후 복구 | stdin encoding SyntaxError | 쓰기 전 실패, encoding 선언 후 재실행 PASS |
전체 stdout, Secret, Terraform state 원문은 기록하지 않는다.

## Validation Results
- 문서 변경과 로컬 manifest 회귀: PASS.
- Git 이력/사용자 변경 비교: BLOCKED.
- Terraform/OpenTofu validate, plan, state 및 AWS 비교: NOT VERIFIED (미실행).
- 실제 DNS/TLS/ALB/Pod/S3/DB 트래픽, CI 실행 결과, drift/replacement/destroy: NOT VERIFIED.
- apply, state 변경, AWS/Kubernetes mutation, commit/push 미실행.

## Remaining Issues
- 후속 단계에서 코드 ↔ State ↔ AWS 증거 비교 필요.
- HTTP Ingress 및 Basic Auth의 노출 위험은 Security/ALB 단계에서 검증 필요. 배포 승인을 의미하지 않는다.
- Atlantis Public ALB/TLS 등 목표 구조의 미구현 범위를 추가 확인해야 함.
- 아키텍처 변경 제안은 이번 단계에서 작성하지 않음. 현재 구조 유지.

## Blocked Items
REPO-001: 실제 checkout 경로 또는 이 소스 사본을 검증 기준으로 사용하겠다는 사용자 판단 필요. 인증 부재로 단정하지 않으며 AWS 로그인/API는 이번 단계에서 검사하지 않았다.

## Next Action
1. 실제 Git 저장소 경로를 확인하여 해당 경로의 GUIDE/STATUS/AGENTS와 Git 변경 상태를 읽고 기존 작업과 이번 문서 수정을 대조한다.
2. Phase 2 계획을 먼저 작성한다. backend/dependency의 자동 초기화 동작을 확인하고 원격 리소스 생성/변경이 없는 방식으로 validate를 준비한다.
3. 읽기 전용 caller identity/region 및 backend 접근을 확인하고, import 대상/기존 bucket 확인 후 승인된 범위의 plan을 검토한다. State 원문/Secret은 출력하지 않는다.
4. VPC → IAM/IRSA → EKS 순서로 진행하며 phase별 증거와 status를 갱신한다. 환경 변경은 사용자 별도 실행 단계로 남긴다.

# Phase 2 Start (2026-09-17)
사용자 확인: GitHub 원본은 https://github.com/GYOUNG-ko/aws-devsecops-project 이며 업데이트되지 않았다. 현재 로컬 소스를 검증 대상으로 사용하고 원격으로 덮어쓰지 않는다.

## Current Phase
2. Terraform / OpenTofu / Terragrunt

## Current Status
진행 중. REPO-001은 WARNING으로 전환: 로컬 검증 진행을 차단하지 않으며 Git 이력 비교는 NOT VERIFIED로 유지한다.

## Validation Plan
Target: 10개 IaC module/unit, provider lock, backend 접근 전제.

Purpose: 구성 유효성과 검증 실행 가능성을 확인하고 코드/State/AWS 대조를 준비한다.

Validation Method: 도구 버전/CLI 도움말, 포맷 검사, 캐시 존재 확인, 읽기 전용 AWS caller identity 조회. Backend를 초기화하거나 리소스를 생성하지 않는다. Provider/module이 준비된 경우 validate를 수행한다.

Command: `tofu fmt -check -recursive terraform`, `terragrunt hcl validate --help`, `aws sts get-caller-identity --region ap-northeast-2`, module/cache inventory, `tofu validate`.

Expected Result: 유효한 HCL과 준비된 provider/module, 의도한 계정의 읽기 전용 접근.

Failure Condition: 구문/스키마 오류, dependency/provider 미준비, 인증/네트워크 오류, 다른 계정 접근.

## IAC-001 — 발견 및 수정 계획
- Status: FAIL
- Severity: High
- Type: Bug
- Component: live/root.hcl + rds-postgres/github-actions-ecr required_providers
- Problem: 공통 generated provider.tf와 두 모듈의 versions.tf가 required_providers를 중복 정의함.
- Evidence: 원본 RDS module과 generated provider 동일 내용을 임시 폴더에 조합한 `tofu validate`가 `Duplicate required providers configuration`으로 실패.
- Root Cause: provider 실행 설정과 module별 provider 요구사항의 소유 위치가 혼재함.
- Impact: 해당 Terragrunt unit의 init/validate/plan을 막음.
- Recommended Fix: root.hcl은 AWS provider 지역 설정만 생성하고, 각 module은 versions.tf에서 자체 provider 요구사항을 선언함. 기존 AWS ~>6.0 및 lock 유지.
- Changed Files (planned): live/root.hcl 및 versions.tf가 없는 8개 module의 신규 versions.tf.
- Validation Method: generated 구성 재조합, backend=false/lockfile=readonly init, validate; 다른 module 회귀 검증, HCL 및 fmt 검사.
- Re-validation Result: 진행 중.

AWS identity: 사용자 확인한 dev profile / <SSO_USER> SSO로 코드의 계정 123456789012 일치 확인. 기본 profile 미설정은 인증 실패로 취급하지 않는다.

## Phase 2 Plan Review Extension
Target: 선행 dependency인 VPC의 code/state/AWS 비교.

Purpose: 현재 NAT false/S3 endpoint true의 실제 수렴, drift/replacement/destroy 여부 확인.

Validation Method: 임시 VPC 사본에 코드와 같은 S3 backend 및 입력을 구성. backend init은 기존 bucket만 참조하며 Terragrunt bootstrap을 사용하지 않음. `plan -lock=false`로 S3 lock 생성도 하지 않음. 동시 apply가 없는 시점의 읽기 전용 관찰이며 추후 apply용 plan으로 사용하지 않음.

Command: `aws s3api list-objects-v2` (key/timestamp만), `tofu init -reconfigure -lockfile=readonly`, `tofu plan -lock=false -input=false -detailed-exitcode`.

Expected Result: 계획 성공 및 변경 여부가 명시됨.

Failure Condition: 참조 리소스 부재, 예기치 않은 destroy/replacement, backend/인증 실패. State 원문이나 Secret 값을 출력하지 않음.

## Phase 2 Storage Plan Extension
Target: PMS storage code/state/AWS.
Purpose: 기존 state key는 존재하나 `get-bucket-location pms-patch`가 NoSuchBucket을 반환하므로 실제 bucket 부재와 state drift를 확인.
Validation Method: 임시 pms-storage 사본에서 기존 backend와 원본 입력으로 읽기 전용 plan, lock=false. 다른 bucket 이름/정책을 추측하거나 import하지 않음.
Command: S3 location 조회, `tofu init -reconfigure -lockfile=readonly`, `tofu plan -lock=false -input=false -detailed-exitcode`.
Expected Result: state와 실제 bucket 상태 차이가 plan에 명시됨.
Failure Condition: 예상하지 않은 삭제/교체, 다른 bucket 대상 또는 접근 오류.

# Phase 2 Result (2026-09-17)
이 기록이 이전 Current Phase/Status/Next Action을 갱신한다.

## Current Phase
2. Terraform / OpenTofu / Terragrunt

## Current Status
BLOCKED — IAC-002 삭제 drift의 의도/데이터 복구 필요 여부 확인 필요. 전체 완료 아님.

## Validation Progress / Completed Validations
- Phase 1: WARNING (로컬 사본을 기준으로 진행; Git 비교 미검증).
- Phase 2: 10개 module validate PASS, Terragrunt HCL PASS, VPC/PMS plan 검토 완료; 나머지 unit의 실제 dependency/state 기반 plan은 PENDING.
- Phase 3–14: PENDING. 이번 VPC/AWS 조회는 Phase 2의 선행 증거이며 전체 Network 검증 완료가 아님.
- OpenTofu 1.12.6, Terragrunt 1.1.4, AWS CLI 2.36.41.
- 10개 local source/dependency 경로 모두 존재.
- 모든 module을 임시 사본으로 구성하고 원본 lockfile을 readonly로 사용, backend=false init 및 validate 완료.
- Module 목록: alb-controller, atlantis, ecr, eks, external-secrets, github-actions-ecr, irsa, pms-storage, rds, vpc.
- EKS 외부 module은 코드의 ~>21.0 범위로 resolve됨. 기존 배포 당시 동일 module 버전이었다는 증거는 없음.

## Resolved Findings Update — IAC-001
- Status: RESOLVED
- Root Cause/Evidence: 앞선 IAC-001 재현 기록 참조.
- Fix: root.hcl의 중복 terraform/required_providers 생성 제거. 8개 module에 versions.tf 추가. 기존 rds-postgres/github-actions-ecr versions.tf는 유지.
- Re-validation Result: 10/10 validate PASS. root의 required_providers 없음, 각 module에 required_providers 정확히 1개인 회귀 검사 PASS. tofu fmt 및 terragrunt hcl validate PASS.
- Impact: provider source/constraint, AWS region, resource 정의, lock version 유지. 원격 apply 없음.

## Current Findings — IAC-002
- Status: BLOCKED
- Severity: High
- Type: Operational Risk
- Component: PMS S3 remote state / actual bucket
- Problem: 원격 State가 관리하던 pms-patch bucket이 실제 AWS에는 존재하지 않음.
- Evidence: `get-bucket-location` NoSuchBucket; refreshed plan이 `aws_s3_bucket.patches has been deleted`를 보고. Plan 5 add / 0 change / 0 destroy.
- Root Cause: State 마지막 반영 이후 AWS bucket이 삭제된 drift. 누가 언제 왜 삭제했는지와 데이터 존재/손실 여부는 NOT VERIFIED.
- Impact: 현재 bucket 기반 다운로드는 제공할 수 없음. 재생성만으로 기존 객체 데이터가 복구되지 않음. 의도된 실습 정리인지 확인 필요.
- Recommended Fix: 삭제 의도 및 보관 데이터/백업 여부 확인 후 재활성화 시점을 결정. 의도된 중지라면 PENDING으로 분류; 비의도 삭제라면 데이터 복구 계획부터 마련. 자동 재생성/import/state 수정 금지.
- Changed Files: 코드 변경 없음 (STATUS만 기록).
- Validation Method: 사용자 의도 확인 후 별도 실행 단계에서 승인된 복구; bucket/객체 및 plan 수렴 재검증.
- Re-validation Result: 읽기 전용 AWS 조회와 plan 일치. 미해결.

## REPO-001 Update
Status: WARNING. 사용자 제공 원격 저장소는 오래된 상태이므로 현재 로컬 소스로 검증을 계속한다. Git 이력/remote diff는 NOT VERIFIED. Git clone/init/commit/push 없음.

## Changed Files (이번 Phase)
- ASTRA_VALIDATION_STATUS.md
- live/root.hcl
- terraform/modules/alb-controller/versions.tf (new)
- terraform/modules/atlantis/versions.tf (new)
- terraform/modules/ecr/versions.tf (new)
- terraform/modules/eks/versions.tf (new)
- terraform/modules/external-secrets/versions.tf (new)
- terraform/modules/irsa/versions.tf (new)
- terraform/modules/pms-storage/versions.tf (new)
- terraform/modules/vpc/versions.tf (new)
이전 Phase의 문서 변경 목록은 보존한다. GUIDE 추가 수정 없음.

## Commands Executed / Validation Results
| Command | Result | Important Output | Interpretation |
| --- | --- | --- | --- |
| `tofu fmt -check -recursive terraform` | PASS | exit 0 | 형식 검사 |
| `terragrunt hcl validate --working-dir live --no-color` | PASS | exit 0 | Terragrunt HCL 검사, full dependency plan 아님 |
| `aws sts get-caller-identity --profile dev ...` | PASS | account 123456789012, SSO <SSO_USER> | 사용자 지정 profile과 코드 계정 일치 |
| 기본 profile identity | 미설정 | NoCredentials | dev 지정으로 해결 |
| sandbox network init/identity | 실패 후 복구 | DNS/endpoint 연결 실패 | 승인된 네트워크 재시도로 성공 |
| 임시 사본 `init -backend=false -lockfile=readonly`, `validate` | PASS | 10/10 configuration valid | AWS resource mutation 없이 provider schema 확인 |
| `aws s3api list-objects-v2` dev/ prefix | PASS | dev/vpc, dev/pms-storage 2개 state key | 해당 prefix 내 목록만 확인 |
| 임시 VPC backend init + `plan -lock=false -detailed-exitcode` | PASS (변경 존재) | exit 2; 1 add / 0 change / 0 destroy | S3 Gateway endpoint 신규 예정, replacement 없음 |
| VPC `describe-vpc-endpoints` | PASS | [] | 현재 VPC에 endpoint 없음, plan과 일치 |
| `aws eks list-clusters` ap-northeast-2 | PASS | [] | 해당 계정/리전에 EKS 없음; 미구현/중지 상태로 PENDING |
| `get-bucket-location pms-patch` | drift evidence | NoSuchBucket | IAC-002 |
| 임시 PMS storage backend init + plan | 검토 완료, drift 존재 | exit 2; 5 add / 0 change / 0 destroy; bucket deleted | IAC-002, 재생성/데이터 복구 의도 확인 필요 |

VPC 조회: public subnet 2개, private subnet 2개를 참조하며 각 subnet 집합은 각각 하나의 route table을 공유한다. Plan에서 public 2-AZ/IGW check 실패 없음. NAT 리소스 변경 없음. NAT 실제 전체 inventory 및 전체 routing 검증 완료로 해석하지 않는다.
Plan은 저장하지 않았으며 apply용 artifact가 아니다. lock=false 관찰이라 동시 변경에 대한 snapshot 일관성을 보장하지 않는다. 실제 적용 직전 새 plan 검토 필요.
임시 검증 자료: /private/tmp/astra-phase2 (원문 State/Secret을 보고서에 출력하지 않음).

## Remaining Issues / Blocked Items
- IAC-002: bucket 삭제 의도와 데이터 보존 요구사항 미확인.
- EKS 없음: live Kubernetes/IRSA/ALB/ArgoCD 트래픽 검증은 PENDING.
- VPC endpoint 미적용: 생성 예정이며 현재 S3 private path 검증 완료가 아님.
- GitHub 업데이트 및 원격 Git diff는 이번 작업에 포함하지 않음.

## Next Action
1. pms-patch 삭제가 의도된 실습 종료 작업인지, 복구해야 할 데이터가 있었는지 확인한다.
2. 의도된 중지라면 IAC-002를 설명과 함께 PENDING으로 재분류하고, Phase 3 Network 검증 계획을 작성해 VPC/NAT/routes/SG를 읽기 전용으로 확인한다.
3. 비의도 삭제라면 백업/원본 데이터 복구 경로를 먼저 조사한다. 빈 bucket 재생성을 데이터 복구로 취급하지 않는다.
4. 재활성화는 별도 사용자 실행 단계다. 실행 예정 명령은 VPC/PMS 각 unit에서 `AWS_PROFILE=dev terragrunt plan`으로 최신 검토 후 사용자 별도 apply. 이번 세션에서는 apply/state 변경/commit/push 미실행.

# Architecture Review Start (2026-09-17)
사용자 요청: Terraform/Terragrunt 모듈 설계를 실제 업무 기준으로 비판적으로 평가.

Validation Plan:
- Target: module/unit/state 경계, ownership, dependency, 환경 확장, provider 및 버전 관리, GitOps 전달, IaC CI.
- Purpose: validate 성공과 운영 가능한 설계를 구분.
- Validation Method: 로컬 코드 근거와 Terraform/Terragrunt 공식 문서 비교. 현재 검증 범위 및 설계 제안을 분리.
- Command: 대상 HCL/TF/workflow 읽기, `rg`, `nl`, `wc -c`, 공식 문서 조회.
- Expected Result: 장단점과 운영 실패 시나리오, 최소 개선 순서 및 migration 위험이 명확한 제안서.
- Failure Condition: 소유 범위 불명확, 수명 다른 리소스 결합, 환경값 누출, 재현/검증 경로 부재.
- 변경 범위: 검토 문서와 STATUS만. 인프라/모듈/State 재구성은 하지 않음.

# Architecture Review Result (2026-09-17)
- 완료: 사용자 요청 설계 평가. 결과는 docs/architecture/iac-design-review.md.
- 결론: modules/live 기본 패턴 유지 적절. 실무 운영 전 ownership/lifecycle/environment/version/IaC CI 보완 필요.
- Findings: ARCH-001~008 OPEN. 자세한 severity/type/evidence/root cause/impact/fix/validation은 제안서 표에 기록.
- Changed Files: docs/architecture/iac-design-review.md 신규, ASTRA_VALIDATION_STATUS.md 추가 기록만.
- 검증: module/unit/output/provider/workflow 정적 대조, Atlantis 설정 2개 파일 각각 0 byte 확인, 공식 Terraform/Terragrunt 자료 확인.
- 인프라 코드 재구성/State 이동/새 apply 없음. 기존 IAC-001 수정 판단 유지; 10개 validate를 전체 배포 성공으로 확대 해석하지 않음.
- Current Status: 전체 검증은 여전히 BLOCKED (IAC-002 bucket 삭제 의도 미확인). 설계 평가 요청은 완료.
- Next Action: Architecture Proposal 우선순위에 따라 State key 유지 가능한 개선부터 별도 변경 계획. bucket 삭제/데이터 복구 의도 질문은 기존 미해결 항목으로 유지.

# Maintenance Architecture Implementation Start (2026-09-17)
사용자가 ARCH-002/003/004 경계 개선 및 실제 업무 환경 개선을 명시적으로 요청했다. 코드 구조 변경을 수행하되 원격 apply, State 이동, commit/push는 수행하지 않는다.

Validation Plan:
Target: DB/EKS 연결, account GitHub OIDC, test/PMS IAM, 환경 입력, 업무별 작업/검토 및 CI 경로.
Purpose: 인프라/개발/DevOps 업무별 책임과 리소스 수명을 일치시키고 변경 검증 가능성을 확보.
Validation Method: 기존 구현/이름/State key 보존 대조, 분리 module backend=false validate, mock provider contract tests, Terragrunt HCL/source/dependency 검사, CI 구조 검사, Kustomize 회귀. 기존 state key 존재 여부와 IAM 소유 현황은 읽기 전용 재확인.
Command: 파일 읽기/rg, tofu fmt/init/validate/test, terragrunt hcl validate, Python 계약 검사, kubectl kustomize, aws list 조회.
Expected Result: RDS의 EKS dependency 제거, 공용 OIDC와 역할 독립, test/PMS 역할 독립, 기존 VPC/PMS storage key 유지, 잘못된 dependency/권한 확대 없음.
Failure Condition: 의도치 않은 기존 리소스 주소/State key 변경, DB/EKS 재결합, IAM trust/S3 prefix 범위 확대, 렌더링/CI 검증 실패.

## IAC-003 — Legacy Windows VPC State ownership
- Status: BLOCKED (배포 전 소유권 결정 필요); 코드 개선/오프라인 검증은 진행 가능.
- Severity: High
- Type: Operational Risk
- Component: State key portability / existing VPC ownership
- Problem: 같은 VPC의 기존 관리 State가 `dev\vpc/terraform.tfstate`에 남아 있고 현재 unit은 `dev/vpc/terraform.tfstate`에서 VPC를 data로 조회함.
- Evidence: bucket 전체 key 목록 6개; Windows VPC State에는 managed instance 12개. VPC ID vpc-04a5815b1059b0bcb가 현재 lookup VPC와 일치하며 AWS describe-vpcs 결과 available. Windows eks/atlantis/irsa State는 비어 있음.
- Root Cause: 과거 Windows 경로 구분자가 backend key에 포함된 기록과 현재 macOS/Linux 경로 기반 key가 다름. 최초 key 생성 시점의 설정/도구 버전은 미확인.
- Impact: 현재 prefix만 조회하면 기존 network 소유권을 놓침. 잘못된 State를 기준으로 관리 이관/삭제/재생성할 위험.
- Recommended Fix: 기존 VPC 관리 주체 결정, State version/실제 IDs 대조, 별도 이관 계획. 단순 state 삭제나 강제 이동을 하지 않음.
- Changed Files: live/root.hcl, devops/scripts/state_preflight.py, devops/tests/test_state_preflight.py, docs/operations/iac-maintenance.md.
- Validation Method: 경로 정규화/managed instance 판정 테스트, 전체 key inventory, legacy state의 resource address/ID만 안전하게 추출, 실제 AWS ID 비교, read-only preflight.
- Re-validation Result: preflight가 legacy key와 12 instances를 감지하고 exit 1로 중단. 근본 소유권 문제는 미해결; 보호 동작은 PASS.
- Correction to earlier evidence: Phase 2의 `dev/` prefix 내 state 2개 확인은 사실이지만 전체 bucket inventory가 아니었음. 전체 State가 2개뿐이라는 해석은 취소한다.

# Maintenance Architecture Implementation Result (2026-09-17)

## Current Phase
사용자 요청: 업무별 유지보수 구조 및 ARCH-002/003/004 수명 분리 구현 완료. 전체 AWS 검증과 실환경 배포는 별도 상태.

## Current Status
코드/로컬 검증 PASS. 실환경 적용 BLOCKED: IAC-003 기존 VPC State 소유권, IAC-002 PMS bucket 삭제 의도/복구 요구 미확인.

## Completed Validations / Resolved Findings
- ARCH-002: CODE RESOLVED — RDS unit에서 EKS dependency 및 node SG input 제거, eks-database-access 별도 unit. DB 자체 보호/비공개/암호화 유지와 EKS 없이 mock plan 검증.
- ARCH-003: CODE RESOLVED — shared/github-oidc의 account identity와 앱 role 분리; role trust/branch 제한 유지 검증.
- ARCH-004: CODE RESOLVED — 기존 irsa는 테스트만 소유; pms-irsa는 storage output과 EKS output 소비. AWS 이름과 S3 read-only prefix 범위 유지.
- ARCH-005: CODE RESOLVED (single-account/dev scope) — account/region/env 분리, module의 dev tag 입력화, allowed_account_ids 및 preflight 계정 확인. 다중 account/region 실행은 PENDING.
- ARCH-006: IMPROVED — OpenTofu/Terragrunt 버전 고정, EKS module 21.25.0 고정. upstream transitive module 완전 고정까지 주장하지 않음.
- ARCH-007: IMPROVED — credentials 없는 IaC CI, 업무별 workspace/검증 명령/PR/CODEOWNERS 추가. GitHub remote 실행/branch protection/Atlantis 설정은 PENDING.
- ARCH-008: Remaining — GitOps output 수동 PR 전달 계약 문서화; 자동 환경 manifest 생성 미구현.
- ARCH-001 / IAC-003: 기존 VPC State 소유권 정리 필요. guard 구현과 실제 차단 동작 PASS.
기존 Finding 상세와 이력은 이전 보고서에 보존. CODE RESOLVED는 AWS 적용 완료가 아님.

## Architecture / Work Environment Changes
- 기존 배포 경로를 유지하며 infrastructure/development/devops workspace로 동일 코드를 업무별 표시. GitHub/Argo 경로와 기존 dev backend key 보존.
- 10개에서 13개 unit: 공용 GitHub OIDC, PMS IAM, EKS↔DB 연결을 독립화.
- devops/contracts/iac-units.json에 module 소비자/owner/reviewer/dependencies/key 등록; 코드와 자동 대조.
- live root에서 Windows separator 정규화 및 기존 legacy 소유 검사. hook 우회 dependency 최적화 비활성화, backend bucket 자동 업데이트 비활성화.
- Makefile 작업 명령, CI install의 reviewed SHA256/고정 버전, local/CI 실행 버전 일치 검사.
- 실제 팀 handle을 꾸며내지 않고 확인된 repo owner를 CODEOWNERS로 지정. 역할별 팀 계정 전환/보호 규칙은 운영 문서에 명시.
- workflow는 읽기 권한만 사용하며 AWS OIDC/secret/apply 권한이 없음. 기존 PMS CI 및 Argo/Kubernetes manifest 변경 없음.

## Commands Executed / Validation Results
| 검증 | 결과 | 범위/핵심 증거 |
| --- | --- | --- |
| tofu fmt / terragrunt hcl fmt --check / hcl validate | PASS | 모든 변경 module/unit |
| Python unit contract 검사 | PASS | 13 unit, source 존재, State key 중복 없음, DAG, DB/EKS 및 identity 경계 |
| Terragrunt render (isolated mock dependency outputs) | PASS | 13 unit, 실제 include/env/inputs/provider/hook 평가; 원본 live에 mock 없음 |
| devops/scripts/validate_iac.py | PASS | 13 unit 모두 backend=false/readonly lock init + validate; 렌더링된 provider/inputs 사용 |
| OpenTofu mock plan tests | PASS | 총 5개: DB 보호/독립성, SG 접근 범위, CI identity/branch, PMS trust/prefix, 잘못된 prefix 거부 |
| Python state guard tests | PASS | 총 5개: Windows alias, 빈 State, 관리 instance, data-only 구분, 잘못된 계정 조기 중단 |
| 실제 State preflight | EXPECTED BLOCK / 보호 PASS | legacy dev\vpc State의 관리 instance 12개 감지 |
| 실제 Terragrunt init 진입점, backend=false | EXPECTED BLOCK / 보호 PASS | before_hook 실패 후 `Not running 'terraform'`; provider/backend 초기화 진행 안 함 |
| AWS read-only inventory | PASS | 전체 State key 6개, legacy network VPC ID 실제 available, 해당 IAM role/OIDC 없음 |
| kubectl kustomize | PASS | 기존 8개 resource 렌더링; Argo/Kubernetes 원본 byte 비교 동일 |
| workflow YAML / Python syntax / workspace paths / links | PASS | workflow 2개 파싱, workspace 3개 경로 유효, relative link 21개 유효 |
| CI Linux 도구 설치 | PARTIAL | 공식 release asset SHA256 확인 및 local/CI 버전 일치 PASS; 실제 GitHub Linux job 실행 NOT VERIFIED |

재검증 중 수정한 검증 설정: GitHub role에서 TLS 요구 제거 후 기존 lock의 TLS block 제거, mock policy ARN을 실제 schema에 맞게 보정. 각각 원인 확인 후 후속 전체 검증 PASS. Python py_compile은 시스템 cache 쓰기 권한으로 실패했으며 cache 쓰기 없는 compile 검사로 PASS. 이는 프로젝트 코드 구문 오류가 아니었음.

## Remaining Issues / Blocked Items
- IAC-003: 살아 있는 기존 VPC의 소유 State를 결정하고 이관/보존 절차 검토 필요. 자동 State 변경 없음.
- IAC-002: bucket 삭제/데이터 보존 의도 미확인. 재생성 없음.
- Git metadata 없는 로컬 사본: 변경 파일은 세션 시작 snapshot과 비교. commit/branch/remote diff 미검증.
- 실환경 dependency plan, AWS 변경 및 CI remote 실행은 미완료. 단순 validate를 운영 준비 완료로 기록하지 않음.
- Branch protection 및 실제 여러 팀의 reviewer 연결은 GitHub 운영 설정 필요.

## Next Action
1. VPC 소유권: legacy State의 기존 VPC 관리 유지 또는 명시적 이관 중 운영 방식을 결정하고 resource/ID/State version 기반 계획을 작성한다. guard 제거로 우회하지 않는다.
2. bucket 삭제 의도를 확인한 뒤 activation/복구 범위를 정한다.
3. 검토된 로컬 변경을 실제 Git checkout에 대조·반영하고 PR에서 IaC CI와 CODEOWNERS 보호를 활성화한다. 자동 commit/push 하지 않음.
4. 공용 OIDC → 앱 role, VPC → DB/EKS → 연결/IAM 순서의 실제 plan을 재검토한다. applies는 사용자 별도 실행 단계.

## Changed Files (이번 요청; 시작 snapshot과 비교)
- .github/CODEOWNERS
- .github/pull_request_template.md
- .github/workflows/iac-ci.yml
- .gitignore
- .tool-versions
- ASTRA_VALIDATION_STATUS.md
- Makefile
- README.md
- development.code-workspace
- devops.code-workspace
- devops/README.md
- devops/contracts/iac-units.json
- devops/contracts/mock-outputs.json
- devops/scripts/check_contracts.py
- devops/scripts/install_ci_tools.py
- devops/scripts/render_contracts.py
- devops/scripts/state_preflight.py
- devops/scripts/validate_iac.py
- devops/tests/test_state_preflight.py
- docs/architecture/iac-design-review.md
- docs/operations/iac-maintenance.md
- docs/operations/pms-on-eks.md
- docs/operations/team-workflow.md
- infrastructure.code-workspace
- live/account.hcl
- live/dev/alb-controller/terragrunt.hcl
- live/dev/atlantis/terragrunt.hcl
- live/dev/ecr/terragrunt.hcl
- live/dev/eks-database-access/.terraform.lock.hcl
- live/dev/eks-database-access/terragrunt.hcl
- live/dev/eks/terragrunt.hcl
- live/dev/env.hcl
- live/dev/external-secrets/terragrunt.hcl
- live/dev/github-actions-ecr/.terraform.lock.hcl
- live/dev/github-actions-ecr/terragrunt.hcl
- live/dev/irsa/terragrunt.hcl
- live/dev/pms-irsa/.terraform.lock.hcl
- live/dev/pms-irsa/terragrunt.hcl
- live/dev/pms-storage/terragrunt.hcl
- live/dev/rds/terragrunt.hcl
- live/dev/vpc/terragrunt.hcl
- live/region.hcl
- live/root.hcl
- live/shared/github-oidc/.terraform.lock.hcl
- live/shared/github-oidc/terragrunt.hcl
- terraform/modules/alb-controller/main.tf
- terraform/modules/alb-controller/variables.tf
- terraform/modules/alb-controller/versions.tf
- terraform/modules/atlantis/versions.tf
- terraform/modules/ecr/versions.tf
- terraform/modules/eks-database-access/main.tf
- terraform/modules/eks-database-access/outputs.tf
- terraform/modules/eks-database-access/tests/access.tftest.hcl
- terraform/modules/eks-database-access/variables.tf
- terraform/modules/eks-database-access/versions.tf
- terraform/modules/eks/main.tf
- terraform/modules/eks/variables.tf
- terraform/modules/eks/versions.tf
- terraform/modules/external-secrets/main.tf
- terraform/modules/external-secrets/variables.tf
- terraform/modules/external-secrets/versions.tf
- terraform/modules/github-actions-ecr/main.tf
- terraform/modules/github-actions-ecr/outputs.tf
- terraform/modules/github-actions-ecr/tests/trust.tftest.hcl
- terraform/modules/github-actions-ecr/variables.tf
- terraform/modules/github-actions-ecr/versions.tf
- terraform/modules/github-oidc/main.tf
- terraform/modules/github-oidc/outputs.tf
- terraform/modules/github-oidc/variables.tf
- terraform/modules/github-oidc/versions.tf
- terraform/modules/irsa/main.tf
- terraform/modules/irsa/outputs.tf
- terraform/modules/irsa/variables.tf
- terraform/modules/irsa/versions.tf
- terraform/modules/pms-irsa/main.tf
- terraform/modules/pms-irsa/outputs.tf
- terraform/modules/pms-irsa/tests/access.tftest.hcl
- terraform/modules/pms-irsa/variables.tf
- terraform/modules/pms-irsa/versions.tf
- terraform/modules/pms-storage/versions.tf
- terraform/modules/rds-postgres/main.tf
- terraform/modules/rds-postgres/tests/lifecycle.tftest.hcl
- terraform/modules/rds-postgres/variables.tf
- terraform/modules/rds-postgres/versions.tf
- terraform/modules/vpc/versions.tf
