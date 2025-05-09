variable "location" {
  description = "Specifies the location for the resource group and all the resources"
  default     = "swedencentral"
  type        = string
}

variable "resource_group_name" {
  description = "Specifies the resource group name"
  default     = "aca-fd-demo"
  type        = string
}

variable "vnet_name" {
  description = "Specifies the name of the hub virtual virtual network"
  default     = "vnet-spoke"
  type        = string
}

variable "vnet_address_space" {
  description = "Specifies the address space of the hub virtual virtual network"
  default     = ["10.201.8.0/24"]
  type        = list(string)
}

variable "vnet_subnets" {
  type = list(object({
    name                                          = string
    address_prefixes                              = list(string)
    private_endpoint_network_policies_enabled     = optional(bool, false)
    private_link_service_network_policies_enabled = optional(bool, false)
    delegations                                   = optional(list(string), [])
  }))
  default = [
  {
    name             = "PrivateEndpointSubnet001"
    address_prefixes = ["10.201.8.64/26"]
  },
  {
    name             = "ContainerAppsSubnet001"
    address_prefixes = ["10.201.8.128/26"]
    delegations = [
      "Microsoft.App/environments"
    ]
  },
]
}

variable "cae_resource_group_name" {
  type    = string
  default = "aca-fd-demo-cae-001"
}

variable "front_door_name" {
  type = string
  default = "001"
}

variable "container_app_name" {
  type = string
  default = "helloworld"
}
