include "<REDACTED_HCL_VALUE>" {
  path = find_in_parent_folders("<REDACTED_HCL_VALUE>")
}

locals {
  env         = read_terragrunt_config(find_in_parent_folders("<REDACTED_HCL_VALUE>"))
  common_tags = local.env.locals.tags
}

terraform {
  source = "<REDACTED_HCL_VALUE>"
}

inputs = {
  name = "<REDACTED_HCL_VALUE>"
  /*
  vpc_cidr = "<REDACTED_HCL_VALUE>"

  availability_zones = [
    "<REDACTED_HCL_VALUE>",
    "<REDACTED_HCL_VALUE>"
  ]

  public_subnet_cidrs = [
    "<REDACTED_HCL_VALUE>",
    "<REDACTED_HCL_VALUE>"
  ]

  private_subnet_cidrs = [
    "<REDACTED_HCL_VALUE>",
    "<REDACTED_HCL_VALUE>"
  ]
  */

  # 실습 중 private subnet의 outbound 연결을 위해 활성화
  # 실습 종료 시 false로 변경, terragrunt apply, NAT Gateway & EIP 제거
  #enable_nat_gateway = true
  enable_nat_gateway = false

  # S3 traffic remains private even when NAT is disabled.
  enable_s3_gateway_endpoint = true

  tags = local.common_tags
}
