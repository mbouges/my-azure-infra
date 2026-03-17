# -----------------------------------------------------------------------------
# Microsoft Defender for Cloud — Free tier only
# Provides security posture management (CSPM) at no cost.
# -----------------------------------------------------------------------------

data "azurerm_subscription" "current" {}

# Enable the free tier for key resource types
# The free tier includes: Security recommendations, Secure Score, Azure Security Benchmark
resource "azurerm_security_center_subscription_pricing" "vms" {
  tier          = "Free"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "storage" {
  tier          = "Free"
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_subscription_pricing" "keyvaults" {
  tier          = "Free"
  resource_type = "KeyVaults"
}

resource "azurerm_security_center_subscription_pricing" "arm" {
  tier          = "Free"
  resource_type = "Arm"
}

# Auto-provision is deprecated in azurerm 4.x — Defender manages this natively

# Set security contact for alerts
resource "azurerm_security_center_contact" "main" {
  name                = "default"
  email               = var.security_contact_email
  alert_notifications = true
  alerts_to_admins    = true
}
