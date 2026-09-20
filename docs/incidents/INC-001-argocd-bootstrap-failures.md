# INC-001: Argo CD Bootstrap Failures and Recovery

## Incident Summary

Argo CD를 Amazon EKS에 설치하고 GitOps Application을 bootstrap하는 과정에서 scheduling, Private Repository authentication, manifest generation 문제가 순차적으로 발생했다.

```text
Argo CD 설치
  -> Pod Pending
      -> FailedScheduling / maxPods=11 확인
          -> Worker Node 1 -> 2 확장
              -> Argo CD Component 정상화
                  -> Application Unknown
                      -> Private Repository 인증 실패 해결
                          -> Empty kustomization.yaml 해결
                              -> Synced / Progressing
                                  -> Synced / Healthy
                                      -> Deployment 3/3
```

## Environment

| 항목 | 값 |
| --- | --- |
| Kubernetes Runtime | Amazon EKS |
| Worker Node Group | Managed Node Group |
| Initial Worker Node 수 | 1 |
| Resolved Worker Node 수 | 2 |
| GitOps Tool | Argo CD |
| Git Repository | GitHub Private Repository |
| Application manifest path | `project/kubernetes/app` |
| Application image | `nginx:1.27-alpine` |

## Symptoms

1. Argo CD `application-controller`와 `argocd-server`가 Pending 상태였다.
2. Node 확장 후에도 Application SYNC STATUS가 Unknown 상태였다.
3. Repository 인증을 해결한 뒤에도 Kustomize manifest generation이 실패했다.

## Timeline

| 순서 | 관찰 | 진단 및 조치 | 결과 |
| --- | --- | --- | --- |
| 1 | Argo CD Pod Pending | `kubectl describe`로 Scheduler Event 확인 | `Too many pods` 확인 |
| 2 | 단일 Node의 maxPods 11, Pod Object 13 | Worker Node 1 -> 2 확장 | Argo CD Pod Running |
| 3 | Application Unknown | Application conditions와 Repo Server logs 확인 | Private Repository 인증 오류 확인 |
| 4 | `authentication required` | Fine-grained PAT + Repository Secret 적용 | Repository manifest 조회 시작 |
| 5 | SYNC STATUS Unknown 지속 | Kustomize 오류 확인 | 빈 `kustomization.yaml` 발견 |
| 6 | manifest generation 실패 | resources 등록, 로컬 Kustomize 검증, hard refresh | Synced / Healthy, Deployment 3/3 |

## Observation and Investigation

### 1. Pod Scheduling

조사 명령:

```powershell
kubectl describe pod argocd-application-controller-0 -n argocd
```

Scheduler Event:

```text
0/1 nodes are available: 1 Too many pods.
```

Node 관찰값은 CPU Capacity 2, Memory 약 2 GiB, maxPods 11, Cluster Pod Object Count 13이었다. Pending 상태만으로 CPU/Memory 부족이라고 가정하지 않고 Scheduler Event를 먼저 확인했다.

### 2. Private Repository Authentication

조사 명령:

```powershell
kubectl get application web-app-dev -n argocd -o jsonpath='{.status.conditions}'
```

관찰 오류:

```text
Failed to load target state
failed to list refs
authentication required: Repository not found
```

Application conditions와 Repo Server logs 모두에서 동일한 인증 오류를 확인했다.

### 3. Kustomize Manifest Generation

Repository 인증이 해결된 후 다음 오류가 드러났다.

```text
kustomize build ... failed
Error: kustomization.yaml is empty
```

`project/kubernetes/app/kustomization.yaml`은 존재했지만 0 byte였고, Argo CD가 생성할 manifest가 없었다.

## Root Cause

| Incident | Root Cause |
| --- | --- |
| Pod Scheduling Failure | 단일 Worker Node의 maxPods 제한 도달 |
| Repository Authentication | Private GitHub Repository에 대한 Argo CD Credential 부재 |
| Empty Kustomization | Kustomization 파일은 존재했지만 resources 선언이 없는 빈 파일 |

## Resolution

### Worker Node 확장

`project/live/dev/eks/terragrunt.hcl`의 desired size를 `1 -> 2`로 변경했다. `terragrunt plan`이 No changes를 반환해 실제 런타임 확장은 `aws eks update-nodegroup-config`로 수행했다.

### Repository Secret 등록

- Fine-grained PAT를 생성했다.
- 대상 Repository를 `aws-devsecops-project`로 제한했다.
- `Contents: Read-only` 권한을 사용했다.
- PAT을 Git/YAML에 저장하지 않고 Argo CD namespace의 Kubernetes Repository Secret으로 등록했다.

### Kustomize resources 등록

`project/kubernetes/app/kustomization.yaml`을 아래처럼 구성했다.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
```

로컬 검증 명령:

```powershell
kubectl kustomize .\project\kubernetes\app
```

## Validation

### 검증 완료

- Worker Node 2개 Ready
- `argocd-application-controller` Running
- `argocd-server` Running
- 전체 Argo CD Component Running
- Argo CD Application `Synced / Healthy`
- Deployment `3/3 Ready`
- Git의 replicas `2 -> 3` 변경이 EKS Deployment에 자동 반영됨

### Pending

- `selfHeal: true` 설정의 실제 Drift 복구 검증은 아직 수행하지 않았다.
- 향후 `kubectl scale deployment web-app --replicas=1` 실행 후 Git Desired State인 replicas 3으로 복구되는지 검증한다.

## Security Considerations

- PAT은 Private Repository의 단일 Repository 범위로 제한한다.
- PAT 권한은 `Contents: Read-only`로 최소화한다.
- PAT을 Git, YAML, 기술문서에 기록하지 않는다.
- Argo CD namespace의 Kubernetes Secret으로만 Repository Credential을 관리한다.
- 향후 GitHub App 또는 Secrets Manager/External Secrets 기반 Secret 관리를 검토한다.

## Cost / Operational Considerations

- EKS Worker Node와 Argo CD Pod는 private subnet에서 실행된다.
- GitHub, 공개 이미지 Registry, AWS Public API 통신이 필요한 실습 시간에는 NAT Gateway를 활성화한다.
- 실습 종료 후 NAT Gateway와 EIP를 제거해 상시 NAT 비용을 방지한다.
- NAT Gateway를 제거해도 EKS control plane, managed node EC2, EBS, ECR 등의 비용은 별도로 계속 발생할 수 있다.

## Prevention

- Argo CD 같은 추가 Kubernetes 구성요소를 배포하기 전 Node의 maxPods와 현재 Pod 수를 확인한다.
- Pending 상태는 CPU/Memory 부족으로 단정하지 않고 Scheduler Event를 먼저 확인한다.
- Private Repository를 Argo CD에 등록할 때 Repository Credential을 함께 준비한다.
- Git push 전 `kubectl kustomize .\project\kubernetes\app`으로 manifest generation을 검증한다.
- 하나의 오류를 해결한 뒤 다음 오류가 드러날 수 있으므로, 조치 후 Application conditions와 Repo Server logs를 다시 확인한다.

## Lessons Learned

이번 bootstrap은 하나의 설정 오류가 아니라 scheduling, authentication, manifest generation 문제가 순차적으로 드러난 사례였다. 문제를 계층별로 분리해 `kubectl describe`, Application conditions, Repo Server logs를 사용해 진단하면 원인과 해결을 혼동하지 않을 수 있다. 또한 변경 후 실제 Cluster 상태를 다시 검증해야 GitOps 구성의 성공 여부를 정확히 판단할 수 있다.
