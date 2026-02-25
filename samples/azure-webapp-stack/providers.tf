provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_secrets_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  resource_provider_registrations = "none"
}
