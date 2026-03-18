locals {
  # Region abbreviation map for resource names with character limits (e.g., Key Vault max 24 chars)
  region_abbr = {
    eastus    = "eus"
    eastus2   = "eus2"
    westus    = "wus"
    westus2   = "wus2"
    westus3   = "wus3"
    centralus = "cus"
  }

  abbr = lookup(local.region_abbr, var.location, var.location)

  # CAF-Lite: Standard tagging taxonomy enforced by Azure Policy
  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
    owner       = var.owner_email
    cost_center = "personal"
  }
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}-${var.location}"
  location = var.location
  tags     = local.tags
}

# -----------------------------------------------------------------------------
# Log Analytics Workspace — Free tier (500 MB/day ingestion)
# -----------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${var.environment}-${var.location}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018" # Free tier is no longer a SKU; use PerGB2018 with daily cap
  retention_in_days   = 30          # Minimum retention to minimize cost
  daily_quota_gb      = 0.5         # Cap at 500 MB/day to stay within free allowance
  tags                = local.tags
}

# -----------------------------------------------------------------------------
# Networking Module
# -----------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  project_name               = var.project_name
  environment                = var.environment
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  address_space              = var.address_space
  subnet_prefix              = var.subnet_prefix
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = local.tags
}

# -----------------------------------------------------------------------------
# Key Vault Module
# -----------------------------------------------------------------------------
module "keyvault" {
  source = "./modules/keyvault"

  project_name               = var.project_name
  environment                = var.environment
  location                   = azurerm_resource_group.main.location
  region_abbr                = local.abbr
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = local.tags
  owner_object_id            = var.owner_object_id
  tenant_id                  = data.azurerm_subscription.current.tenant_id
}

# -----------------------------------------------------------------------------
# Governance Module — Azure Policy (CAF-Lite)
# -----------------------------------------------------------------------------
module "governance" {
  source = "./modules/governance"

  location          = var.location
  allowed_locations = var.allowed_locations
  allowed_vm_skus   = var.allowed_vm_skus
}

# -----------------------------------------------------------------------------
# Defender for Cloud — Free tier (CAF-Lite security baseline)
# -----------------------------------------------------------------------------
module "defender" {
  source = "./modules/defender"

  security_contact_email = var.owner_email
}

# -----------------------------------------------------------------------------
# GitHub Actions OIDC Identity (Entra ID)
# -----------------------------------------------------------------------------
module "github_oidc" {
  source = "./modules/github-oidc"

  project_name    = var.project_name
  environment     = var.environment
  github_org      = var.github_org
  github_repo     = var.github_repo
  owner_object_id = var.owner_object_id
}

# -----------------------------------------------------------------------------
# Budget Alert — notify when spending approaches limit
# -----------------------------------------------------------------------------
data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-${var.project_name}-${var.environment}-monthly"
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 50
    threshold_type = "Actual"

    contact_emails = var.budget_contact_emails
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 80
    threshold_type = "Actual"

    contact_emails = var.budget_contact_emails
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 100
    threshold_type = "Forecasted"

    contact_emails = var.budget_contact_emails
  }

  lifecycle {
    ignore_changes = [time_period] # Prevent drift on start_date after initial creation
  }
}
