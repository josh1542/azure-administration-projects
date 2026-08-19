resource "azurerm_resource_group" "vm_encryption" {
  name     = "rg-az104-vm-encryption"
  location = "Australia East"

  tags = {
    Environment = "Lab"
    Project     = "AZ-104 VM Encryption at Host"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_virtual_network" "vm_encryption" {
  name                = "vnet-vm-encryption"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.vm_encryption.location
  resource_group_name = azurerm_resource_group.vm_encryption.name
}

resource "azurerm_subnet" "vm_encryption" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.vm_encryption.name
  virtual_network_name = azurerm_virtual_network.vm_encryption.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_interface" "vm_encryption" {
  name                = "nic-vm-encryption"
  location            = azurerm_resource_group.vm_encryption.location
  resource_group_name = azurerm_resource_group.vm_encryption.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_encryption.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm_encryption" {
  name          = "vm-encryption-host"
  computer_name = "vmencrypthost"

  resource_group_name = azurerm_resource_group.vm_encryption.name
  location            = azurerm_resource_group.vm_encryption.location
  size                = "Standard_D2s_v5"

  admin_username = "azureadmin"
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.vm_encryption.id
  ]

  encryption_at_host_enabled = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  tags = {
    Environment = "Lab"
    Project     = "AZ-104 VM Encryption at Host"
    ManagedBy   = "Terraform"
  }
}