output "policy_assignment_ids" {
  description = "Map of policy assignment names to their IDs"
  value = {
    require_env_tag_rg      = azurerm_subscription_policy_assignment.require_env_tag_rg.id
    require_managed_by_rg   = azurerm_subscription_policy_assignment.require_managed_by_tag_rg.id
    inherit_env_tag         = azurerm_subscription_policy_assignment.inherit_env_tag.id
    inherit_managed_by_tag  = azurerm_subscription_policy_assignment.inherit_managed_by_tag.id
    allowed_locations       = azurerm_subscription_policy_assignment.allowed_locations.id
    secure_transfer_storage = azurerm_subscription_policy_assignment.secure_transfer_storage.id
  }
}
