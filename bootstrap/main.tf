terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

# Random suffix to ensure globally unique storage account name
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  region_abbr = "eus2"
  # Naming follows Azure CAF: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming
  resource_group_name  = "rg-tfstate-${var.environment}-${var.location}"
  storage_account_name = "sttfstate${var.environment}${local.region_abbr}${random_string.suffix.result}"
  container_name       = "tfstate"

  tags = {
    project     = "terraform-state"
    environment = var.environment
    managed_by  = "terraform-bootstrap"
  }
}

resource "azurerm_resource_group" "tfstate" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                          = local.storage_account_name
  resource_group_name           = azurerm_resource_group.tfstate.name
  location                      = azurerm_resource_group.tfstate.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS" # Lowest cost — single region
  account_kind                  = "StorageV2"
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = true # Required for personal use without VPN/private endpoint

  blob_properties {
    versioning_enabled = true # Protect state file from accidental overwrites
  }

  tags = local.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = local.container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
