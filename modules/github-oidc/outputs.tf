output "client_id" {
  description = "Application (client) ID for GitHub Actions OIDC — set as AZURE_CLIENT_ID secret"
  value       = azuread_application.github_actions.client_id
}

output "tenant_id" {
  description = "Entra ID tenant ID — set as AZURE_TENANT_ID secret"
  value       = data.azuread_client_config.current.tenant_id
}

output "subscription_id" {
  description = "Azure subscription ID — set as AZURE_SUBSCRIPTION_ID secret"
  value       = data.azurerm_subscription.current.subscription_id
}

output "service_principal_object_id" {
  description = "Object ID of the service principal"
  value       = azuread_service_principal.github_actions.object_id
}
