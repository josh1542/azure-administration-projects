provider "azurerm" {
  features {}
}

variable "admin_password" {
  description = "Administrator password for the Windows VM"
  type        = string
  sensitive   = true
}