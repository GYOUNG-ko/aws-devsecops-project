include "<REDACTED_HCL_VALUE>" {
  path = find_in_parent_folders("<REDACTED_HCL_VALUE>")
}
terraform {
  source = "<REDACTED_HCL_VALUE>"
}
dependency "<REDACTED_HCL_VALUE>" {
  config_path = "<REDACTED_HCL_VALUE>"
}
dependency "<REDACTED_HCL_VALUE>" {
  config_path = "<REDACTED_HCL_VALUE>"
}
inputs = {
  database_security_group_id = dependency.rds.outputs.database_security_group_id
  eks_node_security_group_id = dependency.eks.outputs.node_security_group_id
}
