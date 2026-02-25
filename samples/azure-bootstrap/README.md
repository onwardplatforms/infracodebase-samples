# Azure Bootstrap

Terraform remote state and shared secrets infrastructure for Azure demo stacks.

## Purpose

Creates the foundation infrastructure needed by all Azure stacks: a Storage Account for Terraform remote state and a Key Vault for shared secrets. Deploy this first, then configure other Azure stacks to use it.

## Resources Created

| Resource | Description |
|----------|-------------|
| Resource Group | Container for all bootstrap resources |
| Storage Account | LRS storage with TLS 1.2 minimum |
| Blob Container | `tfstate` container for Terraform state files |
| Key Vault | Standard SKU, RBAC-authorized, for shared secrets |
| RBAC Assignments | Deployer gets Storage Blob Data Contributor + Key Vault Secrets Officer |

## Quick Start

### Prerequisites

- [Terraform](https://terraform.io/downloads) >= 1.0
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) logged in (`az login`)

### Deploy

```bash
# From repo root
make azure-bootstrap

# Or directly
cd samples/azure-bootstrap
terraform init && terraform apply
```

### Use in Other Stacks

After deploying, get the backend config and Key Vault ID for other stacks:

```bash
terraform output backend_config
terraform output -raw key_vault_id
```

### Destroy

```bash
make azure-bootstrap-destroy
```

The provider is configured to purge soft-deleted Key Vaults on destroy, so you can redeploy with the same `demo_id` immediately.

## Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `demo_id` | Yes | - | Unique identifier (lowercase, numbers, hyphens) |
| `azure_location` | No | `eastus` | Azure region |

## Outputs

| Output | Description |
|--------|-------------|
| `resource_group_name` | Name of the bootstrap resource group |
| `storage_account_name` | Name of the state storage account |
| `container_name` | Name of the tfstate blob container |
| `key_vault_name` | Name of the shared Key Vault |
| `key_vault_id` | Resource ID of the Key Vault (pass to other stacks) |
| `key_vault_uri` | URI of the Key Vault |
| `backend_config` | Ready-to-use backend configuration block |

## Tags

All resources are tagged via `common_tags`:

| Tag Key | Value |
|---------|-------|
| `infracodebase_demo` | `<your-demo-id>` |
| `project` | `samples-azure-bootstrap` |
| `managed_by` | `terraform` |
| `environment` | `development` |
| `purpose` | `demo` |

## Cost

All resources are free or negligible cost for demo usage (Standard LRS storage, Standard SKU Key Vault).
