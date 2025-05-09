locals {
  cae_log_name              = "log-cae-001"
  cae_name                  = "cae-001"
  cae_managed_identity_name = "mi-cae-001"
}

resource "azurerm_log_analytics_workspace" "cae" {
  name                = local.cae_log_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_user_assigned_identity" "cae" {
  name                = local.cae_managed_identity_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_container_app_environment" "cae" {
  name                       = local.cae_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cae.id

  internal_load_balancer_enabled     = true
  infrastructure_resource_group_name = var.cae_resource_group_name
  infrastructure_subnet_id           = azurerm_subnet.subnets["ContainerAppsSubnet001"].id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

// in order to enable MI on CAE, we need to use azapi as a workaround
// this MI is needed to access Key Vault certificate for custom domain
resource "azapi_resource_action" "identitypatch" {
  type        = "Microsoft.App/managedEnvironments@2024-10-02-preview"
  resource_id = azurerm_container_app_environment.cae.id
  method      = "PATCH"

  body = {
    identity = {
      type = "SystemAssigned, UserAssigned"
      userAssignedIdentities = {
        "${azurerm_user_assigned_identity.cae.id}" = {}
      }
    }
  }

  response_export_values = ["*"]
}

resource "azurerm_private_dns_zone" "cae" {
  name                = azurerm_container_app_environment.cae.default_domain
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the private DNS zone to the virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "cae" {
  name                  = "vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.cae.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Create an A record with a wildcard (*) for the container app environment
resource "azurerm_private_dns_a_record" "cae" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.cae.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_container_app_environment.cae.static_ip_address]
}

