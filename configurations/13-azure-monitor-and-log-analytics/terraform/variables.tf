variable "location" {
  type    = string
  default = "Australia East"
}

variable "resource_group_name" {
  type    = string
  default = "rg-az104-monitoring-tf"
}

variable "alert_email" {
  type        = string
  description = "Email address used by the Azure Monitor action group."
  sensitive   = true
}