resource "azurerm_resource_group" "containers" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.containers.name
  location            = azurerm_resource_group.containers.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_user_assigned_identity" "acr_pull" {
  name                = "id-az104-container-acr-pull"
  resource_group_name = azurerm_resource_group.containers.name
  location            = azurerm_resource_group.containers.location
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr_pull.principal_id
}

resource "azurerm_log_analytics_workspace" "containers" {
  name                = "log-az104-containers-tf"
  resource_group_name = azurerm_resource_group.containers.name
  location            = azurerm_resource_group.containers.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "containers" {
  name                       = "cae-az104-containers-tf"
  resource_group_name        = azurerm_resource_group.containers.name
  location                   = azurerm_resource_group.containers.location
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.containers.id

  lifecycle {
    ignore_changes = [
      workload_profile
    ]
  }
}

resource "azurerm_container_group" "aci" {
  name                = "az104-aci-nginx-tf"
  resource_group_name = azurerm_resource_group.containers.name
  location            = azurerm_resource_group.containers.location

  os_type         = "Linux"
  ip_address_type = "Public"
  dns_name_label  = "${var.acr_name}-aci"
  restart_policy  = "Always"

  identity {
    type = "UserAssigned"

    identity_ids = [
      azurerm_user_assigned_identity.acr_pull.id
    ]
  }

  image_registry_credential {
    server                    = azurerm_container_registry.acr.login_server
    user_assigned_identity_id = azurerm_user_assigned_identity.acr_pull.id
  }

  container {
    name   = "nginx"
    image  = "${azurerm_container_registry.acr.login_server}/az104-nginx:v1"
    cpu    = 1
    memory = 1

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  exposed_port {
    port     = 80
    protocol = "TCP"
  }

  depends_on = [
    azurerm_role_assignment.acr_pull
  ]
}

resource "azurerm_container_app" "app" {
  name                         = "az104-container-app-tf"
  container_app_environment_id = azurerm_container_app_environment.containers.id
  resource_group_name          = azurerm_resource_group.containers.name
  revision_mode                = "Single"

  identity {
    type = "UserAssigned"

    identity_ids = [
      azurerm_user_assigned_identity.acr_pull.id
    ]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.acr_pull.id
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = "nginx"
      image  = "${azurerm_container_registry.acr.login_server}/az104-nginx:v1"
      cpu    = 0.25
      memory = "0.5Gi"
    }

    http_scale_rule {
      name                = "http-scaler"
      concurrent_requests = 50
    }
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = 80
    transport                  = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  lifecycle {
    ignore_changes = [
      workload_profile_name
    ]
  }

  depends_on = [
    azurerm_role_assignment.acr_pull
  ]
}