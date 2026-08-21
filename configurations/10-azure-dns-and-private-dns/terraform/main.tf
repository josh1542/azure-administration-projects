resource "azurerm_resource_group" "dns" {
  name     = var.resource_group_name
  location = var.east_location
}

# ------------------------------------------------------------
# Australia East VNet
# ------------------------------------------------------------

resource "azurerm_virtual_network" "east" {
  name                = "vnet-dns-east-tf"
  location            = var.east_location
  resource_group_name = azurerm_resource_group.dns.name
  address_space       = ["10.30.0.0/16"]
}

resource "azurerm_subnet" "east_workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.dns.name
  virtual_network_name = azurerm_virtual_network.east.name
  address_prefixes     = ["10.30.1.0/24"]
}

# ------------------------------------------------------------
# Australia Southeast VNet
# ------------------------------------------------------------

resource "azurerm_virtual_network" "southeast" {
  name                = "vnet-dns-southeast-tf"
  location            = var.southeast_location
  resource_group_name = azurerm_resource_group.dns.name
  address_space       = ["10.40.0.0/16"]
}

resource "azurerm_subnet" "southeast_workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.dns.name
  virtual_network_name = azurerm_virtual_network.southeast.name
  address_prefixes     = ["10.40.1.0/24"]
}

# ------------------------------------------------------------
# Private DNS Zone
# ------------------------------------------------------------

resource "azurerm_private_dns_zone" "corp" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.dns.name
}

# ------------------------------------------------------------
# Private DNS VNet Links
# ------------------------------------------------------------

resource "azurerm_private_dns_zone_virtual_network_link" "east" {
  name                = "link-dns-east"
  private_dns_zone_id = azurerm_private_dns_zone.corp.id
  virtual_network_id  = azurerm_virtual_network.east.id

  registration_enabled = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "southeast" {
  name                = "link-dns-southeast"
  private_dns_zone_id = azurerm_private_dns_zone.corp.id
  virtual_network_id  = azurerm_virtual_network.southeast.id

  registration_enabled = false
}

# ------------------------------------------------------------
# Private DNS A Records
# ------------------------------------------------------------

resource "azurerm_private_dns_a_record" "east" {
  name                = "vm-dns-east"
  private_dns_zone_id = azurerm_private_dns_zone.corp.id
  ttl                 = 3600
  records             = ["10.30.1.4"]
}

resource "azurerm_private_dns_a_record" "southeast" {
  name                = "vm-dns-southeast"
  private_dns_zone_id = azurerm_private_dns_zone.corp.id
  ttl                 = 3600
  records             = ["10.40.1.4"]
}