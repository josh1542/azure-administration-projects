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

data "azurerm_resource_group" "vm_lab" {
  name = "rg-az104-vm-lab"
}

data "azurerm_virtual_network" "vm_lab" {
  name                = "az104-vnet-vm"
  resource_group_name = data.azurerm_resource_group.vm_lab.name
}

data "azurerm_subnet" "vmss" {
  name                 = "snet_vmss"
  virtual_network_name = data.azurerm_virtual_network.vm_lab.name
  resource_group_name  = data.azurerm_resource_group.vm_lab.name
}

output "resource_group_location" {
  value = data.azurerm_resource_group.vm_lab.location
}

output "vnet_address_space" {
  value = data.azurerm_virtual_network.vm_lab.address_space
}

output "subnet_address_prefixes" {
  value = data.azurerm_subnet.vmss.address_prefixes
}

data "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "az104-vmss"
  resource_group_name = data.azurerm_resource_group.vm_lab.name
}

data "azurerm_lb" "load_balancer" {
  name                = "az104-lb"
  resource_group_name = data.azurerm_resource_group.vm_lab.name
}

data "azurerm_public_ip" "lb_pip" {
  name                = "az104-lb-pip"
  resource_group_name = data.azurerm_resource_group.vm_lab.name
}

data "azurerm_lb_backend_address_pool" "lb_backend" {
  name            = "az104-lb-backend"
  loadbalancer_id = azurerm_lb.managed_lb.id
}

output "vmss_id" {
  value = data.azurerm_virtual_machine_scale_set.vmss.id
}

output "load_balancer_id" {
  value = data.azurerm_lb.load_balancer.id
}