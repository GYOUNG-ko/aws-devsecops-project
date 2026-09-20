module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.25.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  # 기존 VPC의 Private Subnet 사용
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Kubernetes API 접근
  # 로컬 PC -> Public Endpoint
  endpoint_public_access = true
  # Worker Node -> Private Endpoint
  endpoint_private_access = true

  # Cluster 생성자에게 SSO Role Kubernetes 관리자 접근 부여
  enable_cluster_creator_admin_permissions = true

  # IRSA, IAM OIDC Provider
  enable_irsa = true

  addons = {
    # Kubernetes 내부 DNS
    coredns = {}
    # Kubernetes Service Network 처리
    kube-proxy = {}

    # Pod Networking - Pod에 VPC IP 할당
    vpc-cni = {
      before_compute = true
    }

    # eks-pod-identity-agent = {}
  }

  eks_managed_node_groups = {
    default = {
      name = "${var.cluster_name}-mng"

      # Amazon Linux 2023 / x86_64
      ami_type = "AL2023_x86_64_STANDARD"

      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size
    }
  }

  tags = var.tags


}