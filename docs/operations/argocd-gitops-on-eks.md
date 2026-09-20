# Argo CD GitOps on Amazon EKS

## 1. 작업 목적

기존 Kind 기반 GitOps 환경을 Amazon EKS로 이관하고, GitHub에 선언된 Kubernetes 상태를 Argo CD가 EKS 클러스터에 지속적으로 반영하는 GitOps 흐름을 검증한다.

## 2. Architecture

```text
Developer
  -> GitHub Repository (main)
      -> Argo CD Application
          -> Kustomize (kubernetes/app)
              -> Kubernetes API
                  -> EKS Deployment
                      -> Pod
```

Argo CD와 애플리케이션 Pod는 EKS Worker Node가 위치한 private subnet에서 실행된다. GitHub 동기화, 공개 이미지 pull, AWS 공개 API 호출이 필요한 실습 시간에는 NAT Gateway를 활성화한다.

```text
Argo CD Pod / EKS Worker Node (private subnet)
  -> NAT Gateway (실습 중 활성화)
      -> GitHub / Docker Hub / AWS Public API
```

## 3. Desired State와 Reconciliation

| 구분 | 역할 |
| --- | --- |
| Git Repository | Desired State를 선언적으로 관리하는 Source of Truth |
| EKS Cluster | 실제로 실행 중인 Actual State |
| Argo CD | Git 상태와 클러스터 상태의 차이를 감지하고 동기화하는 Reconciliation Controller |

Git Repository의 매니페스트가 변경되면 Argo CD가 변경을 감지해 Kubernetes API에 반영한다. 사용자가 `kubectl`로 클러스터 리소스를 직접 변경해 Git 상태와 차이가 발생하면, Argo CD가 설정된 동기화 정책에 따라 Desired State로 복구한다.

## 4. Argo CD Application 구성

Argo CD Application은 GitHub `main` 브랜치의 `kubernetes/app` 경로를 감시한다.

| 설정 | 값 | 의미 |
| --- | --- | --- |
| `repoURL` | `https://github.com/GYOUNG-ko/aws-devsecops-project.git` | GitOps 대상 GitHub Repository |
| `targetRevision` | `main` | 감시할 Branch |
| `path` | `kubernetes/app` | Kubernetes manifest 및 Kustomization 경로 |
| `server` | `https://kubernetes.default.svc` | Argo CD가 실행 중인 EKS Cluster |
| `namespace` | `default` | 애플리케이션 배포 Namespace |
| `CreateNamespace=true` | 활성화 | 대상 Namespace가 없으면 생성 |

`kubernetes/app/kustomization.yaml`은 아래 리소스를 배포 대상으로 선언한다.

- `deployment.yaml`
- `service.yaml`

## 5. 선택한 GitOps 방식

### Automated Sync

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

- `prune: true`: Git에서 삭제된 Argo CD 관리 리소스를 Kubernetes에서도 삭제한다.
- `selfHeal: true`: 사용자가 Kubernetes 리소스를 직접 변경해 Drift가 발생하면 Git의 선언 상태로 복구한다.

### 선택 이유

- 클러스터 직접 변경을 줄이고 Git을 배포 상태의 Source of Truth로 사용한다.
- Git commit과 Pull Request 이력을 통해 배포 변경을 추적할 수 있다.
- Argo CD가 지속적으로 상태를 비교하므로 일회성 `kubectl apply`보다 Drift를 줄일 수 있다.
- 향후 CI가 애플리케이션 이미지를 빌드하더라도, Kubernetes 배포 권한은 Argo CD에 집중할 수 있다.

### 대안과 선택하지 않은 이유

| 대안 | 선택하지 않은 이유 |
| --- | --- |
| 수동 `kubectl apply` | 변경 이력과 실제 클러스터 상태의 일관성을 사람이 계속 관리해야 한다. |
| CI Pipeline에서 `kubectl apply` | CI에 클러스터 배포 권한을 직접 부여해야 하며, 배포 이후 발생한 Drift를 지속적으로 복구하지 못한다. |

## 6. 배포 이미지 전략

EKS 및 GitOps 이관 단계에서는 이미지 공급망과 Kubernetes 배포 경로를 분리 검증하기 위해 공개 이미지 `nginx:1.27-alpine`을 임시 사용한다.

향후 CI 단계에서는 GitHub Actions가 실제 PMS 애플리케이션 이미지를 build하고 Amazon ECR에 push한다. 이후 Deployment의 이미지를 ECR URI와 고정된 이미지 태그 또는 digest로 교체한다.

## 7. Validation

### 7.1 초기 배포

| 항목 | 결과 |
| --- | --- |
| Worker Node | Ready |
| Deployment | `3/3 Ready` |
| Pod | Running / Ready |
| Service | ClusterIP |
| Endpoint | Pod IP 정상 등록 |
| Test Image | `nginx:1.27-alpine` |

### 7.2 Automated Sync

Git Repository에서 Deployment replica를 `2`에서 `3`으로 변경하고 `main` 브랜치에 push했다.

```text
Initial State: replicas 2
Git Change:   replicas 2 -> 3
Result:       Argo CD가 변경을 감지하고 Deployment를 replicas 3으로 동기화
```

검증 결과 Argo CD Application은 `Synced / Healthy` 상태가 되었고, Deployment는 `3/3 Ready` 상태를 확인했다.

### 7.3 Drift / Self-Heal

**Status: Pending (미검증)**

`selfHeal: true`는 Application에 설정되어 있지만, 실제 Drift 복구는 아직 검증하지 않았다. 아래 절차는 향후 검증 계획이며, 결과로 기록하지 않는다.

Git Desired State를 `replicas: 3`으로 유지한 상태에서 수동 변경을 수행한다.

```bash
kubectl scale deployment web-app --replicas=1
```

```text
Manual Change: Actual State 3 -> 1
Expected:      Argo CD가 Drift를 감지
Expected:      selfHeal 정책으로 Desired State 3 복구
```

향후 이 검증을 통해 Git 상태가 클러스터의 배포 기준이며, 직접 변경된 Actual State가 지속되지 않는지 확인한다.

## 8. Troubleshooting

### 8.1 Node maxPods 초과

#### Symptom

Argo CD 설치 후 일부 Pod는 Running 상태였으나 `argocd-application-controller`와 `argocd-server`가 Pending 상태로 유지되었다. Scheduler Event에는 다음 메시지가 표시되었다.

```text
0/1 nodes are available: 1 Too many pods.
```

#### Root Cause

단일 EKS Worker Node에 `kube-system`, 애플리케이션, Argo CD Pod가 집중되어 Node의 Pod scheduling capacity에 도달했다. 이 문제는 CPU 또는 Memory 부족이 아니라 Node가 배치 가능한 Pod 수의 한계가 원인이었다.

#### Resolution

Managed Node Group의 desired size를 `1`에서 `2`로 확장했다.

```hcl
node_min_size     = 1
node_max_size     = 2
node_desired_size = 2
```

#### Validation and Prevention

- Node 2개가 Ready 상태인지 확인한다.
- 기존 Pending Pod가 Running 상태로 전환됐는지 확인한다.
- Argo CD Component가 Ready 상태인지 확인한다.
- 새 구성요소를 배포하기 전 `maxPods`와 현재 Pod 수를 확인한다.

향후에는 Node 수 확장, 더 높은 Pod density를 지원하는 instance type, VPC CNI Prefix Delegation을 검토한다.

### 8.2 Empty Kustomization

#### Symptom

`kustomization.yaml`이 비어 있어 Argo CD가 배포할 리소스를 찾지 못했다.

#### Resolution

Deployment와 Service를 Kustomize resources로 등록했다.

```yaml
resources:
  - deployment.yaml
  - service.yaml
```

## 9. Security and Operation

- Git commit과 Pull Request를 통해 배포 변경 이력을 추적한다.
- Kubernetes 리소스의 수동 변경을 최소화하고, Argo CD가 Git 상태로 복구하도록 한다.
- 실습 중 private subnet의 outbound 통신이 필요할 때만 NAT Gateway를 활성화한다.
- 실습 종료 전 `enable_nat_gateway = false`로 변경하고 `terragrunt plan`에서 NAT Gateway, Elastic IP, private default route 삭제만 포함되는지 확인한 후 apply한다.
- NAT Gateway를 제거해도 EKS control plane, managed node EC2, ALB, EBS volume, ECR 이미지 저장 비용은 별도로 계속 발생할 수 있다.

## 10. Rollback

배포에 문제가 발생하면 Git에서 정상 동작했던 이전 commit으로 revert한다.

```text
Git revert
  -> GitHub main 반영
      -> Argo CD Sync
          -> 이전 Desired State 복구
```

## 11. 향후 운영 고려사항

### 11.1 Private Git Repository 인증

현재 GitHub Repository는 Private이며, Argo CD가 인증 없이 접근할 때 `authentication required: Repository not found` 오류가 발생했다. Repository 범위와 `Contents: Read-only` 권한으로 제한한 Fine-grained PAT를 Argo CD Repository Secret으로 등록해 해결했다. PAT은 Git 또는 YAML에 저장하지 않으며, 향후 GitHub App 또는 Secrets Manager/External Secrets 기반 Secret 관리를 검토한다.

### 11.2 ECR 이미지 전환

실제 PMS 이미지를 ECR에 push한 뒤 Deployment 이미지를 ECR URI와 고정된 태그 또는 digest로 교체한다. 이미지 변경은 Git Repository에서 관리하고 Argo CD가 동기화한다.

### 11.3 S3 Gateway Endpoint 비용 최적화

S3 Gateway Endpoint는 아직 구성하지 않았다. 향후 private route table에 S3 Gateway Endpoint를 추가하면 ECR 이미지 레이어 등 S3 트래픽을 NAT Gateway에서 우회할 수 있다. Gateway Endpoint 자체에는 추가 시간당 및 데이터 처리 비용이 없지만, GitHub, Docker Hub, STS, ECR API 통신을 대체하지는 못한다.

## 12. Conclusion

GitHub Repository를 Source of Truth로 사용하고, Argo CD가 EKS의 Actual State를 Git Desired State에 반영하는 Automated Sync 동작을 검증했다. Self-Heal은 설정되어 있으나 실제 Drift 복구 검증은 Pending 상태다. 또한 GitOps 구성요소 증가로 발생한 Node Pod scheduling capacity 문제를 Managed Node Group 확장으로 해결했다. 다음 단계에서는 Self-Heal 실제 검증, PMS 이미지의 ECR 전환, HTTPS 외부 공개 및 S3 Gateway Endpoint 기반 네트워크 비용 최적화를 진행한다.
