variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "demo_id" {
  description = "Unique identifier for this demo environment (used in naming and tagging)"
  type        = string
  default     = "infra"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.demo_id))
    error_message = "demo_id must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.60.0.0/16"
}

variable "create_rds" {
  description = "Whether to create an RDS PostgreSQL instance"
  type        = bool
  default     = true
}

variable "ec2_public_access" {
  description = "Place EC2 in public subnet with public IP (true = free tier, no NAT Gateway; false = private subnet with NAT Gateway, ~$32/mo)"
  type        = bool
  default     = true
}
