data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "monitoring" {
  name     = "rg-az104-monitoring"
  location = "Australia East"
}

resource "azurerm_monitor_action_group" "budget_alerts" {
  name                = "ag-budget-alerts"
  resource_group_name = azurerm_resource_group.monitoring.name
  short_name          = "BudgetAlert"

  email_receiver {
    name          = "BudgetEmail"
    email_address = var.budget_email
  }
}

resource "azurerm_consumption_budget_subscription" "monthly_budget" {
  name            = "MonthlyBudget"
  subscription_id = data.azurerm_subscription.current.id

  amount     = 20
  time_grain = "Monthly"

  time_period {
    start_date = "2026-08-01T00:00:00Z"
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 50
    threshold_type = "Actual"

    contact_emails = [
      var.budget_email
    ]

    contact_groups = [
      azurerm_monitor_action_group.budget_alerts.id
    ]
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 100
    threshold_type = "Actual"

    contact_emails = [
      var.budget_email
    ]

    contact_groups = [
      azurerm_monitor_action_group.budget_alerts.id
    ]
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 100
    threshold_type = "Forecasted"

    contact_emails = [
      var.budget_email
    ]

    contact_groups = [
      azurerm_monitor_action_group.budget_alerts.id
    ]
  }
}