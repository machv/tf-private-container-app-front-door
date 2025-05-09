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

variable "cae_resource_group_name" {
  description = "Name for automatically created resource group for the container app environment"
  type    = string
  default = "aca-fd-demo-cae-001"
}

variable "vnet_name" {
  default     = "vnet-app-011"
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
      name             = "ServersSubnet001"
      address_prefixes = ["10.201.8.0/26"]
    },
    {
      name             = "ContainerAppsSubnet001"
      address_prefixes = ["10.201.8.64/26"]
      delegations = [
        "Microsoft.App/environments"
      ]
    },
  ]
}


