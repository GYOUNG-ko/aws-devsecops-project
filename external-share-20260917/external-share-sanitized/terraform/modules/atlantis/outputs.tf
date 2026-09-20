output "instance_id" {
  description = "Atlantis EC2 instance ID"
  value       = aws_instance.atlantis.id
}

output "private_ip" {
  description = "Private IP address of Atlantis EC2"
  value       = aws_instance.atlantis.private_ip
}

output "security_group_id" {
  description = "Security group ID of Atlantis EC2"
  value       = aws_security_group.atlantis.id
}

output "iam_role_name" {
  description = "IAM role name attached to Atlantis EC2"
  value       = aws_iam_role.atlantis.name
}
