# IaC 유지보수와 분리 적용 절차

## 현재 상태
코드 분리와 로컬 회귀 검증은 완료했으며 AWS 적용이나 State 이동은 수행하지 않았다. 기존 `live/dev/*` 디렉터리와 Linux/macOS 기준 backend key를 유지한다. 추가 unit은 `shared/github-oidc`, `dev/pms-irsa`, `dev/eks-database-access`이다.

2026-09-17 읽기 전용 확인:
- `dev/vpc/terraform.tfstate`, `dev/pms-storage/terraform.tfstate` 존재.
- `dev\atlantis/terraform.tfstate`, `dev\eks/terraform.tfstate`, `dev\irsa/terraform.tfstate`는 관리 리소스/outputs가 비어 있음.
- `dev\vpc/terraform.tfstate`에는 VPC/Subnet/IGW/Route table/association 12개 instance 소유 기록이 남음. 이 State의 VPC ID는 현재 코드가 조회하는 `vpc-04a5815b1059b0bcb`와 같고 실제 AWS 상태는 `available`임.
- 관련 `dev-eks*`, `github-actions-pms-ecr` 역할 및 계정 OIDC provider는 조회 결과 없음.
- PMS bucket은 삭제 drift가 확인되어 별도 IAC-002가 열려 있음.

**VPC legacy State가 비워졌다고 가정하면 안 된다.** `data`로 VPC를 조회하는 현재 코드와 기존 resource 소유 State의 관계를 먼저 정리해야 한다. 새 preflight는 기존 resource가 있는 동명 Windows key를 발견하면 해당 unit의 init/plan/apply를 막는다. 하위 dependency 조회도 이 보호를 우회하지 않도록 dependency optimization을 비활성화했다. 캐시에서 직접 tofu를 실행하면 이 절차를 우회할 수 있으므로 운영 진입점은 Terragrunt로 통일한다.

## 도구와 로컬 검증
`.tool-versions`: OpenTofu 1.12.6, Terragrunt 1.1.4. Python 3.9 이상, AWS CLI, kubectl 필요. 환경 인증은 `AWS_PROFILE=dev` 등 실행자 환경에서 지정하고 코드에 SSO 사용자/자격증명을 넣지 않는다.

```bash
make validate-infra
make render-gitops
```
검증은 네트워크로 module/provider를 다운로드할 수 있지만 AWS credential 및 backend 없이 임시 디렉터리에서 수행한다. policy/보호 설정 테스트는 mock provider + plan만 사용한다.

## State 소유 정리 (현재 live plan 차단 원인)
1. 같은 계정/리전 및 bucket의 전체 key 목록을 조회한다. `dev/` prefix만 조회하면 Windows key를 놓친다.
2. 보안 통제된 위치에서 각 State의 resource address/ID를 실제 AWS와 대조한다. State에는 secret이 있을 수 있으므로 PR/log에 원문을 붙이지 않는다.
3. 기존 VPC 소유권을 기존 State에 유지할지, 현재 network unit으로 이관할지 운영자가 결정한다. 두 State가 동일 resource를 동시에 소유하지 않도록 한다.
4. 별도 검토된 migration 절차와 복구 가능한 State version을 확보한다. 이 문서는 자동 state rm/mv/import를 제공하거나 실행하지 않는다.
5. legacy key가 더 이상 resource를 소유하지 않는다는 증거를 확보한 뒤 preflight와 plan을 재실행한다. 단순히 guard를 삭제하거나 bucket의 State 객체를 지우지 않는다.

## 분리된 수명과 배포 순서
```text
shared/github-oidc ──────────────> github-actions-ecr <── ecr
vpc ──> rds ────────────────────> eks-database-access <── eks <── vpc
          └──> external-secrets <──────────────────────── eks
pms-storage ───────────────────> pms-irsa <────────────── eks
                                                         └──> irsa (test only)
```
- DB 본체 및 DB SG: `rds`에서 관리. EKS 없이 독립 plan 가능하도록 입력 계약을 분리.
- DB ingress rule: `eks-database-access`만 관리. EKS 교체 후 이 단위만 재검토.
- 공용 GitHub identity: `shared/github-oidc`가 한 번 관리. 앱별 IAM role은 ARN을 소비.
- 테스트 IAM: 기존 `irsa` 경로. PMS IAM: 새 `pms-irsa`, storage 출력에 명시적으로 의존.
- 배포 전에는 External Secrets/DB뿐 아니라 `eks-database-access`와 `pms-irsa`도 준비되어야 함.

## 기존 State에 리소스가 있었을 때의 이전 매핑
현재 조회한 관련 기존 State는 비어 있지만, 적용 시점에 다시 확인한다. 다른 환경/백업 State에 아래 주소가 있다면 이 코드를 그대로 적용하면 삭제/중복 생성 위험이 있다.

| 이전 unit/address | 새 unit/address |
| --- | --- |
| github-actions-ecr / aws_iam_openid_connect_provider.github_actions | shared/github-oidc / 동일 address |
| irsa / aws_iam_role.pms_backend[0] | pms-irsa / aws_iam_role.pms_backend |
| irsa / aws_iam_policy.pms_patch_read[0] | pms-irsa / aws_iam_policy.pms_patch_read |
| irsa / aws_iam_role_policy_attachment.pms_patch_read[0] | pms-irsa / aws_iam_role_policy_attachment.pms_patch_read |
| rds / aws_vpc_security_group_ingress_rule.postgres_from_eks | eks-database-access / 동일 address |

cross-State 이동은 module 안의 moved block만으로 해결되지 않는다. 실제 이관은 State version/주소/실제 ID를 확보한 별도 작업으로 수행하고 이전/새 unit 양쪽 plan이 예상치 않은 삭제/교체를 제안하지 않는지 확인한다. 기존 테스트 IAM, DB 본체, bucket, cluster의 AWS 이름은 유지한다.

## 실제 plan 검토 절차
State 소유 문제가 해소된 뒤 각 unit 디렉터리에서:

```bash
export AWS_PROFILE=dev
terragrunt run --disable-bucket-update --backend-require-bootstrap -- plan -lock=false -input=false
```
위 명령은 read-only 검토용이다. State lock 없이 실행하므로 동시에 다른 apply가 없는 유지보수 구간에서만 사용한다. 적용 직전에는 최신 검토와 정상 잠금이 있는 별도 배포 절차가 필요하다. CI mock/validate는 실제 plan을 대체하지 않는다.

승인 판단 자료: 정확한 commit/local revision, 계정/리전/State key, dependency 순서, add/change/destroy/replacement 수, IAM 변경, 비용, DB 데이터 보존, rollback. 적용은 사용자의 별도 실행 단계이며 이번 작업에서 수행하지 않았다.

## 복구
- 코드 적용 전: 변경 코드를 이전 버전으로 되돌리고 재검증한다.
- State 이관 후: 코드만 되돌리지 않는다. 승인된 State 복구/역이관 절차와 resource 소유권 대조가 함께 필요하다.
- DB/Storage: 삭제 후 빈 리소스 재생성은 데이터 복구가 아니다. 백업/원본 복구를 별도로 검증한다.
