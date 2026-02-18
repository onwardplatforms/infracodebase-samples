output "resource_group_name" {
  description = "Name of the AWS Resource Group containing all bootstrap resources"
  value       = aws_resourcegroups_group.main.name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.locks.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.locks.arn
}

output "backend_config" {
  description = "Backend configuration block to add to other Terraform stacks"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.state.id}"
        key            = "<STACK_NAME>/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.locks.name}"
        encrypt        = true
      }
    }
  EOT
}
