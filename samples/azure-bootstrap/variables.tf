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

variable "terraform_sp_client_id" {
  description = "Application (client) ID of the Terraform service principal to grant access to resources"
  type        = string
}
