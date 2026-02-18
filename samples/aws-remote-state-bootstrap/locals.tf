locals {
  name_prefix         = "demo-${var.demo_id}"
  bucket_name         = var.bucket_name != "" ? var.bucket_name : "${local.name_prefix}-terraform-state"
  dynamodb_table_name = var.dynamodb_table_name != "" ? var.dynamodb_table_name : "${local.name_prefix}-terraform-locks"
}
