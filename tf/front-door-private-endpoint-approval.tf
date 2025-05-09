data "azapi_resource_list" "cae_private_endpoints" {
  type                   = "Microsoft.App/managedEnvironments/privateEndpointConnections@2024-10-02-preview"
  parent_id              = azurerm_container_app_environment.cae.id
  response_export_values = ["value"]

  depends_on = [
    azurerm_cdn_frontdoor_origin.helloworld_aca
  ]
}

locals {
  pending_items           = [for item in data.azapi_resource_list.cae_private_endpoints.output.value : item.properties.privateLinkServiceConnectionState.status == "Pending" ? item : null]
  compacted_pending_items = [for item in local.pending_items : item if item != null]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [data.azapi_resource_list.cae_private_endpoints]

  create_duration = "30s"
}

resource "azapi_update_resource" "approval" {
  type      = "Microsoft.App/managedEnvironments/privateEndpointConnections@2024-10-02-preview"
  name      = try(local.compacted_pending_items[0].name, "dummy")
  parent_id = azurerm_container_app_environment.cae.id

  body = {
    properties = {
      privateLinkServiceConnectionState = {
        description = "Approved via Terraform"
        status      = "Approved"
      }
    }
  }

  depends_on = [
    data.azapi_resource_list.cae_private_endpoints,
    time_sleep.wait_30_seconds,
  ]

  lifecycle {
    ignore_changes = [
      name,
      output,
      body.properties.privateLinkServiceConnectionState.description,
    ]
  }
}
