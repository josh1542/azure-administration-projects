output "private_dns_zone_name" {
  value = azurerm_private_dns_zone.corp.name
}

output "east_vnet_name" {
  value = azurerm_virtual_network.east.name
}

output "southeast_vnet_name" {
  value = azurerm_virtual_network.southeast.name
}

output "east_dns_record" {
  value = "vm-dns-east.${azurerm_private_dns_zone.corp.name}"
}

output "southeast_dns_record" {
  value = "vm-dns-southeast.${azurerm_private_dns_zone.corp.name}"
}