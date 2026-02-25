output "resource_group_name" {
  description = "Name of the bootstrap resource group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "Name of the storage account for Terraform state"
  value       = azurerm_storage_account.state.name
}

output "container_name" {
  description = "Name of the blob container for Terraform state"
  value       = azurerm_storage_container.tfstate.name
}

output "key_vault_name" {
  description = "Name of the Key Vault for shared secrets"
  value       = azurerm_key_vault.main.name
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "backend_config" {
  description = "Backend configuration block to add to other Azure Terraform stacks"
  value       = <<-EOT
    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.main.name}"
        storage_account_name = "${azurerm_storage_account.state.name}"
        container_name       = "tfstate"
        key                  = "<STACK_NAME>/terraform.tfstate"
      }
    }
  EOT
}
