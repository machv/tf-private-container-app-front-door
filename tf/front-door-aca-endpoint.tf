variable "uep_govauth_test_fd_endpoint_name" {
  type = string
  default = "aca-demo"
}

resource "azurerm_cdn_frontdoor_endpoint" "uep_test_govauth" {
  name                     = var.uep_govauth_test_fd_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
}

resource "azurerm_cdn_frontdoor_origin_group" "uep_test_govauth" {
  name                     = "uep-test-govauth"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id

  load_balancing {}

  health_probe {
    protocol            = "Http"
    path                = "/"
    request_type        = "GET"
    interval_in_seconds = 60
  }
}

resource "azapi_resource" "uep_test_govauth_aca" {
  type      = "Microsoft.Cdn/profiles/origingroups/origins@2024-09-01"
  name      = "aca-test-govauth"
  parent_id = azurerm_cdn_frontdoor_origin_group.uep_test_govauth.id

  body = {
    properties = {
      hostName                    = azurerm_container_app.app.ingress[0].fqdn
      httpPort                    = 80
      httpsPort                   = 443
      originHostHeader            = azurerm_container_app.app.ingress[0].fqdn
      priority                    = 1
      weight                      = 500
      enabledState                = "Enabled"
      enforceCertificateNameCheck = true
      sharedPrivateLinkResource = {
        privateLink = {
          id = azurerm_container_app_environment.cae.id
        }
        groupId             = "managedEnvironments"
        privateLinkLocation = azurerm_container_app_environment.cae.location
        requestMessage      = "Front Door Private Link (${azurerm_cdn_frontdoor_profile.fd.name})"
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "uep_test_govauth_aca" {
  name                          = "uep-test-govauth-aca"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.uep_test_govauth.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.uep_test_govauth.id
  cdn_frontdoor_origin_ids      = [azapi_resource.uep_test_govauth_aca.id]
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  link_to_default_domain          = true
}
