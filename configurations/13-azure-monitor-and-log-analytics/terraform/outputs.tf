output "resource_group_name" {
  value = azurerm_resource_group.monitoring.name
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.monitoring.name
}

output "monitoring_vm_name" {
  value = azurerm_linux_virtual_machine.monitoring.name
}

output "data_collection_rule_name" {
  value = azurerm_monitor_data_collection_rule.monitoring.name
}

output "metric_alert_name" {
  value = azurerm_monitor_metric_alert.high_cpu.name
}

output "vm_public_ip" {
  value = azurerm_public_ip.monitoring.ip_address
}