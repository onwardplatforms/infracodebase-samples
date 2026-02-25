# Azure Web App Stack

Sample Azure web application with PostgreSQL and Storage Account for demo purposes.

## Purpose

Deploys a simple web application stack on Azure for demonstrating Infracodebase capabilities. The architecture is intentionally simple (no VNet or private endpoints) — networking can be added live during demos to showcase infrastructure evolution.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Resource Group                     │
│                                                      │
│   ┌─────────────────┐    ┌──────────────────────┐   │
│   │  App Service     │    │  PostgreSQL Flexible  │   │
│   │  Plan (B1)       │    │  Server (B1ms)        │   │
│   │                  │    │                       │   │
│   │  ┌────────────┐  │    │  ┌────────────────┐   │   │
│   │  │ Linux Web  │──┼────┼─>│    demoapp     │   │   │
│   │  │ App        │  │    │  │   database     │   │   │
│   │  │ (Node 20)  │  │    │  └────────────────┘   │   │
│   │  └────────────┘  │    └──────────────────────┘   │
│   └─────────────────┘                                │
│                                                      │
│   ┌─────────────────┐                                │
│   │ Storage Account  │                                │
│   │ (Standard LRS)   │                                │
│   └─────────────────┘                                │
└─────────────────────────────────────────────────────┘

         │ Credentials stored in
         ▼
┌─────────────────────┐
│  Bootstrap Key Vault │  (from azure-bootstrap)
└─────────────────────┘
```

## Resources Created

| Resource | Description |
|----------|-------------|
| Resource Group | Container for all webapp resources |
| App Service Plan | Linux B1 plan |
| Linux Web App | Node 20 LTS with system-assigned managed identity |
| PostgreSQL Flexible Server | v16, B_Standard_B1ms, 32GB storage, public access |
| PostgreSQL Database | `demoapp` database (UTF-8) |
| Firewall Rule | Allows Azure services to connect to PostgreSQL |
| Storage Account | Standard LRS with TLS 1.2 minimum |
| Key Vault Secrets | PostgreSQL host, username, and password stored in bootstrap Key Vault |
| RBAC Assignment | Web app managed identity gets Key Vault Secrets User |

## Quick Start

### Prerequisites

- [Terraform](https://terraform.io/downloads) >= 1.0
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) logged in (`az login`)
- [azure-bootstrap](../azure-bootstrap) deployed first

### Deploy

```bash
# From repo root (automatically passes Key Vault ID from bootstrap)
make azure-webapp

# Or directly
cd samples/azure-webapp-stack
terraform init && terraform apply \
  -var="bootstrap_key_vault_id=$(terraform -chdir=../azure-bootstrap output -raw key_vault_id)"
```

### Destroy

```bash
make azure-webapp-destroy
```

## Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `demo_id` | Yes | - | Unique identifier (should match azure-bootstrap) |
| `azure_location` | No | `eastus` | Azure region |
| `bootstrap_key_vault_id` | Yes | - | Key Vault resource ID from azure-bootstrap |

## Outputs

| Output | Description |
|--------|-------------|
| `resource_group_name` | Name of the webapp resource group |
| `resource_group_id` | ID of the webapp resource group |
| `webapp_url` | URL of the web application |
| `webapp_name` | Name of the web application |
| `app_service_plan_name` | Name of the App Service Plan |
| `postgres_fqdn` | FQDN of the PostgreSQL server |
| `postgres_server_name` | Name of the PostgreSQL server |
| `storage_account_name` | Name of the storage account |
| `webapp_identity_principal_id` | Managed identity principal ID |

## Tags

All resources are tagged via `common_tags`:

| Tag Key | Value |
|---------|-------|
| `infracodebase_demo` | `<your-demo-id>` |
| `project` | `samples-azure-webapp-stack` |
| `managed_by` | `terraform` |
| `environment` | `development` |
| `purpose` | `demo` |

## Security Notes

- PostgreSQL password is randomly generated (24 chars) and stored in Key Vault
- Web app uses a system-assigned managed identity for Key Vault access
- PostgreSQL has public network access enabled (for demo simplicity)
- No VNet or private endpoints by design — add these during live demos

## Cost

| Resource | Approximate Monthly Cost |
|----------|-------------------------|
| App Service Plan (B1) | ~$13 |
| PostgreSQL Flexible (B1ms) | ~$12 |
| Storage Account (LRS) | Negligible |

**Destroy resources when not in use to minimize costs.**
