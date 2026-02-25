# Infracodebase Samples

Sample infrastructure projects for use with [Infracodebase](https://infracodebase.com) demos.

## Purpose

This repository contains deployable sample infrastructure that can be used to demonstrate Infracodebase capabilities:

- **ClickOps to Infrastructure-as-Code** - Import existing cloud resources into Terraform management
- **Resource Discovery** - Demonstrate how Infracodebase discovers and documents infrastructure
- **Live Demos** - Deploy real infrastructure, demonstrate the product, then destroy

## Available Samples

### AWS

| Sample | Description |
|--------|-------------|
| [aws-remote-state-bootstrap](./samples/aws-remote-state-bootstrap) | S3 + DynamoDB for Terraform remote state |
| [aws-vpc-stack](./samples/aws-vpc-stack) | VPC with public/private subnets, EC2, and optional RDS |

### Azure

| Sample | Description |
|--------|-------------|
| [azure-bootstrap](./samples/azure-bootstrap) | Storage Account + Key Vault for Terraform remote state and shared secrets |
| [azure-webapp-stack](./samples/azure-webapp-stack) | App Service + PostgreSQL + Storage Account |

## Deployment Order

Bootstrap stacks should be deployed first, then application stacks:

```
AWS:   aws-remote-state-bootstrap  -->  aws-vpc-stack
Azure: azure-bootstrap             -->  azure-webapp-stack
```

## Usage

All samples have sensible defaults and require no configuration. Use the root Makefile:

```bash
# Deploy everything
make all-up

# Or deploy by cloud
make aws-up        # bootstrap + vpc stack
make azure-up      # bootstrap + webapp stack

# Destroy
make aws-down
make azure-down

# Individual stacks
make aws-bootstrap
make aws-vpc
make azure-bootstrap
make azure-webapp
```

Or run Terraform directly in any sample directory:

```bash
cd samples/azure-bootstrap
terraform init && terraform apply
```

## Tagging Convention

All samples use a consistent tagging scheme for resource identification:

| Tag Key | Value | Description |
|---------|-------|-------------|
| `infracodebase_demo` | `<demo_id>` | Links all resources across stacks for a given demo |
| `project` | `samples-<stack-name>` | Identifies which sample created the resource |
| `managed_by` | `terraform` | Indicates IaC management |
| `environment` | `development` | Environment classification |
| `purpose` | `demo` | Marks resources as demo infrastructure |

Filter by `infracodebase_demo = <your-demo-id>` in the AWS or Azure console to find all resources for a demo.

## Adding New Samples

1. Create a new folder under `samples/`
2. Include a README with deployment instructions
3. Tag all resources with the standard tagging convention above
4. Default all variables so no tfvars file is needed
5. Add targets to the root Makefile

## Cost Considerations

These samples are designed to be **deployed and destroyed quickly**. Some resources may incur costs:

- Default configurations use low-cost tiers where possible
- Always destroy resources after demos to avoid charges
- Review each sample's README for specific cost information
