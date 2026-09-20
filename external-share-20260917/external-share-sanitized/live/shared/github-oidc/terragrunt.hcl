include "<REDACTED_HCL_VALUE>" {
  path   = find_in_parent_folders("<REDACTED_HCL_VALUE>")
  expose = true
}
terraform {
  source = "<REDACTED_HCL_VALUE>"
}
inputs = {
  tags = {
    Project   = include.root.locals.account.locals.project
    Scope     = "<REDACTED_HCL_VALUE>"
    ManagedBy = "<REDACTED_HCL_VALUE>"
  }
}
