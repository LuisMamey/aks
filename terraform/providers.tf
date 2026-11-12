terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateluismamey01"
    container_name       = "tfstate"
    key                  = "aks-metrics.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
