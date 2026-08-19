resource "azurerm_resource_group" "storage" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "AZ104-Storage"
  }
}

resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.storage.name
  location                 = azurerm_resource_group.storage.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  https_traffic_only_enabled       = true
  min_tls_version                  = "TLS1_2"
  allow_nested_items_to_be_public  = false
  public_network_access_enabled    = true
  shared_access_key_enabled        = true
  default_to_oauth_authentication  = true
  cross_tenant_replication_enabled = false
  is_hns_enabled                   = false
  nfsv3_enabled                    = false
  sftp_enabled                     = false

  blob_properties {
    versioning_enabled            = true
    change_feed_enabled           = true
    change_feed_retention_in_days = 7

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  share_properties {
    retention_policy {
      days = 7
    }
  }

  azure_files_authentication {
    directory_type = "AADKERB"

    default_share_level_permission = "StorageFileDataSmbShareContributor"
  }

  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "AZ104-Storage"
  }
}

resource "azurerm_storage_container" "storage" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "storage_reader" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Reader"
  principal_id         = var.lab_user_object_id
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.lab_user_object_id
}

resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.storage.id

  rule {
    name    = "move-old-blobs-to-cool"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
      }
    }
  }
}

resource "azurerm_storage_share" "files" {
  name               = "az104-tf-fileshare"
  storage_account_id = azurerm_storage_account.storage.id
  quota              = 5
  access_tier        = "TransactionOptimized"
}

resource "azurerm_storage_account" "destination" {
  name                     = var.destination_storage_account_name
  resource_group_name      = azurerm_resource_group.storage.name
  location                 = azurerm_resource_group.storage.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  https_traffic_only_enabled       = true
  min_tls_version                  = "TLS1_2"
  allow_nested_items_to_be_public  = false
  public_network_access_enabled    = true
  cross_tenant_replication_enabled = false
  is_hns_enabled                   = false

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "AZ104-Storage"
  }
}

resource "azurerm_storage_container" "destination" {
  name                  = "az104-tf-destination-container"
  storage_account_id    = azurerm_storage_account.destination.id
  container_access_type = "private"
}

resource "azurerm_storage_object_replication" "replication" {
  source_storage_account_id      = azurerm_storage_account.storage.id
  destination_storage_account_id = azurerm_storage_account.destination.id

  rules {
    source_container_name      = azurerm_storage_container.storage.name
    destination_container_name = azurerm_storage_container.destination.name
    copy_blobs_created_after   = "OnlyNewObjects"
  }
}