resource "azurerm_resource_group" "networking" {
  name     = var.resource_group_name
  location = var.east_location
}

# ------------------------------------------------------------
# Australia East VNet
# ------------------------------------------------------------

resource "azurerm_virtual_network" "east" {
  name                = "vnet-australia-east-tf"
  location            = var.east_location
  resource_group_name = azurerm_resource_group.networking.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "east_workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.east.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "east_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.east.name
  address_prefixes     = ["10.10.255.0/27"]
}

# ------------------------------------------------------------
# Australia Southeast VNet
# ------------------------------------------------------------

resource "azurerm_virtual_network" "southeast" {
  name                = "vnet-australia-southeast-tf"
  location            = var.southeast_location
  resource_group_name = azurerm_resource_group.networking.name
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "southeast_workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.southeast.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_subnet" "southeast_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.southeast.name
  address_prefixes     = ["10.20.255.0/27"]
}

# ------------------------------------------------------------
# Global VNet Peering
# ------------------------------------------------------------

resource "azurerm_virtual_network_peering" "east_to_southeast" {
  name                      = "east-to-southeast"
  resource_group_name       = azurerm_resource_group.networking.name
  virtual_network_name      = azurerm_virtual_network.east.name
  remote_virtual_network_id = azurerm_virtual_network.southeast.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "southeast_to_east" {
  name                      = "southeast-to-east"
  resource_group_name       = azurerm_resource_group.networking.name
  virtual_network_name      = azurerm_virtual_network.southeast.name
  remote_virtual_network_id = azurerm_virtual_network.east.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# ------------------------------------------------------------
# VPN Gateway Public IPs
# ------------------------------------------------------------

# Australia East supports Availability Zones.
resource "azurerm_public_ip" "east_gateway" {
  name                = "pip-vng-australia-east-tf"
  location            = var.east_location
  resource_group_name = azurerm_resource_group.networking.name
  allocation_method   = "Static"
  sku                 = "Standard"

  zones = ["1", "2", "3"]
}

# Australia Southeast does not support Availability Zones.
resource "azurerm_public_ip" "southeast_gateway" {
  name                = "pip-vng-australia-southeast-tf"
  location            = var.southeast_location
  resource_group_name = azurerm_resource_group.networking.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ------------------------------------------------------------
# Australia East VPN Gateway
# ------------------------------------------------------------

resource "azurerm_virtual_network_gateway" "east" {
  name                = "vng-australia-east-tf"
  location            = var.east_location
  resource_group_name = azurerm_resource_group.networking.name

  type          = "Vpn"
  vpn_type      = "RouteBased"
  active_active = false
  bgp_enabled   = false
  sku           = "VpnGw1AZ"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.east_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.east_gateway.id
  }
}

# ------------------------------------------------------------
# Australia Southeast VPN Gateway
# ------------------------------------------------------------

resource "azurerm_virtual_network_gateway" "southeast" {
  name                = "vng-australia-southeast-tf"
  location            = var.southeast_location
  resource_group_name = azurerm_resource_group.networking.name

  type          = "Vpn"
  vpn_type      = "RouteBased"
  active_active = false
  bgp_enabled   = false
  sku           = "VpnGw1AZ"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.southeast_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.southeast_gateway.id
  }
}

# ------------------------------------------------------------
# VNet-to-VNet VPN Connections
# ------------------------------------------------------------

resource "azurerm_virtual_network_gateway_connection" "east_to_southeast" {
  name                = "east-to-southeast-vpn-tf"
  location            = var.east_location
  resource_group_name = azurerm_resource_group.networking.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.east.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.southeast.id

  shared_key                         = var.vpn_shared_key
  connection_protocol                = "IKEv2"
  bgp_enabled                        = false
  use_policy_based_traffic_selectors = false
  dpd_timeout_seconds                = 45
}

resource "azurerm_virtual_network_gateway_connection" "southeast_to_east" {
  name                = "southeast-to-east-vpn-tf"
  location            = var.southeast_location
  resource_group_name = azurerm_resource_group.networking.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.southeast.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.east.id

  shared_key                         = var.vpn_shared_key
  connection_protocol                = "IKEv2"
  bgp_enabled                        = false
  use_policy_based_traffic_selectors = false
  dpd_timeout_seconds                = 45
}