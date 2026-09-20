include "root" {
  path = find_in_parent_folders("root.hcl")
}
terraform {
  source = "../../../terraform/modules/eks-database-access"
}
dependency "eks" {
  config_path = "../eks"
}
dependency "rds" {
  config_path = "../rds"
}
inputs = {
  database_security_group_id = dependency.rds.outputs.database_security_group_id
  eks_node_security_group_id = dependency.eks.outputs.node_security_group_id
}
