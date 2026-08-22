# ------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------

resource "azurerm_resource_group" "backup" {
  name     = var.resource_group_name
  location = var.location
}

# ------------------------------------------------------------
# Networking
# ------------------------------------------------------------

resource "azurerm_virtual_network" "backup" {
  name                = "vnet-az104-backup-tf"
  location            = azurerm_resource_group.backup.location
  resource_group_name = azurerm_resource_group.backup.name
  address_space       = ["10.80.0.0/16"]
}

resource "azurerm_subnet" "backup" {
  name                 = "snet-backup"
  resource_group_name  = azurerm_resource_group.backup.name
  virtual_network_name = azurerm_virtual_network.backup.name
  address_prefixes     = ["10.80.1.0/24"]
}

resource "azurerm_network_security_group" "backup" {
  name                = "nsg-vm-backup-tf"
  location            = azurerm_resource_group.backup.location
  resource_group_name = azurerm_resource_group.backup.name
}

resource "azurerm_network_interface" "backup" {
  name                = "nic-vm-backup-tf"
  location            = azurerm_resource_group.backup.location
  resource_group_name = azurerm_resource_group.backup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backup.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "backup" {
  network_interface_id      = azurerm_network_interface.backup.id
  network_security_group_id = azurerm_network_security_group.backup.id
}

# ------------------------------------------------------------
# Linux VM
# ------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "backup" {
  name                = "vm-backup-tf"
  location            = azurerm_resource_group.backup.location
  resource_group_name = azurerm_resource_group.backup.name

  size           = "Standard_B2ats_v2"
  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.backup.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(pathexpand("~/.ssh/az104-backup-tf.pub"))
  }

  secure_boot_enabled = true
  vtpm_enabled        = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    echo "AZ-104 Terraform backup test" > /home/azureuser/backup-test.txt
    chown azureuser:azureuser /home/azureuser/backup-test.txt
  EOF
  )

  boot_diagnostics {}

  depends_on = [
    azurerm_network_interface_security_group_association.backup
  ]
}

# ------------------------------------------------------------
# Recovery Services Vault
# ------------------------------------------------------------

resource "azurerm_recovery_services_vault" "backup" {
  name                = "rsv-az104-backup-tf"
  location            = azurerm_resource_group.backup.location
  resource_group_name = azurerm_resource_group.backup.name

  sku = "Standard"

  storage_mode_type            = "LocallyRedundant"
  cross_region_restore_enabled = false
  immutability                 = "Disabled"
}

# ------------------------------------------------------------
# Enhanced VM Backup Policy
# ------------------------------------------------------------

resource "azurerm_backup_policy_vm" "backup" {
  name                = "policy-az104-vm-backup-enhanced-tf"
  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = azurerm_recovery_services_vault.backup.name

  policy_type = "V2"
  timezone    = "UTC"

  instant_restore_retention_days = 2

  backup {
    frequency     = "Hourly"
    time          = "08:00"
    hour_interval = 4
    hour_duration = 12
  }

  retention_daily {
    count = 7
  }
}

# ------------------------------------------------------------
# Protect VM with Azure Backup
# ------------------------------------------------------------

resource "azurerm_backup_protected_vm" "backup" {
  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = azurerm_recovery_services_vault.backup.name

  source_vm_id     = azurerm_linux_virtual_machine.backup.id
  backup_policy_id = azurerm_backup_policy_vm.backup.id
}