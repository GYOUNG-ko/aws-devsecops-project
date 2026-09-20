output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = data.aws_subnets.private.ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = data.aws_subnets.public.ids
}

output "private_route_table_ids" {
  description = "Route tables associated with private subnets"
  value       = sort(tolist(local.private_route_table_ids))
}

output "s3_gateway_endpoint_id" {
  description = "S3 Gateway Endpoint ID, or null when disabled"
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

