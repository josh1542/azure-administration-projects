output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "aci_fqdn" {
  value = azurerm_container_group.aci.fqdn
}

output "container_app_fqdn" {
  value = azurerm_container_app.app.ingress[0].fqdn
}