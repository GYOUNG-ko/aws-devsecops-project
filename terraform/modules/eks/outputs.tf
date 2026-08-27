# 생성한 EKS Cluster 정보를 다른 구성에서 사용할 수 있도록 공개
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

# kubectl 등이 접근할 Kubernetes API Endpoint
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

# EKS Cluster Security Group
output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}
