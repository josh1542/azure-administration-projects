resource "azurerm_resource_group" "security" {
  name     = var.resource_group_name
  location = var.location
}

# ------------------------------------------------------------
# Virtual Network
# ------------------------------------------------------------

resource "azurerm_virtual_network" "security" {
  name                = "vnet-security-lab-tf"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  address_space       = ["10.50.0.0/16"]
}

resource "azurerm_subnet" "admin" {
  name                 = "snet-admin"
  resource_group_name  = azurerm_resource_group.security.name
  virtual_network_name = azurerm_virtual_network.security.name
  address_prefixes     = ["10.50.1.0/24"]
}

resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.security.name
  virtual_network_name = azurerm_virtual_network.security.name
  address_prefixes     = ["10.50.2.0/24"]
}

# ------------------------------------------------------------
# Application Security Groups
# ------------------------------------------------------------

resource "azurerm_application_security_group" "admin" {
  name                = "asg-admin"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
}

resource "azurerm_application_security_group" "web" {
  name                = "asg-web"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
}

# ------------------------------------------------------------
# Network Security Group
# ------------------------------------------------------------

resource "azurerm_network_security_group" "web" {
  name                = "nsg-web"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
}

# ------------------------------------------------------------
# NSG Rules
# ------------------------------------------------------------

resource "azurerm_network_security_rule" "allow_admin_http" {
  name                        = "allow-http-admin-to-web"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  resource_group_name         = azurerm_resource_group.security.name
  network_security_group_name = azurerm_network_security_group.web.name

  source_application_security_group_ids = [
    azurerm_application_security_group.admin.id
  ]

  destination_application_security_group_ids = [
    azurerm_application_security_group.web.id
  ]
}

resource "azurerm_network_security_rule" "deny_vnet_http" {
  name                        = "deny-http-vnet-to-web"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.security.name
  network_security_group_name = azurerm_network_security_group.web.name

  destination_application_security_group_ids = [
    azurerm_application_security_group.web.id
  ]
}

# ------------------------------------------------------------
# Associate NSG with Web Subnet
# ------------------------------------------------------------

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

# ------------------------------------------------------------
# Lightweight NICs for ASG Membership
# ------------------------------------------------------------

resource "azurerm_network_interface" "admin" {
  name                = "nic-admin-tf"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.admin.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "web" {
  name                = "nic-web-tf"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# ------------------------------------------------------------
# NIC → ASG Associations
# ------------------------------------------------------------

resource "azurerm_network_interface_application_security_group_association" "admin" {
  network_interface_id          = azurerm_network_interface.admin.id
  application_security_group_id = azurerm_application_security_group.admin.id
}

resource "azurerm_network_interface_application_security_group_association" "web" {
  network_interface_id          = azurerm_network_interface.web.id
  application_security_group_id = azurerm_application_security_group.web.id
}