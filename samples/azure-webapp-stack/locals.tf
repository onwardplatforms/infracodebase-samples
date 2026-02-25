locals {
  # Region abbreviation lookup
  region_abbreviations = {
    eastus    = "eus"
    eastus2   = "eus2"
    westus    = "wus"
    westus2   = "wus2"
    centralus = "cus"
  }
  region_abbrev = lookup(local.region_abbreviations, var.azure_location, var.azure_location)

  # Naming: {type}-{region}-{workload}-{env}
  workload     = "${var.demo_id}app"
  env          = "dev"
  name_suffix  = "${local.region_abbrev}-${local.workload}-${local.env}"

  rg_name      = "rg-${local.name_suffix}"
  asp_name     = "asp-${local.name_suffix}"
  webapp_name  = "app-${local.name_suffix}"
  pg_name      = "psql-${local.name_suffix}"
  storage_name = replace("st${local.name_suffix}", "-", "") # storage: alphanumeric only, max 24 chars

  # Key Vault secret names use the workload prefix
  secret_prefix = "${local.workload}-${local.env}"

  common_tags = {
    infracodebase_demo = var.demo_id
    project            = "samples-azure-webapp-stack"
    managed_by         = "terraform"
    environment        = "development"
    purpose            = "demo"
  }
}
