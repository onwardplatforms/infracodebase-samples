output "resource_group_name" {
  description = "Name of the webapp resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the webapp resource group"
  value       = azurerm_resource_group.main.id
}

output "webapp_url" {
  description = "URL of the web application"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "webapp_name" {
  description = "Name of the web application"
  value       = azurerm_linux_web_app.main.name
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.main.name
}

output "postgres_fqdn" {
  description = "FQDN of the PostgreSQL flexible server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_server_name" {
  description = "Name of the PostgreSQL flexible server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "webapp_identity_principal_id" {
  description = "Principal ID of the web app's system-assigned managed identity"
  value       = azurerm_linux_web_app.main.identity[0].principal_id
}
