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
  workload     = "${var.demo_id}boot"
  env          = "dev"
  name_suffix  = "${local.region_abbrev}-${local.workload}-${local.env}"

  rg_name      = "rg-${local.name_suffix}"
  storage_name = replace("st${local.name_suffix}", "-", "") # storage: alphanumeric only, max 24 chars
  kv_name      = "kv-${local.name_suffix}"                  # key vault: alphanumeric + hyphens, max 24 chars

  common_tags = {
    infracodebase_demo = var.demo_id
    project            = "samples-azure-bootstrap"
    managed_by         = "terraform"
    environment        = "development"
    purpose            = "demo"
  }
}
