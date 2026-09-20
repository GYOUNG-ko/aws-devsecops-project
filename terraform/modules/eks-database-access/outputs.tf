output "ingress_rule_id" {
  value = aws_vpc_security_group_ingress_rule.postgres_from_eks.id
}
