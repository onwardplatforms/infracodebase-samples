#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "azuread_service_principal" "terraform" {
  client_id = var.terraform_sp_client_id
}

#------------------------------------------------------------------------------
# Resource Group
#------------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.azure_location
  tags     = local.common_tags
}

#------------------------------------------------------------------------------
# RBAC: Grant the Terraform SP Contributor on the resource group
#------------------------------------------------------------------------------

resource "azurerm_role_assignment" "terraform_sp_rg_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_service_principal.terraform.object_id
}

#------------------------------------------------------------------------------
# App Service
#------------------------------------------------------------------------------

resource "azurerm_service_plan" "main" {
  name                = local.asp_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = local.common_tags
}

resource "azurerm_linux_web_app" "main" {
  name                = local.webapp_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true
  tags                = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = false

    application_stack {
      node_version = "20-lts"
    }
  }

  app_settings = {
    "DATABASE_HOST"   = azurerm_postgresql_flexible_server.main.fqdn
    "DATABASE_NAME"   = "demoapp"
    "STORAGE_ACCOUNT" = azurerm_storage_account.main.name
  }
}

#------------------------------------------------------------------------------
# PostgreSQL Flexible Server
#------------------------------------------------------------------------------

resource "random_password" "postgres" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                          = local.pg_name
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  version                       = "16"
  administrator_login           = "pgadmin"
  administrator_password        = random_password.postgres.result
  public_network_access_enabled = true
  storage_mb                    = 32768
  sku_name                      = "B_Standard_B1ms"
  zone                          = "1"
  tags                          = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "demoapp"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Allow Azure services to connect (for App Service)
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

#------------------------------------------------------------------------------
# Storage Account
#------------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                     = local.storage_name
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.common_tags
}

#------------------------------------------------------------------------------
# Key Vault: Store credentials as secrets in bootstrap Key Vault
#------------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "postgres_host" {
  name         = "${local.secret_prefix}-postgres-host"
  value        = azurerm_postgresql_flexible_server.main.fqdn
  key_vault_id = var.bootstrap_key_vault_id
}

resource "azurerm_key_vault_secret" "postgres_user" {
  name         = "${local.secret_prefix}-postgres-user"
  value        = "pgadmin"
  key_vault_id = var.bootstrap_key_vault_id
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "${local.secret_prefix}-postgres-password"
  value        = random_password.postgres.result
  key_vault_id = var.bootstrap_key_vault_id
}

#------------------------------------------------------------------------------
# RBAC: Grant the Web App's managed identity access to Key Vault secrets
#------------------------------------------------------------------------------

resource "azurerm_role_assignment" "webapp_kv_secrets_user" {
  scope                = var.bootstrap_key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}
