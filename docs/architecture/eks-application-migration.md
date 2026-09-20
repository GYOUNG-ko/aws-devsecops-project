# EKS Application Migration

> Historical lab record: nginx / web-app / 3 replicas and the runtime results below describe the earlier exercise. Current local code prepares PMS Backend with 2 replicas. Actual AWS state has not been verified in this session. See the [PMS activation runbook](../operations/pms-on-eks.md) and [ASTRA Validation Status](../../ASTRA_VALIDATION_STATUS.md).

## 1. 목적

기존 로컬 Kubernetes 환경에서 검증한 애플리케이션 구조를 Amazon EKS로 이관한다. 이 단계의 목표는 실제 애플리케이션 CI/CD와 이미지 공급망을 완성하는 것이 아니라, Kubernetes Deployment와 Service가 EKS에서 정상 동작하는지 분리해 검증하는 것이다.

이미지 공급망의 영향을 배제하기 위해 임시 공개 이미지 `nginx:1.27-alpine`을 사용했다. 실제 PMS 애플리케이션 이미지는 CI와 Amazon ECR 구성이 완료된 후 교체한다.

## 2. 애플리케이션 구성

애플리케이션 매니페스트는 다음 경로에서 관리한다.

```text
project/kubernetes/app/
├── deployment.yaml
├── service.yaml
└── kustomization.yaml
```

| 리소스 | 역할 | 현재 설정 |
| --- | --- | --- |
| Deployment | web-app Pod의 선언 상태 관리 | replicas 3, `nginx:1.27-alpine` |
| Service | Pod 집합에 대한 내부 네트워크 진입점 제공 | `ClusterIP`, port 80 |
| Kustomization | Deployment와 Service를 하나의 배포 단위로 구성 | 두 매니페스트를 resources로 선언 |

## 3. Kustomize 구성

`project/kubernetes/app/kustomization.yaml`은 Argo CD가 배포할 리소스를 명시한다.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
```

로컬 manifest 생성 검증은 `project/` 상위 경로에서 다음 명령으로 수행한다.

```powershell
kubectl kustomize .\project\kubernetes\app
```

## 4. 관찰 → 진단 → 해결 → 검증

### 관찰

Argo CD가 Private GitHub Repository의 `project/kubernetes/app` 경로를 읽어 EKS에 배포해야 했다. Kustomization 파일은 존재했지만 초기에는 비어 있어 manifest generation이 실패했다.

### 진단

Argo CD Application 상태와 Kustomize 오류를 확인한 결과, 컨테이너 이미지 또는 EKS 런타임 문제가 아니라 배포 대상 리소스가 Kustomization에 선언되지 않은 것이 원인이었다.

### 해결

`project/kubernetes/app/kustomization.yaml`에 `deployment.yaml`, `service.yaml`을 resources로 등록했다. 이후 Git에 반영하고 Argo CD hard refresh를 수행했다.

### 검증 완료

| 항목 | 검증 결과 |
| --- | --- |
| Runtime | AWS EKS |
| Deployment | `web-app` |
| Desired replicas | 3 |
| READY | `3/3` |
| Service | ClusterIP |
| Image | `nginx:1.27-alpine` |
| Argo CD Automated Sync | Git의 replicas `2 -> 3` 변경 자동 반영 확인 |

## 5. 설계 판단

| 작업 | 선택한 방식 | 대안 | 선택 이유 | 비용 영향 | 보안/운영 영향 | 완료 검증 방법 | 롤백 방법 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| EKS 애플리케이션 이관 | 임시 공개 nginx 이미지로 Deployment/Service 분리 검증 | 실제 PMS 이미지와 CI/ECR을 한 번에 구축 | Kubernetes 이관 실패와 이미지 공급망 실패를 분리해 진단하기 위함 | 이미지 pull에 따른 네트워크 비용 가능 | 공개 이미지 버전은 고정하고, 실제 서비스 이미지는 이후 ECR로 전환 | Deployment `3/3 Ready`, Service Endpoint 등록 | Git에서 이전 manifest로 revert 후 Argo CD Sync |
| Manifest 조립 | Kustomize resources 사용 | 개별 `kubectl apply` | 선언형 배포 단위를 GitOps 경로에서 일관되게 관리 | 추가 비용 없음 | 배포 대상 파일 누락을 명시적으로 관리 | `kubectl kustomize .\project\kubernetes\app` | Kustomization의 이전 Git commit으로 revert |

## 6. 향후 이미지 흐름

```text
Application Source
  -> GitHub Actions
      -> Docker Build
          -> Vulnerability Scan
              -> Amazon ECR
                  -> GitOps Repository
                      -> Argo CD
                          -> EKS
```

향후에는 Deployment의 `nginx:1.27-alpine`을 Amazon ECR 이미지 URI로 교체하고, 재현성을 위해 변동 가능한 태그 대신 고정 태그 또는 image digest 사용을 검토한다.

## 7. 미검증 및 다음 단계

- 실제 PMS 애플리케이션 이미지의 GitHub Actions build 및 vulnerability scan
- Amazon ECR push 및 ECR 이미지로 Deployment 교체
- Ingress, ALB, ACM, Route 53을 이용한 HTTPS 외부 공개
- 실제 애플리케이션의 readiness/liveness probe와 관측성 구성

위 항목은 이 문서의 EKS Deployment/Service 이관 검증 범위에 포함되지 않으며, 아직 완료로 기록하지 않는다.
