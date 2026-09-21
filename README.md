# AWS DevSecOps Project

## Maintenance work areas

| Work | Workspace | Source / validation |
| --- | --- | --- |
| Infrastructure | [Infrastructure workspace](infrastructure.code-workspace) | `terraform/`, `live/` — `make validate-infra` |
| Development | [Development workspace](development.code-workspace) | `backend/`, `app/` — `make verify-app` |
| DevOps | [DevOps workspace](devops.code-workspace) | `.github/`, `devops/`, `argocd/`, `kubernetes/`, `atlantis/` |

See [team workflow](docs/operations/team-workflow.md), [IaC maintenance and migration](docs/operations/iac-maintenance.md), and [validation status](ASTRA_VALIDATION_STATUS.md). Existing source paths are preserved; workspaces provide role-based views of the same files. Before any live plan, reconcile the populated legacy Windows VPC state described in the migration runbook.



## PMS MVP Current Status

The repository now contains the local PMS read-only vertical slice:

- Static Web UI: `app/index.html` provides a Patch Portal table, loading/empty/error states, and metadata detail view.
- Backend: `backend/` is a Java 21 Spring Boot API using AWS SDK for Java v2.
- APIs: `GET /api/patches` and `GET /api/patches/metadata?key=...` are ready for private S3 objects under `patches/<product>/<version>/<filename>`.
- Credentials: the backend uses the AWS Default Credentials Provider Chain. Access keys and secrets must not be placed in source code or `application.yml`.
- AWS status: no AWS SSO login, Terraform apply, Terragrunt apply, or AWS resource changes were performed for this MVP step.

The repository also contains the next EKS deployment phase as code. It is prepared but not applied:

- `backend/Dockerfile` builds the Spring Boot application with Maven and runs it as a non-root user.
- `kubernetes/app` deploys the application on port 8080 with IRSA, health probes, resource limits, and an ALB Ingress.
- `live/dev/ecr` prepares an immutable, scan-on-push ECR repository.
- `.github/workflows/pms-ci.yml` tests and scans pull requests, then uses branch-restricted GitHub OIDC to publish `main` images and pin the Deployment to the resulting digest.
- `live/dev/github-actions-ecr` prepares the least-privilege OIDC role used only for the PMS ECR repository.
- `live/dev/rds` prepares private encrypted PostgreSQL with deletion protection, backups, an EKS-only security group, and a Secrets Manager connection secret.
- `live/dev/external-secrets` and `argocd/external-secrets.yaml` prepare the controller IRSA and pinned Helm chart that synchronize only the PMS database secret.
- Flyway owns the `download_requests` schema; local development uses H2 while the EKS `postgres` profile supports two application replicas.
- `live/dev/alb-controller` prepares the AWS Load Balancer Controller IRSA role; `argocd/aws-load-balancer-controller.yaml` installs the pinned Helm chart through Argo CD.
- The VPC module validates the public ALB subnet routes and can add an S3 Gateway Endpoint to private route tables.
- NAT is disabled in the current VPC input (`enable_nat_gateway = false`). EKS has a desired configuration in code; its actual deployment state has not been verified in this validation session. See [PMS on EKS activation runbook](docs/operations/pms-on-eks.md) for the reviewed activation order.

### Local development

Set only non-secret configuration before running the backend. A valid AWS credential source is required for actual S3 calls and will be configured after AWS SSO login.

```bash
export PMS_S3_BUCKET=<private-pms-bucket>
export PMS_S3_PREFIX=patches/
export AWS_REGION=ap-northeast-2
cd backend
mvn spring-boot:run
```

Open `http://localhost:8080/`. The Web page and REST API share one origin, so no permissive CORS policy is required.

### AWS validation pending

After AWS SSO login, validate the S3 bucket's Block Public Access, default encryption, bucket policy, and prefix-scoped IAM policy before running `terraform plan`. Do not run `terraform apply` or `terragrunt apply` until the plan has been reviewed and approved.

## PMS S3 and IRSA Phase A

The following code is prepared only. It has not created, changed, or deleted AWS resources.

### New bucket target state

`live/dev/pms-storage` defines a separate private bucket lifecycle because this repository previously had no Terraform-managed application bucket. The module creates the following target state when it is approved and applied:

- S3 Block Public Access: all four controls enabled.
- Object ownership: `BucketOwnerEnforced`, which disables ACL-based access.
- Default encryption: SSE-S3 (`AES256`).
- Bucket policy: explicit deny for requests that do not use HTTPS. This is a deny-only policy, not a public access grant.
- Destructive protection: `force_destroy = false` and `prevent_destroy = true`.

Patch objects must be uploaded under `patches/<product>/<version>/<filename>`. S3 prefixes are logical key paths, so Terraform does not create an empty `patches/` object.

### PMS Backend IRSA target state

The existing `irsa` module manages only the `aws-test/s3-reader` test identity. The independent `pms-irsa` module and `live/dev/pms-irsa` unit prepare the PMS Backend Role, consuming the bucket output from `pms-storage` and trusted only by:

```text
system:serviceaccount:default:pms-backend
```

The PMS Role allows only:

- `s3:ListBucket` when `s3:prefix` matches `patches/*`
- `s3:GetObject` on `arn:aws:s3:::<pms-bucket>/patches/*`

The prepared [ServiceAccount manifest](kubernetes/app/serviceaccount.yaml) is referenced by the current `pms-backend` Deployment through `serviceAccountName: pms-backend`. This confirms the code relationship only; live IRSA operation remains unverified.

### Required read-only checks after AWS SSO login

Before any plan, verify the target bucket situation:

1. Caller identity and configured Region.
2. Whether the configured PMS bucket already exists.
3. If it exists: location, Block Public Access, encryption, ownership controls, bucket policy, and object list.
4. If it already exists but is not in Terraform state, stop before planning creation. Decide whether to import it or choose a different bucket name; do not overwrite its configuration implicitly.

### Expected plan sequence after AWS SSO login

1. Run `terragrunt plan` in `live/dev/pms-storage` and review the bucket, public-access block, ownership controls, encryption, and HTTPS-only deny policy.
2. Run `terragrunt plan` in `live/dev/pms-irsa` and review the PMS Backend IAM Role, prefix-scoped IAM policy, and attachment. The test role remains separately managed in `live/dev/irsa`. Follow the migration runbook if an older state already owns PMS resources.
3. Report the complete diff, cost, security effect, and rollback path. Stop for approval before any apply.

## GitOps on AWS EKS

The nginx results below are historical records, not re-verified in this session. Current code prepares the PMS Deployment with 2 replicas. See [ASTRA Validation Status](ASTRA_VALIDATION_STATUS.md) for current validation evidence.

이 프로젝트는 Amazon EKS와 Argo CD를 이용해 GitHub Private Repository의 Kubernetes 매니페스트를 선언적으로 배포한다. Kustomize로 Deployment와 Service를 구성하고, Argo CD Automated Sync를 통해 Git 변경을 EKS에 자동 반영한다.

- GitHub Private Repository를 Git Desired State의 Source of Truth로 사용
- Argo CD Application이 `kubernetes/app` 경로의 Kustomize manifest를 동기화
- Deployment replicas `2 -> 3` 변경의 Automated Sync 실제 검증 완료
- `prune: true`, `selfHeal: true` 설정 사용 (`selfHeal` 실제 Drift 복구 검증은 Pending)

### Troubleshooting

- EKS Worker Node의 maxPods 제한으로 인한 Argo CD Pod scheduling failure
- Private GitHub Repository 인증 실패
- 빈 `kustomization.yaml`로 인한 manifest generation failure

상세 내용은 아래 문서에서 확인한다.

- [EKS Application Migration](docs/architecture/eks-application-migration.md)
- [Argo CD GitOps](docs/architecture/argocd-gitops.md)
- [INC-001: Argo CD Bootstrap Failures](docs/incidents/INC-001-argocd-bootstrap-failures.md)

### Rendering account-specific manifests

Public manifests do not commit the AWS account ID. Render bootstrap manifests with the active AWS identity before applying them:

```bash
python3 scripts/render_aws_account_template.py argocd/aws-load-balancer-controller.yaml | kubectl apply -f -
python3 scripts/render_aws_account_template.py argocd/external-secrets.yaml | kubectl apply -f -
python3 scripts/render_aws_account_template.py kubernetes/irsa-test/serviceaccount.yaml | kubectl apply -f -
```

Before running Terragrunt against AWS, export the active account once in your shell:

```bash
export AWS_PROFILE=dev
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)"
```

`live/account.hcl` derives the backend bucket from that value. Set `TF_STATE_BUCKET` only when the deployed backend bucket does not use the repository naming convention. The committed fallback account is an invalid sentinel so the existing state ownership preflight fails closed if `AWS_ACCOUNT_ID` is omitted.
