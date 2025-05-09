data "azapi_resource_list" "cae_private_endpoints" {
  type                   = "Microsoft.App/managedEnvironments/privateEndpointConnections@2024-10-02-preview"
  parent_id              = azurerm_container_app_environment.cae.id
  response_export_values = ["value"]

  depends_on = [
    azapi_resource.uep_test_govauth_aca
  ]
}

locals {
  parsed_json             = (data.azapi_resource_list.cae_private_endpoints.output)
  pending_items           = [for item in local.parsed_json.value : item.properties.privateLinkServiceConnectionState.status == "Pending" ? item : null]
  compacted_pending_items = [for item in local.pending_items : item if item != null]
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
    data.azapi_resource_list.cae_private_endpoints
  ]

  lifecycle {
    ignore_changes = [name]
  }
}
