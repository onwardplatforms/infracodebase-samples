output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "ec2_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = aws_instance.backend.id
}

output "ec2_instance_private_ip" {
  description = "Private IP of the backend EC2 instance"
  value       = aws_instance.backend.private_ip
}

output "ec2_instance_public_ip" {
  description = "Public IP of the backend EC2 instance (only when ec2_public_access=true)"
  value       = var.ec2_public_access ? aws_instance.backend.public_ip : null
}

output "ec2_public_access" {
  description = "Whether EC2 is in public subnet (true = free tier, no NAT Gateway)"
  value       = var.ec2_public_access
}

output "rds_instance_arn" {
  description = "ARN of the RDS instance (if created)"
  value       = var.create_rds ? aws_db_instance.main[0].arn : null
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance (if created)"
  value       = var.create_rds ? aws_db_instance.main[0].endpoint : null
}

output "common_tag_key" {
  description = "The common tag key used for all resources"
  value       = "infracodebase_demo"
}

output "common_tag_value" {
  description = "The common tag value used for all resources"
  value       = var.demo_id
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "ssm_connect_command" {
  description = "Command to connect to the EC2 instance via SSM"
  value       = "aws ssm start-session --target ${aws_instance.backend.id} --region ${var.aws_region}"
}
