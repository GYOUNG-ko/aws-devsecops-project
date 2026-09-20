locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../terraform/modules/rds-postgres"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  identifier         = "${local.env.locals.environment}-pms-postgres"
  database_name      = "pms"
  master_username    = "pmsadmin"
  instance_class     = "db.t4g.micro"
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  vpc_id             = dependency.vpc.outputs.vpc_id
  secret_name        = "${local.env.locals.environment}/pms/database"
  multi_az           = false
  tags               = local.env.locals.tags
}
