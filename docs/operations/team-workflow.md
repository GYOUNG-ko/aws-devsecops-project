# 인프라 · 개발 · DevOps 업무 방식

## 작업 영역과 책임
업무 경계는 담당 코드, 변경 권한, 리뷰와 전달 계약으로 정의한다. GitHub/Argo CD/State가 사용하는 경로를 한꺼번에 옮기지 않고 기존 경로를 유지한다. 아래 workspace 파일은 같은 소스를 업무별로 묶어 보여 주며 복사본을 만들지 않는다.

| 업무 | 작업 화면 | 담당 코드 | 주 검증 | 공동 검토 |
| --- | --- | --- | --- | --- |
| 인프라 | `infrastructure.code-workspace` | `terraform/`, `live/` | `make validate-infra`, 환경별 실제 plan | IAM/OIDC/네트워크는 DevOps와 배포 영향 검토; DB는 개발과 호환성 검토 |
| 개발 | `development.code-workspace` | `backend/`, `app/`, backend migration/tests | `make verify-app` | DB migration, port/probe/env 변경은 인프라·DevOps와 검토 |
| DevOps | `devops.code-workspace` | `.github/`, `devops/`, `argocd/`, `kubernetes/`, `atlantis/` | `make test-devops`, `make render-gitops`, CI | IAM 권한은 인프라 승인, 이미지/health contract는 개발 승인 |

현재 GitHub 계정/팀으로 확인된 담당자는 저장소 소유자 `@GYOUNG-ko`뿐이므로 CODEOWNERS는 이 사용자로 등록한다. 세 업무 역할이 세 명의 인원을 뜻하지는 않는다. 실제 팀 계정이 준비되면 경로별 reviewer를 바꾸고 branch protection에서 Code Owner review 및 IaC validation을 required로 설정한다. 로컬 CODEOWNERS/PR template만으로 GitHub 보호 규칙이 활성화되지는 않는다.

## 인프라 변경
1. 변경 unit 및 모든 소비자를 `devops/contracts/iac-units.json`에서 확인한다.
2. `make validate-infra`로 13개 unit을 검증한다. 공통 module/root 변경은 소비자 전체가 영향 대상이다.
3. IaC 유지보수 절차의 계정/State preflight 후 실제 plan을 얻는다. mock 통과를 배포 가능 판정으로 사용하지 않는다.
4. PR에 생성/변경/삭제/교체 수, 비용, dependency 순서, 데이터 보존 영향을 기록한다.
5. 검토된 변경만 별도 실행 단계에서 적용한다. 자동 apply/전체 stack destroy를 두지 않는다.
6. IaC 출력 변경이 있으면 DevOps가 해당 GitOps 설정 PR을 갱신한다.

## 개발 변경
1. Backend API·UI·DB migration을 변경하고 애플리케이션 테스트를 실행한다.
2. 포트, health endpoint, IAM 요청, Secret/env key가 바뀌면 같은 PR에서 배포 계약을 검토한다.
3. 앱 CI는 build/scan 후 ECR image digest를 GitOps에 반영하는 기존 흐름을 유지한다.
4. DB migration은 이전/다음 앱 버전의 공존과 rollback을 검토한다. 이미지 rollback이 DB schema rollback을 보장하지 않는다.

## DevOps 변경
1. workflow/배포 manifest/검증 도구를 변경한다. CI 정의는 개발 소스와 독립적으로 검토한다.
2. Kubernetes 리소스의 최종 소유자는 Argo CD이며 Terraform에서 동일 리소스를 중복 관리하지 않는다.
3. Terraform output → GitOps의 ARN/clusterName/image 계약은 현재 명시적인 PR 반영 방식이다. 아직 자동 생성 파이프라인으로 구현되지 않았다.
4. Atlantis는 EC2 방향을 유지하지만 서버 설정이 미구현이다. 현재는 credentials 없는 IaC CI와 수동 reviewed plan 절차를 사용한다.

## 환경 확장
현재는 단일 account/region + dev를 유지한다.
- `live/account.hcl`: AWS 계정과 State bucket, 프로젝트 소유 정보.
- `live/region.hcl`: 실행 리전.
- `live/dev/env.hcl`: 환경명, clusterName, PMS bucket/prefix, 환경 태그.
- `live/shared/github-oidc`: 같은 계정의 공용 GitHub identity.

새 환경 도입 시 dev를 그대로 apply하지 않는다. bucket/role/repository/DB 이름 충돌과 공용 OIDC 재사용을 먼저 검토하고, env 설정과 unit inventory/lockfile, GitOps 환경 구성을 함께 추가한다. 계정/리전 계층을 도입하는 변경은 기존 State key 이전 계획이 있어야 한다. 이번 작업은 prod 리소스나 새 AWS 계정을 만들지 않았다.
