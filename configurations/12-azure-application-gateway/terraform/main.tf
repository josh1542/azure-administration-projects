resource "azurerm_resource_group" "appgw" {
  name     = var.resource_group_name
  location = var.location
}

# ------------------------------------------------------------
# Virtual Network
# ------------------------------------------------------------

resource "azurerm_virtual_network" "appgw" {
  name                = "vnet-appgw-lab-tf"
  location            = azurerm_resource_group.appgw.location
  resource_group_name = azurerm_resource_group.appgw.name
  address_space       = ["10.60.0.0/16"]
}

resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.appgw.name
  virtual_network_name = azurerm_virtual_network.appgw.name
  address_prefixes     = ["10.60.0.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "snet-backend"
  resource_group_name  = azurerm_resource_group.appgw.name
  virtual_network_name = azurerm_virtual_network.appgw.name
  address_prefixes     = ["10.60.1.0/24"]
}

# ------------------------------------------------------------
# Backend NICs
# ------------------------------------------------------------

resource "azurerm_network_interface" "web1" {
  name                = "nic-web-1-tf"
  location            = azurerm_resource_group.appgw.location
  resource_group_name = azurerm_resource_group.appgw.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.60.1.4"
  }
}

resource "azurerm_network_interface" "web2" {
  name                = "nic-web-2-tf"
  location            = azurerm_resource_group.appgw.location
  resource_group_name = azurerm_resource_group.appgw.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.60.1.5"
  }
}

# ------------------------------------------------------------
# Application Gateway Public IP
# ------------------------------------------------------------

resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-az104-tf"
  location            = azurerm_resource_group.appgw.location
  resource_group_name = azurerm_resource_group.appgw.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ------------------------------------------------------------
# Application Gateway
# ------------------------------------------------------------

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-az104-tf"
  location            = azurerm_resource_group.appgw.location
  resource_group_name = azurerm_resource_group.appgw.name

  http2_enabled = true

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 0
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "frontend-port-http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-public-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = "backend-pool-web"

    ip_addresses = [
      azurerm_network_interface.web1.private_ip_address,
      azurerm_network_interface.web2.private_ip_address
    ]
  }

  backend_http_settings {
    name                  = "backend-http"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "listener-http"
    frontend_ip_configuration_name = "frontend-public-ip"
    frontend_port_name             = "frontend-port-http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule-http"
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = "listener-http"
    backend_address_pool_name  = "backend-pool-web"
    backend_http_settings_name = "backend-http"
  }
}