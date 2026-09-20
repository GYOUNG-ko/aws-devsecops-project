# Dev 환경 비용 및 NAT Gateway 운영 정책

## NAT 활성화

- EKS, Atlantis, ECR image pull, Terraform 실행 중에는 `enable_nat_gateway = true`를 사용한다.
- private subnet의 EKS node와 Atlantis EC2가 GitHub, AWS API, ECR 및 Terraform provider registry에 접근할 수 있다.

## NAT 비활성화

- 실습 종료 후 `enable_nat_gateway = false`로 변경한다.
- `terragrunt plan`으로 NAT Gateway, Elastic IP, private default route 삭제만 포함되는지 확인한 뒤 apply한다.
- 실행 중인 배포, 이미지 pull, Atlantis 작업이 있을 때는 비활성화하지 않는다.

## 비용 주의

- NAT Gateway를 비활성화해도 EKS control plane, managed node EC2, ALB, EBS volume, ECR 이미지 저장 비용은 계속 발생한다.
