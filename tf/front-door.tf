locals {
  front_door_name = "fd-001"
  workspace_name  = "log-fd-001"
}

resource "azurerm_cdn_frontdoor_profile" "fd" {
  name                = local.front_door_name
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Premium_AzureFrontDoor"
}

// create log analytics workspace
resource "azurerm_log_analytics_workspace" "fd" {
  name                = local.workspace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "fd" {
  name                       = "fd-logging"
  target_resource_id         = azurerm_cdn_frontdoor_profile.fd.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.fd.id

  enabled_log {
    category = "FrontDoorAccessLog"
  }

  enabled_log {
    category = "FrontDoorWebApplicationFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }
}
