#------------------------------------------------------------------------------
# Resource Group (tag-based, similar to Azure Resource Groups)
#------------------------------------------------------------------------------

resource "aws_resourcegroups_group" "main" {
  name        = "${local.name_prefix}-tfstate-resources"
  description = "Terraform remote state resources for demo environment ${var.demo_id}"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        {
          Key    = "infracodebase_demo"
          Values = [var.demo_id]
        },
        {
          Key    = "project"
          Values = ["samples-aws-remote-state-bootstrap"]
        }
      ]
    })
  }

  tags = {
    Name = "${local.name_prefix}-tfstate-resources"
  }
}

#------------------------------------------------------------------------------
# S3 Bucket for Terraform State
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "state" {
  bucket = local.bucket_name

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = local.bucket_name
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#------------------------------------------------------------------------------
# DynamoDB Table for State Locking
#------------------------------------------------------------------------------

resource "aws_dynamodb_table" "locks" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = local.dynamodb_table_name
  }
}
