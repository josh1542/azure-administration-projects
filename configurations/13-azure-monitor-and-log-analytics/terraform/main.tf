# ------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------

resource "azurerm_resource_group" "monitoring" {
  name     = var.resource_group_name
  location = var.location
}

# ------------------------------------------------------------
# Networking
# ------------------------------------------------------------

resource "azurerm_virtual_network" "monitoring" {
  name                = "vnet-monitoring-tf"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  address_space       = ["10.70.0.0/16"]
}

resource "azurerm_subnet" "monitoring" {
  name                 = "snet-monitoring"
  resource_group_name  = azurerm_resource_group.monitoring.name
  virtual_network_name = azurerm_virtual_network.monitoring.name
  address_prefixes     = ["10.70.1.0/24"]
}

resource "azurerm_public_ip" "monitoring" {
  name                = "pip-vm-monitoring-tf"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "monitoring" {
  name                = "nsg-vm-monitoring-tf"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
}

resource "azurerm_network_interface" "monitoring" {
  name                = "nic-vm-monitoring-tf"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.monitoring.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.monitoring.id
  }
}

resource "azurerm_network_interface_security_group_association" "monitoring" {
  network_interface_id      = azurerm_network_interface.monitoring.id
  network_security_group_id = azurerm_network_security_group.monitoring.id
}

# ------------------------------------------------------------
# Log Analytics
# ------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "monitoring" {
  name                = "log-az104-monitoring-tf"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name

  sku               = "PerGB2018"
  retention_in_days = 30
}

# ------------------------------------------------------------
# Linux Monitoring VM
# ------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "monitoring" {
  name                = "vm-monitoring-tf"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name

  size           = "Standard_B2ats_v2"
  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.monitoring.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(pathexpand("~/.ssh/az104-monitoring-tf.pub"))
  }

  identity {
    type = "SystemAssigned"
  }

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

  depends_on = [
    azurerm_network_interface_security_group_association.monitoring
  ]
}

# ------------------------------------------------------------
# Azure Monitor Agent
# ------------------------------------------------------------

resource "azurerm_virtual_machine_extension" "ama" {
  name                 = "AzureMonitorLinuxAgent"
  virtual_machine_id   = azurerm_linux_virtual_machine.monitoring.id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorLinuxAgent"
  type_handler_version = "1.0"

  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
}

# ------------------------------------------------------------
# Data Collection Rule
# ------------------------------------------------------------

resource "azurerm_monitor_data_collection_rule" "monitoring" {
  name                = "dcr-az104-monitoring-tf"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  kind                = "Linux"

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.monitoring.id
      name                  = "log-analytics-destination"
    }
  }

  data_sources {
    performance_counter {
      name                          = "VMInsightsPerfCounters"
      streams                       = ["Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
    }
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["log-analytics-destination"]
  }
}

resource "azurerm_monitor_data_collection_rule_association" "monitoring" {
  name                    = "dcra-vm-monitoring"
  target_resource_id      = azurerm_linux_virtual_machine.monitoring.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.monitoring.id

  depends_on = [
    azurerm_virtual_machine_extension.ama
  ]
}

# ------------------------------------------------------------
# Azure Monitor Action Group
# ------------------------------------------------------------

resource "azurerm_monitor_action_group" "monitoring" {
  name                = "ag-az104-monitoring-tf"
  resource_group_name = azurerm_resource_group.monitoring.name
  short_name          = "az104mon"

  email_receiver {
    name                    = "email-alert"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

# ------------------------------------------------------------
# CPU Metric Alert
# ------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "alert-vm-high-cpu-tf"
  resource_group_name = azurerm_resource_group.monitoring.name

  scopes = [
    azurerm_linux_virtual_machine.monitoring.id
  ]

  description   = "Warning when average VM CPU exceeds 20 percent."
  severity      = 2
  enabled       = true
  auto_mitigate = true

  frequency   = "PT1M"
  window_size = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 20
  }

  action {
    action_group_id = azurerm_monitor_action_group.monitoring.id
  }
}