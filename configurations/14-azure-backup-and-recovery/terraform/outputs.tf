output "resource_group_name" {
  value = azurerm_resource_group.backup.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.backup.name
}

output "recovery_services_vault_name" {
  value = azurerm_recovery_services_vault.backup.name
}

output "backup_policy_name" {
  value = azurerm_backup_policy_vm.backup.name
}

output "protected_vm_id" {
  value = azurerm_backup_protected_vm.backup.id
}