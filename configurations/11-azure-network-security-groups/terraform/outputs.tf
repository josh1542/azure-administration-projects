output "network_security_group_name" {
  value = azurerm_network_security_group.web.name
}

output "admin_application_security_group" {
  value = azurerm_application_security_group.admin.name
}

output "web_application_security_group" {
  value = azurerm_application_security_group.web.name
}

output "admin_nic_private_ip" {
  value = azurerm_network_interface.admin.private_ip_address
}

output "web_nic_private_ip" {
  value = azurerm_network_interface.web.private_ip_address
}