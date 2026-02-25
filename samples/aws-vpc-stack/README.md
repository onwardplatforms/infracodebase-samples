# AWS VPC Stack

Sample AWS VPC environment with EC2 and RDS for demo purposes. Deploy, test, and destroy.

## Purpose

This repository provides working Terraform code to stand up a complete AWS VPC stack for demonstration purposes. It's designed to be:

- **Deployed quickly** for live demos
- **Tested with Infracodebase** to demonstrate ClickOps-to-Infrastructure-as-Code workflows
- **Destroyed immediately** after successful demo completion

Use cases include demonstrating:
- Importing existing AWS resources into Terraform management
- Converting manually-created infrastructure to IaC
- AWS resource discovery and documentation

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                            VPC                                  │
│                       (10.60.0.0/16)                            │
│                                                                 │
│   ┌─────────────────────┐     ┌─────────────────────┐          │
│   │   Public Subnet 1   │     │   Public Subnet 2   │          │
│   │    (10.60.0.0/24)   │     │    (10.60.1.0/24)   │          │
│   │        AZ-a         │     │        AZ-b         │          │
│   │                     │     │                     │          │
│   │  ┌─────────────┐    │     │                     │          │
│   │  │ NAT Gateway │    │     │                     │          │
│   │  └─────────────┘    │     │                     │          │
│   └─────────────────────┘     └─────────────────────┘          │
│             │                                                   │
│             │ (private mode only)                               │
│             ▼                                                   │
│   ┌─────────────────────┐     ┌─────────────────────┐          │
│   │  Private Subnet 1   │     │  Private Subnet 2   │          │
│   │   (10.60.10.0/24)   │     │   (10.60.11.0/24)   │          │
│   │        AZ-a         │     │        AZ-b         │          │
│   │                     │     │                     │          │
│   │  ┌─────────────┐    │     │  ┌─────────────┐    │          │
│   │  │ EC2 Backend │    │     │  │     RDS     │    │          │
│   │  │  (t2.micro) │    │     │  │  PostgreSQL │    │          │
│   │  └─────────────┘    │     │  └─────────────┘    │          │
│   └─────────────────────┘     └─────────────────────┘          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Resources Created

| Resource | Description |
|----------|-------------|
| VPC | Virtual Private Cloud with DNS support |
| Subnets | 2 public + 2 private across 2 AZs |
| Internet Gateway | For public subnet internet access |
| NAT Gateway | For private subnet outbound access (optional) |
| Route Tables | Public and private routing |
| Security Groups | Backend VM and RDS access rules |
| IAM Role | SSM access for EC2 (no SSH keys needed) |
| EC2 Instance | t2.micro Amazon Linux 2023 |
| RDS PostgreSQL | db.t3.micro with 20GB storage (optional) |

## Quick Start

### Prerequisites

- [Terraform](https://terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- AWS account with permissions to create VPC, EC2, RDS, IAM resources

### Deploy

```bash
# From repo root
make aws-vpc

# Or directly
cd samples/aws-vpc-stack
terraform init && terraform apply
```

### Connect to EC2

```bash
aws ssm start-session --target <instance-id> --region us-east-1
```

### Destroy

```bash
make aws-vpc-destroy
```

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DEMO_ID` | Yes | - | Unique identifier (lowercase, numbers, hyphens) |
| `AWS_REGION` | No | us-east-1 | AWS region for deployment |
| `EC2_PUBLIC_ACCESS` | No | false | Place EC2 in public subnet (free tier) |
| `CREATE_RDS` | No | true | Create RDS PostgreSQL instance |
| `TF_VAR_FILE` | No | - | Path to additional tfvars file |

### Terraform Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `demo_id` | (required) | Unique demo identifier |
| `aws_region` | us-east-1 | AWS region |
| `vpc_cidr` | 10.60.0.0/16 | VPC CIDR block |
| `create_rds` | true | Create RDS instance |
| `ec2_public_access` | true | EC2 in public subnet |

## Cost Considerations

| Deployment Mode | Monthly Cost (approx) |
|-----------------|----------------------|
| `ec2_public_access=true` (default) | **Free tier eligible** |
| `ec2_public_access=false` | ~$32/mo (NAT Gateway) |

The default configuration is free tier eligible. Set `EC2_PUBLIC_ACCESS=false` for production-like private networking (adds NAT Gateway cost).

**Destroy resources when not in use to minimize costs.**

## Tags

All resources are tagged for easy identification:

| Tag Key | Value |
|---------|-------|
| `infracodebase_demo` | `<your-demo-id>` |
| `project` | `samples-aws-vpc-stack` |
| `managed_by` | `terraform` |
| `environment` | `development` |
| `purpose` | `demo` |

### Finding Resources in AWS Console

Filter by tag: `infracodebase_demo = <your-demo-id>`

## Outputs

After deployment, the following outputs are available:

```bash
terraform output
# or
DEMO_ID=mytest ./demo.sh outputs
```

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC identifier |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `ec2_instance_id` | EC2 instance identifier |
| `ec2_instance_private_ip` | EC2 private IP address |
| `ec2_instance_public_ip` | EC2 public IP (if ec2_public_access=true) |
| `rds_instance_arn` | RDS ARN (if create_rds=true) |
| `rds_endpoint` | RDS connection endpoint |
| `ssm_connect_command` | Ready-to-use SSM session command |
| `common_tag_key` | Tag key for filtering resources |
| `common_tag_value` | Tag value (demo_id) |

## Security Notes

- EC2 uses SSM Session Manager (no SSH keys or open ports)
- RDS password is randomly generated and stored only in Terraform state
- IMDSv2 is required on EC2 instances
- EBS volumes are encrypted
- No secrets in code or outputs

## Manual Terraform Commands

```bash
# Initialize
terraform init

# Plan
terraform plan -var="demo_id=mytest"

# Apply
terraform apply -var="demo_id=mytest"

# Apply with free tier settings
terraform apply -var="demo_id=mytest" -var="ec2_public_access=true"

# Destroy
terraform destroy -var="demo_id=mytest"
```

## Troubleshooting

### SSM Session Manager not connecting

Ensure the EC2 instance has internet access:
- If `ec2_public_access=false`: NAT Gateway must be created and healthy
- If `ec2_public_access=true`: Instance must have public IP

Check IAM role has `AmazonSSMManagedInstanceCore` policy attached.

### Permission errors

The IAM user/role running Terraform needs permissions for:
- EC2 (VPC, subnets, instances, security groups)
- IAM (roles, instance profiles, policy attachments)
- RDS (instances, subnet groups)

For demos, `AdministratorAccess` is simplest.

## License

MIT
