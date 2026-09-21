# PMS on EKS activation runbook

This runbook describes the expected deployment flow. It does not authorize or perform an AWS apply.

## Traffic and identity flow

```text
Internet
  -> internet-facing ALB in two tagged public subnets
  -> HTTP listener and Kubernetes Ingress rule
  -> IP target group
  -> pms-backend ClusterIP Service:80
  -> pms-backend Pod:8080 in a private subnet
  -> S3 through the S3 Gateway Endpoint using the Pod's IRSA role
```

The ALB public subnets must have `kubernetes.io/role/elb=1` and a default route to the VPC Internet Gateway. The VPC module validates that at least two Availability Zones are represented and that every selected public subnet route table has the Internet Gateway default route.

NAT is not part of the inbound ALB path. It is required temporarily for private nodes and Pods to reach GitHub or public registries and may be required for AWS public APIs until the appropriate VPC interface endpoints are present. S3 traffic uses the Gateway Endpoint and does not require NAT.

## Required order

First complete the [State ownership preflight and migration review](iac-maintenance.md). The populated legacy Windows VPC State currently blocks live activation. The steps below describe the post-resolution sequence.

1. Log in through AWS SSO and verify the account and Region.
2. Run and review `terragrunt plan` in `live/dev/vpc`. For lab activation, set `enable_nat_gateway = true` before planning. The plan should add NAT/EIP/private default routes and the S3 Gateway Endpoint.
3. Apply the reviewed VPC plan only after explicit approval.
4. Plan/apply `live/dev/eks`.
5. Plan/apply `live/dev/ecr`, build `backend/Dockerfile` from the repository root, scan it, and push immutable tag `v0.1.0`.
6. Review `live/shared/github-oidc` first, then `live/dev/github-actions-ecr`. The shared unit owns the account GitHub OIDC provider; the application unit consumes its ARN. If an existing provider is managed elsewhere, resolve its ownership under the migration runbook before any import or creation.
7. Plan/apply `live/dev/alb-controller` to create the controller IRSA role.
8. Install Argo CD, then render and apply `argocd/aws-load-balancer-controller.yaml` with `python3 scripts/render_aws_account_template.py argocd/aws-load-balancer-controller.yaml | kubectl apply -f -`. Wait until its Deployment is Available.
9. Plan/apply `live/dev/rds` for private PostgreSQL, the database security group and `dev/pms/database` Secret, then `live/dev/eks-database-access` for the EKS-only ingress rule. The DB unit no longer depends on the cluster. Review monthly RDS cost and deletion protection before approval.
10. Plan/apply `live/dev/external-secrets`, then render and apply `argocd/external-secrets.yaml` with `python3 scripts/render_aws_account_template.py argocd/external-secrets.yaml | kubectl apply -f -`. Wait for the controller and its CRDs to become ready.
11. Create the `pms-auth` Secret through an approved secret-management path. `kubernetes/app/secret.example.yaml` documents the required keys and must not be applied with placeholder values.
12. Plan/apply `live/dev/pms-storage` and `live/dev/pms-irsa`, then verify the ServiceAccount role ARN. The separate `live/dev/irsa` test unit is optional for application activation. Resolve the recorded deleted-bucket drift and data recovery intent before recreating storage.
13. Apply `argocd/web-app-dev.yaml` and verify `ClusterSecretStore`, `ExternalSecret`, generated `pms-database` Secret, Ingress, target health, and Pod logs.

## GitHub Actions image flow

`.github/workflows/pms-ci.yml` runs tests, builds the image, and blocks high or critical Trivy findings on pull requests. A successful `main` run assumes `github-actions-pms-ecr` through GitHub OIDC, pushes an immutable `sha-<commit>` tag, resolves the ECR digest, and commits that digest to the Deployment with `[skip ci]`.

The deployment role is restricted to `GYOUNG-ko/aws-devsecops-project` on `refs/heads/main` and to the `pms-backend` ECR repository. It has no Terraform or EKS mutation permission. The workflow needs repository `contents: write` permission to commit the digest; if `main` branch protection rejects bot pushes, replace that step with an approved pull-request workflow.

## Preflight checks

```bash
kubectl kustomize kubernetes/app
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get deployment -n external-secrets external-secrets
kubectl get clustersecretstore aws-secrets-manager
kubectl get externalsecret -n default pms-database
kubectl get ingress pms-backend
kubectl get targetgroupbinding
kubectl get pods -l app=pms-backend
kubectl get endpointslice -l kubernetes.io/service-name=pms-backend
```

The EKS Deployment uses the `postgres` Spring profile and two replicas. Flyway applies the database schema before Hibernate validates it. External Secrets reads only `dev/pms/database` and materializes the `pms-database` Kubernetes Secret. Local development continues to use H2.

The initial RDS password is generated by Terraform and therefore exists as sensitive data in encrypted remote Terraform state as well as Secrets Manager. Restrict state-bucket access accordingly. Before production, provision separate migration and application database roles and enable an approved rotation strategy rather than using the initial administrator account from the application.

## Known production gaps

- Add ACM, HTTPS listener, HTTP-to-HTTPS redirect, DNS, and a restricted inbound policy.
- Replace local Basic Auth secrets with the chosen identity and secret-management system.
- Promote the dev RDS configuration to Multi-AZ and use separate least-privilege database roles before production.
- Add application metrics, centralized logs, alerts, and autoscaling.
- Replace the release tag with an image digest after the first ECR push.
