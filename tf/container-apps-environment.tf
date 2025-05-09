locals {
  cae_log_name              = "log-cae-001"
  cae_name                  = "cae-001"
  cae_managed_identity_name = "mi-cae-001"
  container_app_name        = "aca-helloworld-001"
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

resource "azurerm_container_app" "app" {
  name                         = local.container_app_name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  template {
    container {
      name   = "quickstart"
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    target_port      = 80
    external_enabled = true
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  lifecycle {
    ignore_changes = [
      template,
      ingress,
      secret,
      registry,
      revision_mode,
    ]
  }
}
