# DevOps 업무 영역

이 디렉터리는 검증 자동화와 인프라/애플리케이션 사이의 계약을 관리한다.

- `contracts/iac-units.json`: 담당 업무, module 소비 unit, State key, 의존성 목록. 변경 시 CI가 실제 구성과 대조한다.
- `contracts/mock-outputs.json`: AWS 없는 검증용 fixture. 실제 live 구성에 주입하지 않는다.
- `scripts/validate_iac.py`: 임시 사본의 Terragrunt 렌더링, backend 없는 init/validate, mock plan 테스트.
- `scripts/state_preflight.py`: 계정 및 Windows legacy State 별칭의 기존 resource 소유 검사. live root hook에서 사용.
- `scripts/install_ci_tools.py`: 고정 버전/검토된 SHA256으로 Linux CI 도구 설치.
- `tests/`: State 경로/소유권 보호 회귀 테스트.

GitHub 요구 경로인 `.github/workflows`, Argo CD가 참조하는 `argocd/`, `kubernetes/`, 별도 EC2용 `atlantis/`도 DevOps 담당이다. CI는 credentials 없이 검증하며 apply하지 않는다.

저장소 루트에서 `make validate-infra`, `make test-devops`, `make render-gitops`를 사용한다.
[업무별 협업 절차](../docs/operations/team-workflow.md)와 [IaC 변경 절차](../docs/operations/iac-maintenance.md)를 따른다.
