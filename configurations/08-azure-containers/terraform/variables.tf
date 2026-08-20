variable "location" {
  type    = string
  default = "Australia East"
}

variable "resource_group_name" {
  type    = string
  default = "rg-az104-containers-tf"
}

variable "acr_name" {
  type        = string
  description = "Globally unique Azure Container Registry name."
}