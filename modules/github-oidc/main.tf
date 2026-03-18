# -----------------------------------------------------------------------------
# GitHub Actions OIDC Identity for Terraform CI/CD
# Creates an Entra ID app registration with federated credentials trusted by
# GitHub Actions, plus subscription-level role assignments.
# No secrets — uses OpenID Connect (OIDC) token exchange.
# -----------------------------------------------------------------------------

data "azurerm_subscription" "current" {}

# --- Entra ID Application Registration ---
# Owners are managed out-of-band (user + SP) so the SP can manage its own app via OIDC.
resource "azuread_application" "github_actions" {
  display_name = "sp-${var.project_name}-github-actions-${var.environment}"

  owners = [var.owner_object_id]

  # MS Graph: Application.ReadWrite.OwnedBy — lets the SP manage its own app registration
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "18a4783c-866b-4cc7-a460-3d5e5662c884" # Application.ReadWrite.OwnedBy
      type = "Role"
    }
  }

  lifecycle {
    ignore_changes = [owners]
  }
}

# --- Service Principal ---
resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id

  owners = [var.owner_object_id]
}

# --- Federated Credential: PR branches ---
resource "azuread_application_federated_identity_credential" "github_pr" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-pr"
  description    = "Trust GitHub Actions OIDC tokens from pull requests"

  audiences = ["api://AzureADTokenExchange"]
  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:${var.github_org}/${var.github_repo}:pull_request"
}

# --- Federated Credential: main branch (for apply without environment) ---
resource "azuread_application_federated_identity_credential" "github_main" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-main"
  description    = "Trust GitHub Actions OIDC tokens from main branch"

  audiences = ["api://AzureADTokenExchange"]
  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
}

# --- Federated Credential: production environment (for apply with environment) ---
resource "azuread_application_federated_identity_credential" "github_environment_production" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-environment-production"
  description    = "Trust GitHub Actions OIDC tokens from production environment"

  audiences = ["api://AzureADTokenExchange"]
  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:${var.github_org}/${var.github_repo}:environment:production"
}

# --- Role Assignments on Subscription ---
# Contributor: create/manage resources
resource "azurerm_role_assignment" "contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# User Access Administrator: manage role assignments (for Key Vault RBAC, policy identity, etc.)
resource "azurerm_role_assignment" "user_access_admin" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Storage Blob Data Contributor: read/write Terraform state
resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Key Vault Secrets Officer: manage secrets (e.g., VM admin passwords)
resource "azurerm_role_assignment" "keyvault_secrets_officer" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azuread_service_principal.github_actions.object_id
}
