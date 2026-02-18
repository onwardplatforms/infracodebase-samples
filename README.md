# Infracodebase Samples

Sample infrastructure projects for use with [Infracodebase](https://infracodebase.com) demos.

## Purpose

This repository contains deployable sample infrastructure that can be used to demonstrate Infracodebase capabilities:

- **ClickOps to Infrastructure-as-Code** - Import existing cloud resources into Terraform management
- **Resource Discovery** - Demonstrate how Infracodebase discovers and documents infrastructure
- **Live Demos** - Deploy real infrastructure, demonstrate the product, then destroy

## Available Samples

| Sample | Description | Cloud |
|--------|-------------|-------|
| [aws-vpc-stack](./samples/aws-vpc-stack) | VPC with public/private subnets, EC2, and optional RDS | AWS |

## Usage

Each sample is a standalone Terraform project. Navigate to the sample directory and follow its README.

```bash
cd samples/aws-vpc-stack
DEMO_ID=mytest ./demo.sh up
```

## Adding New Samples

1. Create a new folder under `samples/`
2. Include a README with deployment instructions
3. Tag all resources with `infracodebase_demo` for easy identification
4. Provide a helper script for easy deploy/destroy

## Cost Considerations

These samples are designed to be **deployed and destroyed quickly**. Some resources may incur costs:

- Default configurations use free tier eligible resources where possible
- Always destroy resources after demos to avoid charges
- Review each sample's README for specific cost information
