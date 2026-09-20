# Argo CD GitOps on Amazon EKS

> Historical lab record: nginx / web-app / 3 replicas and the runtime results below describe the earlier exercise. Current local code prepares PMS Backend with 2 replicas. Actual AWS state has not been verified in this session. See the [PMS activation runbook](../operations/pms-on-eks.md) and [ASTRA Validation Status](../../ASTRA_VALIDATION_STATUS.md).

## 1. 목적

GitHub에 선언된 Kubernetes 매니페스트를 Argo CD가 Amazon EKS에 지속적으로 반영하도록 구성한다. Git을 Desired State의 Source of Truth로 사용하고, 클러스터에서 발생하는 상태 차이를 Argo CD Reconciliation으로 관리하는 것이 목표다.

## 2. Architecture

```text
Developer
  -> Git Push
      -> GitHub Private Repository
          -> Argo CD Repo Server
              -> Kustomize
                  -> Argo CD Application Controller
                      -> Kubernetes API
                          -> AWS EKS
```

| 구성요소 | 역할 |
| --- | --- |
| GitHub | Desired State와 변경 이력을 관리하는 Source of Truth |
| Amazon EKS | 실행 중인 Kubernetes Actual State |
| Argo CD Repo Server | Git Repository 인증 및 manifest 조회/생성 |
| Kustomize | Deployment와 Service를 배포 단위로 조립 |
| Argo CD Application Controller | Desired State와 Actual State를 비교하고 동기화 |

## 3. Argo CD Application 구성

Application manifest는 `project/argocd/web-app-dev.yaml`에 정의한다.

| 설정 | 값 | 의미 |
| --- | --- | --- |
| `repoURL` | GitHub Private Repository | GitOps 대상 Repository |
| `targetRevision` | `main` | 감시할 Branch |
| `path` | `kubernetes/app` | Repository 내부 Kubernetes manifest 경로 |
| `destination.server` | `https://kubernetes.default.svc` | Argo CD가 실행 중인 EKS Cluster |
| `destination.namespace` | `default` | 애플리케이션 배포 Namespace |
| `automated` | enabled | Git 변경 자동 동기화 |
| `prune` | `true` | Git에서 삭제된 관리 리소스 삭제 |
| `selfHeal` | `true` | Drift 발생 시 Git Desired State로 복구하도록 설정 |

## 4. 선택한 방식과 이유

### Automated Sync

`project/argocd/web-app-dev.yaml`에서 Automated Sync, prune, selfHeal을 활성화했다.

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

- Automated Sync: Git push 후 선언 상태 변경을 자동 반영한다.
- prune: Git에서 삭제된 Argo CD 관리 리소스를 클러스터에서도 삭제한다.
- selfHeal: 수동 변경으로 발생한 Drift를 Git 상태로 복구하도록 **설정**한다.

### 대안과 비교

| 작업 | 선택한 방식 | 대안 | 선택 이유 | 비용 영향 | 보안/운영 영향 | 완료 검증 방법 | 롤백 방법 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Kubernetes 배포 | Argo CD Automated Sync | 수동 `kubectl apply`, CI에서 `kubectl apply` | Git commit을 배포 기준으로 유지하고 지속 reconciliation을 사용하기 위함 | Argo CD 운영 리소스 필요 | CI에 Cluster Admin 권한을 직접 부여하지 않는 구조로 확장 가능 | Git 변경이 EKS Deployment에 자동 반영되는지 확인 | 이전 Git commit revert 후 Argo CD Sync |
| Git Repository 인증 | Fine-grained PAT + Argo CD Repository Secret | GitHub App, SSH Deploy Key, External Secrets | 현재 학습 프로젝트에서 가장 빠르게 최소 권한을 적용할 수 있음 | 추가 AWS 비용 없음 | Repository 범위 제한, Contents Read-only, PAT 미커밋 | Repo Server authentication 오류 제거 및 manifest 조회 확인 | Secret 삭제 또는 PAT 폐기 |

## 5. Private Git Repository 인증

### 관찰

GitHub Repository가 Private인 상태에서 Argo CD에 Repository Credential을 등록하지 않으면, Application이 Repository의 target state를 조회할 수 없었다.

```text
authentication required: Repository not found
```

### 진단과 원인

`project/argocd/web-app-dev.yaml`의 Repository URL과 Branch는 올바르지만, Argo CD Repo Server에 GitHub 인증정보가 없어 refs 및 manifest를 읽을 수 없었다. Private GitHub Repository는 인증되지 않은 Argo CD Repo Server의 접근을 허용하지 않는다.

### 해결

- GitHub Fine-grained PAT를 생성한다.
- 대상 Repository를 `aws-devsecops-project`로 제한한다.
- `Contents` 권한은 Read-only로 설정한다.
- PAT은 Git 또는 YAML에 저장하지 않는다.
- PAT을 Argo CD namespace의 Kubernetes Repository Secret으로 등록한다.

### 검증 완료

Repository 인증 오류가 제거되고 Argo CD가 Git Repository의 manifest를 읽기 시작한 것을 확인했다.

## 6. Automated Sync 검증

### 관찰과 변경

초기 `project/kubernetes/app/deployment.yaml`의 replicas는 `2`였다. Git에서 replicas를 `2 -> 3`으로 변경하고, `test: validate Argo CD automated sync` commit을 `main` Branch에 push했다.

### 검증 완료

| 항목 | 결과 |
| --- | --- |
| Argo CD Application | `Synced / Healthy` |
| Deployment replicas | 3 |
| READY | `3/3` |
| UP-TO-DATE | 3 |
| AVAILABLE | 3 |

Git Desired State의 `replicas=3`이 Argo CD reconciliation을 통해 EKS Actual State의 replicas 3으로 자동 반영되는 것을 실제 검증했다.

## 7. Self-Heal 검증

**Status: Pending (미검증)**

`selfHeal: true`는 Application에 설정되어 있지만, 실제 Drift 복구는 아직 검증하지 않았다. 따라서 Self-Heal 검증 완료로 기록하지 않는다.

향후 아래 테스트를 수행한다. 명령은 `project/` 상위 경로에서 실행한다.

```powershell
kubectl scale deployment web-app --replicas=1
```

| 구분 | 기대 상태 |
| --- | --- |
| Git Desired State | replicas 3 |
| 수동 변경 직후 Actual State | replicas 3 -> 1 |
| Argo CD 동작 | Drift 감지 |
| 복구 기대값 | replicas 1 -> 3 |

## 8. Troubleshooting

### Incident 1 - Argo CD Pod Scheduling Failure

#### 증상과 조사

- `argocd-application-controller` Pending
- `argocd-server` Pending
- `dex-server`의 일시적인 CrashLoop/restart

```powershell
kubectl describe pod argocd-application-controller-0 -n argocd
```

```text
0/1 nodes are available: 1 Too many pods.
```

Node 관찰값은 CPU Capacity 2, Memory 약 2 GiB, maxPods 11, Cluster Pod Object Count 13이었다.

#### 원인과 해결

CPU 또는 Memory 부족이 아니라 단일 EKS Worker Node의 maxPods 제한에 도달해 Scheduler가 추가 Argo CD Pod를 배치할 수 없었다. `project/live/dev/eks/terragrunt.hcl`의 `node_desired_size`를 `1 -> 2`로 수정했다. 다만 `terragrunt plan`은 No changes를 반환했으며, EKS module/runtime의 desired size 처리 방식 때문에 실제 런타임 확장은 `aws eks update-nodegroup-config`로 수행했다.

#### 검증 완료

Worker Node를 2개로 확장한 후 Node 2개 Ready, `argocd-application-controller` Running, `argocd-server` Running, 전체 Argo CD Component Running을 확인했다.

### Incident 2 - Private GitHub Repository Authentication

#### 증상과 조사

Application 상태는 `SYNC STATUS: Unknown`, `HEALTH STATUS: Healthy`였다. Git에서 replicas를 `2 -> 3`으로 변경하고 push했지만 EKS Deployment는 `2/2` 상태를 유지했다.

```powershell
kubectl get application web-app-dev -n argocd -o jsonpath='{.status.conditions}'
```

```text
Failed to load target state
failed to list refs
authentication required: Repository not found
```

Repo Server 로그에서도 같은 authentication error를 확인했다.

#### 원인과 해결

Private Repository에 접근할 Argo CD Repository Credential이 없었다. Repository 범위와 Contents Read-only 권한으로 제한한 Fine-grained PAT를 생성하고, Argo CD Repository Secret으로 등록했다.

#### 검증 완료

인증 오류가 제거되고 Argo CD가 Git Repository manifest를 읽기 시작했다.

### Incident 3 - Empty kustomization.yaml

#### 증상과 원인

Private Repository 인증을 해결한 뒤에도 Application의 SYNC STATUS가 Unknown 상태였다. `project/kubernetes/app/kustomization.yaml` 파일은 존재했지만 0 byte 빈 파일이어서 다음 오류가 발생했다.

```text
kustomize build ... failed
Error: kustomization.yaml is empty
```

#### 해결과 검증 완료

Kustomization에 Deployment와 Service를 resources로 등록하고, 로컬에서 manifest generation을 검증한 뒤 Git commit/push 및 Argo CD hard refresh를 수행했다.

```powershell
kubectl kustomize .\project\kubernetes\app
```

Argo CD Application은 `Synced / Progressing`을 거쳐 `Synced / Healthy`가 되었고, Deployment는 `3/3 Ready` 상태를 확인했다.

## 9. Security and Operation

- Git 변경 이력을 배포 이력으로 활용하고 수동 Cluster 변경을 최소화한다.
- PAT은 Git/YAML에 저장하지 않으며 Repository 단위와 `Contents: Read-only` 권한으로 제한한다.
- 문제 발생 시 Scheduler Event, Application conditions, Repo Server logs를 각각 확인해 scheduling, authentication, manifest generation 원인을 분리한다.
- private subnet에서 GitHub, 공개 이미지 Registry, AWS Public API 접근이 필요한 실습 시간에만 NAT Gateway를 활성화한다.
- 실습 종료 시 `project/live/dev/vpc/terragrunt.hcl`의 `enable_nat_gateway = false`를 적용해 NAT Gateway와 EIP를 제거한다.

## 10. Rollback

Git에서 정상 동작한 이전 commit으로 revert하면 Argo CD가 이전 Desired State를 EKS에 다시 동기화한다.

```text
Git revert
  -> GitHub main Branch
      -> Argo CD Sync
          -> Previous Desired State
```

## 11. 향후 개선

- Self-Heal Drift 복구 실제 검증
- GitHub App 또는 Secrets Manager/External Secrets 기반 Repository Credential 관리 검토
- 실제 PMS 이미지의 GitHub Actions build, vulnerability scan, Amazon ECR push
- S3 Gateway Endpoint를 통한 S3 트래픽의 NAT 우회 비용 최적화
