# -----------------------------------------------------------------------------
# CAF-Lite Governance: Azure Policy Assignments (subscription-level)
# All built-in policies — no cost.
# -----------------------------------------------------------------------------

data "azurerm_subscription" "current" {}

# --- Require a tag on resource groups ---
resource "azurerm_subscription_policy_assignment" "require_env_tag_rg" {
  name                 = "require-environment-tag-rg"
  display_name         = "Require 'environment' tag on resource groups"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"

  parameters = jsonencode({
    tagName = { value = "environment" }
  })
}

resource "azurerm_subscription_policy_assignment" "require_managed_by_tag_rg" {
  name                 = "require-managed-by-tag-rg"
  display_name         = "Require 'managed_by' tag on resource groups"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"

  parameters = jsonencode({
    tagName = { value = "managed_by" }
  })
}

# --- Inherit tags from resource group ---
resource "azurerm_subscription_policy_assignment" "inherit_env_tag" {
  name                 = "inherit-environment-tag"
  display_name         = "Inherit 'environment' tag from resource group if missing"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54"
  location             = var.location # Required for managed identity

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    tagName = { value = "environment" }
  })
}

resource "azurerm_subscription_policy_assignment" "inherit_managed_by_tag" {
  name                 = "inherit-managed-by-tag"
  display_name         = "Inherit 'managed_by' tag from resource group if missing"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54"
  location             = var.location # Required for managed identity

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    tagName = { value = "managed_by" }
  })
}

# --- Allowed locations (restrict to cost-effective regions) ---
resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  display_name         = "Restrict resource locations"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

# --- Deny expensive VM SKUs (cost guardrail) ---
resource "azurerm_subscription_policy_assignment" "allowed_vm_skus" {
  count = length(var.allowed_vm_skus) > 0 ? 1 : 0

  name                 = "allowed-vm-skus"
  display_name         = "Restrict VM sizes to cost-effective SKUs"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3"

  parameters = jsonencode({
    listOfAllowedSKUs = { value = var.allowed_vm_skus }
  })
}

# --- Require secure transfer for storage accounts ---
resource "azurerm_subscription_policy_assignment" "secure_transfer_storage" {
  name                 = "require-secure-transfer-storage"
  display_name         = "Require secure transfer for storage accounts"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
}
