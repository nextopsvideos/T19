terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.4.0"
    }
  }

   backend "azurerm" {
    resource_group_name = "NextOps"
    storage_account_name = "nextopstfsa19"
    container_name = "tfstate"
    key = "PROD/prod.tfstate"
    access_key = "GOULKG/0MnQFx8LXmUvyAKn05X2PrsT7L/btMKpFOm8kRqrKsTf6gTJZ1+Vd5CZmFxjVwPi9xbq4+AStTd1z8g=="
  }
}

provider "azurerm" {
    features {}      
    subscription_id = "a355c32e-4a22-4b05-aab4-be236850fa6e"  
}

module "prod" {
    source = "../../vnet_module"
    rg_name             = "ProdRG"
    rg_location         = "WestUS"
    vnet_name           = "ProdVNET"
    vnet_addr_space     = [ "10.20.0.0/16" ]
    subnet1_name        = "prodsubnet01"
    subnet1_addr_prefix = [ "10.20.0.0/24" ]
    vm_name             = "ProdLVM01"
    vm_size             = "Standard_B2s"
    nic_name            = "prodnic1"  
}