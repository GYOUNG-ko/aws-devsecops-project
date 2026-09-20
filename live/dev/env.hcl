locals {
  environment             = "dev"
  cluster_name            = "dev-eks"
  pms_patch_bucket_name   = "pms-patch"
  pms_patch_object_prefix = "patches/"
  tags = {
    Project     = "aws-devsecops-project"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
