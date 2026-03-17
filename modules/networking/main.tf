resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.project_name}-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "default" {
  name                            = "snet-default-${var.environment}-${var.location}"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [var.subnet_prefix]
  default_outbound_access_enabled = false
}

resource "azurerm_network_security_group" "default" {
  name                = "nsg-default-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Deny all inbound from internet by default — explicit allow rules should be added as needed
resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                        = "DenyAllInbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.default.name
}

resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.default.id
}

# Enable diagnostic logging for the VNet to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "diag-${azurerm_virtual_network.this.name}"
  target_resource_id         = azurerm_virtual_network.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "VMProtectionAlerts"
  }
}

# Enable diagnostic logging for the NSG (flow analytics)
resource "azurerm_monitor_diagnostic_setting" "nsg" {
  name                       = "diag-${azurerm_network_security_group.default.name}"
  target_resource_id         = azurerm_network_security_group.default.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
