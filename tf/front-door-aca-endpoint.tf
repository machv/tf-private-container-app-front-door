variable "aca_fd_endpoint_name" {
  type    = string
  default = "aca-demo"
}

resource "azurerm_cdn_frontdoor_endpoint" "aca_helloworld" {
  name                     = var.aca_fd_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
}

resource "azurerm_cdn_frontdoor_origin_group" "aca_helloworld" {
  name                     = "helloworld"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id

  load_balancing {}

  health_probe {
    protocol            = "Http"
    path                = "/"
    request_type        = "GET"
    interval_in_seconds = 60
  }
}

resource "azurerm_cdn_frontdoor_origin" "helloworld_aca" {
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aca_helloworld.id
  name                          = "aca-test-govauth"

  certificate_name_check_enabled = true
  host_name                      = azurerm_container_app.app.ingress[0].fqdn
  origin_host_header             = azurerm_container_app.app.ingress[0].fqdn
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 500
  enabled                        = true

  private_link {
    request_message        = "Front Door Private Link (${azurerm_cdn_frontdoor_profile.fd.name})"
    target_type            = "managedEnvironments"
    location               = azurerm_container_app_environment.cae.location
    private_link_target_id = azurerm_container_app_environment.cae.id
  }
}

resource "azurerm_cdn_frontdoor_route" "helloworld_aca" {
  name                          = "helloworld-aca"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.aca_helloworld.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aca_helloworld.id
  cdn_frontdoor_origin_ids = [
    azurerm_cdn_frontdoor_origin.helloworld_aca.id,
  ]
  enabled = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  link_to_default_domain = true
}
