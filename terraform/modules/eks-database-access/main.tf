resource "aws_vpc_security_group_ingress_rule" "postgres_from_eks" {
  security_group_id            = var.database_security_group_id
  referenced_security_group_id = var.eks_node_security_group_id
  description                  = "PostgreSQL from EKS nodes and default Pod ENIs"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

