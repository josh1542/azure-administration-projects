variable "resource_group_name" {
  type    = string
  default = "rg-az104-dns-tf"
}

variable "east_location" {
  type    = string
  default = "Australia East"
}

variable "southeast_location" {
  type    = string
  default = "Australia Southeast"
}

variable "private_dns_zone_name" {
  type    = string
  default = "corp.internal"
}