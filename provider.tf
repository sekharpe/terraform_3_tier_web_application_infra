terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.1.0"
    }
  }
}

# provider "azurerm" {

# }
# terraform {
#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = "~>3.0"
#     }
#   }
#   backend "azurerm" {
#       resource_group_name  = "tfstate"
#       storage_account_name = "<storage_account_name>"
#       container_name       = "tfstate"
#       key                  = "terraform.tfstate"
#   }

#}

provider "azurerm" {
  features {}
  subscription_id = "88416177-e521-4d58-b91e-c5be2a680dbf"
}


resource "azurerm_resource_group" "state-demo-secure" {
  name     = "state-demo"
  location = "eastus"
}
