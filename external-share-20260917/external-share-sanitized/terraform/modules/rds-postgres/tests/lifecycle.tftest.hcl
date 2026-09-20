mock_provider "aws" {
  mock_resource "aws_security_group" {
    defaults = { id = "sg-33333333" }
  }
}
mock_provider "random" {}
variables {
  identifier         = "test-pms"
  database_name      = "pms"
  master_username    = "pmsadmin"
  private_subnet_ids = ["subnet-11111111", "subnet-22222222"]
  vpc_id             = "vpc-11111111"
  secret_name        = "test/pms/database"
}
run "database_plans_without_cluster" {
  command = plan
  assert {
    condition     = aws_db_instance.this.publicly_accessible == false && aws_db_instance.this.storage_encrypted && aws_db_instance.this.deletion_protection && aws_db_instance.this.skip_final_snapshot == false
    error_message = "Separating connectivity must preserve database privacy and recovery protection."
  }
}
