variable "resource_group_name" {
  type    = string
  default = "rg-az104-vnet-connectivity-tf"
}

variable "east_location" {
  type    = string
  default = "Australia East"
}

variable "southeast_location" {
  type    = string
  default = "Australia Southeast"
}

variable "vpn_shared_key" {
  type      = string
  sensitive = true
}