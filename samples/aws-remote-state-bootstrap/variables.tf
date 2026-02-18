variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "demo_id" {
  description = "Unique identifier for this demo environment (used in naming and tagging)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.demo_id))
    error_message = "demo_id must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "bucket_name" {
  description = "Name for the S3 state bucket. If not set, defaults to demo-<demo_id>-terraform-state."
  type        = string
  default     = ""
}

variable "dynamodb_table_name" {
  description = "Name for the DynamoDB lock table. If not set, defaults to demo-<demo_id>-terraform-locks."
  type        = string
  default     = ""
}
