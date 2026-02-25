variable "demo_id" {
  description = "Unique identifier for this demo environment (used in naming and tagging)"
  type        = string
  default     = "infra"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.demo_id))
    error_message = "demo_id must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "azure_location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "additional_principal_ids" {
  description = "Object IDs of additional principals (e.g. CI/CD service principals) to grant access to state storage and Key Vault"
  type        = list(string)
  default     = []
}
