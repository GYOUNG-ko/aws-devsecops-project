mock_provider "aws" {}
variables {
  database_security_group_id = "sg-11111111"
  eks_node_security_group_id = "sg-22222222"
}
run "only_postgres_from_selected_cluster" {
  command = plan
  assert {
    condition     = aws_vpc_security_group_ingress_rule.postgres_from_eks.from_port == 5432 && aws_vpc_security_group_ingress_rule.postgres_from_eks.to_port == 5432 && aws_vpc_security_group_ingress_rule.postgres_from_eks.ip_protocol == "tcp" && aws_vpc_security_group_ingress_rule.postgres_from_eks.referenced_security_group_id == "sg-22222222" && aws_vpc_security_group_ingress_rule.postgres_from_eks.security_group_id == "sg-11111111"
    error_message = "Connectivity must not broaden database access when moved out of the data unit."
  }
}
