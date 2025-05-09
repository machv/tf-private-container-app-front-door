terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.19.0"
    }

    azapi = {
      source = "azure/azapi"
    }
  }

  required_version = ">= 1.3.1" # for optional parameters
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {
}

data "azurerm_subscription" "current" {
}
