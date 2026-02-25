#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

#------------------------------------------------------------------------------
# Resource Group
#------------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.azure_location
  tags     = local.common_tags
}

#------------------------------------------------------------------------------
# Storage Account for Terraform Remote State
#------------------------------------------------------------------------------

resource "azurerm_storage_account" "state" {
  name                     = local.storage_name
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.common_tags
}

resource "azurerm_storage_container" "tfstate" {
  name                 = "tfstate"
  storage_account_id   = azurerm_storage_account.state.id
}

#------------------------------------------------------------------------------
# RBAC: Grant the deployer access to manage state
#------------------------------------------------------------------------------

resource "azurerm_role_assignment" "deployer_blob_contributor" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

#------------------------------------------------------------------------------
# RBAC: Grant additional principals access to state storage and Key Vault
#------------------------------------------------------------------------------

resource "azurerm_role_assignment" "additional_blob_contributor" {
  for_each             = toset(var.additional_principal_ids)
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "additional_kv_secrets_officer" {
  for_each             = toset(var.additional_principal_ids)
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
}

#------------------------------------------------------------------------------
# Key Vault (shared secrets for all Azure stacks)
#------------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                       = local.kv_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  rbac_authorization_enabled = true
  tags                       = local.common_tags
}

#------------------------------------------------------------------------------
# RBAC: Grant the deployer access to manage secrets in Key Vault
#------------------------------------------------------------------------------

resource "azurerm_role_assignment" "deployer_kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
