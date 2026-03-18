# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------
output "resource_group_name" {
  description = "Name of the main resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the main resource group"
  value       = azurerm_resource_group.main.id
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "default_subnet_id" {
  description = "ID of the default subnet"
  value       = module.networking.default_subnet_id
}

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------
output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.keyvault.key_vault_uri
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

# -----------------------------------------------------------------------------
# GitHub Actions OIDC (set these as GitHub repository secrets)
# -----------------------------------------------------------------------------
output "github_actions_client_id" {
  description = "AZURE_CLIENT_ID — set as GitHub Actions secret"
  value       = module.github_oidc.client_id
}

output "github_actions_tenant_id" {
  description = "AZURE_TENANT_ID — set as GitHub Actions secret"
  value       = module.github_oidc.tenant_id
}

output "github_actions_subscription_id" {
  description = "AZURE_SUBSCRIPTION_ID — set as GitHub Actions secret"
  value       = module.github_oidc.subscription_id
}

# -----------------------------------------------------------------------------
# Dev VM
# -----------------------------------------------------------------------------
output "vm_bastion_name" {
  description = "Bastion host name — connect via Azure portal"
  value       = module.compute.bastion_name
}

output "vm_admin_username" {
  description = "Admin username for RDP"
  value       = module.compute.admin_username
}

output "vm_admin_password_secret" {
  description = "Key Vault secret name containing the admin password"
  value       = module.compute.admin_password_secret_name
}
