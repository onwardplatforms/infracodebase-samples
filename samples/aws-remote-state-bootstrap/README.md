# AWS Remote State Bootstrap

Terraform remote state infrastructure (S3 + DynamoDB) for shared use across AWS demo stacks.

## Purpose

Creates the backend infrastructure needed to store Terraform state remotely. Deploy this first, then configure other AWS stacks to use it as their backend.

## Resources Created

| Resource | Description |
|----------|-------------|
| S3 Bucket | Versioned, KMS-encrypted bucket for Terraform state files |
| DynamoDB Table | Pay-per-request table for state locking |
| Resource Group | Tag-based group for easy resource discovery |

## Quick Start

### Prerequisites

- [Terraform](https://terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials

### Deploy

```bash
# From repo root
make aws-bootstrap

# Or directly
cd samples/aws-remote-state-bootstrap
terraform init && terraform apply
```

### Use in Other Stacks

After deploying, copy the backend config into your other stacks:

```bash
terraform output backend_config
```

### Destroy

```bash
make aws-bootstrap-destroy
```

**Note:** The S3 bucket has versioning enabled. If destroy fails, you may need to empty the bucket first (including delete markers and old versions).

## Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `demo_id` | Yes | - | Unique identifier (lowercase, numbers, hyphens) |
| `aws_region` | No | `us-east-1` | AWS region |
| `bucket_name` | No | `demo-<demo_id>-terraform-state` | Custom S3 bucket name |
| `dynamodb_table_name` | No | `demo-<demo_id>-terraform-locks` | Custom DynamoDB table name |

## Outputs

| Output | Description |
|--------|-------------|
| `s3_bucket_name` | Name of the S3 state bucket |
| `s3_bucket_arn` | ARN of the S3 state bucket |
| `dynamodb_table_name` | Name of the DynamoDB lock table |
| `dynamodb_table_arn` | ARN of the DynamoDB lock table |
| `backend_config` | Ready-to-use backend configuration block |
| `resource_group_name` | AWS Resource Group for discovery |

## Tags

All resources are tagged via provider `default_tags`:

| Tag Key | Value |
|---------|-------|
| `infracodebase_demo` | `<your-demo-id>` |
| `project` | `samples-aws-remote-state-bootstrap` |
| `managed_by` | `terraform` |
| `environment` | `development` |
| `purpose` | `demo` |

## Cost

All resources are free tier eligible or pay-per-request with negligible cost for demo usage.
