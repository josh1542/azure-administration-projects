resource "azurerm_resource_group" "app_service" {
  name     = "rg-az104-appservice-tf"
  location = "Australia East"

  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "AZ104-AppService"
  }
}

resource "azurerm_virtual_network" "app_service" {
  name                = "vnet-az104-appservice-tf"
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.app_service.location
  resource_group_name = azurerm_resource_group.app_service.name

  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "AZ104-AppService"
  }
}

resource "azurerm_subnet" "app_service" {
  name                 = "snet-appservice"
  resource_group_name  = azurerm_resource_group.app_service.name
  virtual_network_name = azurerm_virtual_network.app_service.name
  address_prefixes     = ["10.30.1.0/24"]

  delegation {
    name = "app-service-delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

resource "azurerm_service_plan" "app_service" {
  name                = "asp-az104-appservice-tf"
  resource_group_name = azurerm_resource_group.app_service.name
  location            = azurerm_resource_group.app_service.location

  os_type  = "Windows"
  sku_name = "S1"

  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "AZ104-AppService"
  }
}

resource "azurerm_windows_web_app" "app_service" {
  name                = "az104-appservice-tf-20260819"
  resource_group_name = azurerm_resource_group.app_service.name
  location            = azurerm_resource_group.app_service.location
  service_plan_id     = azurerm_service_plan.app_service.id

  https_only                = true
  virtual_network_subnet_id = azurerm_subnet.app_service.id

  app_settings = {
    APP_ENVIRONMENT = "Terraform"
  }

  site_config {
    always_on           = true
    minimum_tls_version = "1.2"
  }

  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "AZ104-AppService"
  }
}

resource "azurerm_windows_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_windows_web_app.app_service.id

  https_only = true

  app_settings = {
    APP_ENVIRONMENT = "Staging"
  }

  site_config {
    always_on           = true
    minimum_tls_version = "1.2"
  }

  tags = {
    Environment = "Staging"
    ManagedBy   = "Terraform"
    Project     = "AZ104-AppService"
  }
}

resource "azurerm_monitor_autoscale_setting" "app_service" {
  name                = "autoscale-az104-appservice-tf"
  resource_group_name = azurerm_resource_group.app_service.name
  location            = azurerm_resource_group.app_service.location
  target_resource_id  = azurerm_service_plan.app_service.id

  profile {
    name = "default"

    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.app_service.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.app_service.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "AZ104-AppService"
  }
}