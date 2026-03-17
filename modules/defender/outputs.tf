output "defender_pricing_tiers" {
  description = "Map of resource types to their Defender pricing tiers"
  value = {
    virtual_machines = azurerm_security_center_subscription_pricing.vms.tier
    storage_accounts = azurerm_security_center_subscription_pricing.storage.tier
    key_vaults       = azurerm_security_center_subscription_pricing.keyvaults.tier
    arm              = azurerm_security_center_subscription_pricing.arm.tier
  }
}
