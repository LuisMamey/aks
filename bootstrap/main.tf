terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "Azure Subscription ID where the state backend will live."
  type        = string
}

variable "location" {
  description = "Azure region for the state backend."
  type        = string
  default     = "eastus2"
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-tfstate"
  location = var.location
}

resource "azurerm_storage_account" "tfstate" {
  #checkov:skip=CKV_AZURE_59:Accepted risk — see docs/adr/0001-bootstrap-state-hardening-scope.md
  #checkov:skip=CKV2_AZURE_33:Accepted risk — see docs/adr/0001-bootstrap-state-hardening-scope.md
  #checkov:skip=CKV2_AZURE_40:Accepted risk — see docs/adr/0001-bootstrap-state-hardening-scope.md
  #checkov:skip=CKV2_AZURE_1:Accepted risk — see docs/adr/0001-bootstrap-state-hardening-scope.md
  #checkov:skip=CKV_AZURE_33:Accepted risk — see docs/adr/0001-bootstrap-state-hardening-scope.md
  name                            = "sttfstateluismamey01"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  sas_policy {
    expiration_period = "00.01:00:00"
    expiration_action = "Log"
  }
}

resource "azurerm_storage_container" "tfstate" {
  #checkov:skip=CKV2_AZURE_21:Accepted risk — see docs/adr/0001-bootstrap-state-hardening-scope.md
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
