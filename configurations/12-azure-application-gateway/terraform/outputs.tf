output "application_gateway_name" {
  value = azurerm_application_gateway.appgw.name
}

output "application_gateway_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}

output "backend_1_private_ip" {
  value = azurerm_network_interface.web1.private_ip_address
}

output "backend_2_private_ip" {
  value = azurerm_network_interface.web2.private_ip_address
}