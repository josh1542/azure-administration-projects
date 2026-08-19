variable "location" {
  type        = string
  description = "Azure region used for the Terraform storage lab."
  default     = "Australia East"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Terraform-managed resource group."
  default     = "rg-az104-storage-tf"
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique name for the Terraform-managed storage account."
}

variable "container_name" {
  type        = string
  description = "Name of the private blob container."
  default     = "az104-tf-container"
}

variable "lab_user_object_id" {
  type        = string
  description = "Microsoft Entra Object ID of the lab user receiving Azure RBAC assignments."
}

variable "destination_storage_account_name" {
  description = "Globally unique name for the object replication destination storage account."
  type        = string
}