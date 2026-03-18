resource "azurerm_key_vault" "this" {
  name                       = "kv-${var.project_name}-${var.environment}-${var.region_abbr}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard" # Cost-optimized: standard tier
  purge_protection_enabled   = false      # Personal env — allow cleanup
  soft_delete_retention_days = 7          # Minimum retention to reduce accidental cost

  # Network rules — allow access from Azure services and your IP
  network_acls {
    default_action = "Allow" # Personal env — open for convenience
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# Grant the deploying principal Key Vault Administrator role
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.owner_object_id
}

# Enable diagnostic logging to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "diag-${azurerm_key_vault.this.name}"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }
}
