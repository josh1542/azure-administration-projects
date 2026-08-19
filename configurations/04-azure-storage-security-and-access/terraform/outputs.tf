output "resource_group_name" {
  description = "Name of the Terraform-managed resource group."
  value       = azurerm_resource_group.storage.name
}

output "storage_account_name" {
  description = "Name of the Terraform-managed storage account."
  value       = azurerm_storage_account.storage.name
}

output "storage_account_id" {
  description = "Resource ID of the Terraform-managed storage account."
  value       = azurerm_storage_account.storage.id
}

output "container_name" {
  description = "Name of the private blob container."
  value       = azurerm_storage_container.storage.name
}