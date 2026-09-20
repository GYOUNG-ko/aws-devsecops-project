include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}
terraform {
  source = "../../../terraform/modules/github-oidc"
}
inputs = {
  tags = {
    Project   = include.root.locals.account.locals.project
    Scope     = "account"
    ManagedBy = "Terraform"
  }
}
