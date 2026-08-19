terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "arm_lab" {
  name = "rg-az104-arm-lab"
}

resource "azurerm_managed_disk" "disk3" {
  name                 = "az104-tf-disk3"
  location             = data.azurerm_resource_group.arm_lab.location
  resource_group_name  = data.azurerm_resource_group.arm_lab.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32

  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "AZ104-ARM"
  }
}