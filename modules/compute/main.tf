# -----------------------------------------------------------------------------
# Windows 11 VM for IDE / Development
# Cost-optimized: B-series burstable, Standard SSD, auto-shutdown
# Trusted Launch enabled (required for Windows 11)
# Admin password stored in Key Vault
# -----------------------------------------------------------------------------

resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "!@#$%&*()-_=+[]{}|;:,.<>?"
}

resource "azurerm_key_vault_secret" "admin_password" {
  name         = "${var.vm_name}-admin-password"
  value        = random_password.admin.result
  key_vault_id = var.key_vault_id
}

# --- Public IP ---
resource "azurerm_public_ip" "vm" {
  name                = "pip-${var.vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# --- NIC ---
resource "azurerm_network_interface" "vm" {
  name                = "nic-${var.vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

# --- NSG Rule: Allow RDP from specific IP ---
resource "azurerm_network_security_rule" "allow_rdp" {
  name                        = "AllowRDP-${var.vm_name}"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = var.allowed_rdp_source_ip
  destination_address_prefix  = azurerm_network_interface.vm.private_ip_address
  resource_group_name         = var.resource_group_name
  network_security_group_name = var.nsg_name
}

# --- Windows 11 VM ---
resource "azurerm_windows_virtual_machine" "this" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = random_password.admin.result
  network_interface_ids = [azurerm_network_interface.vm.id]
  computer_name         = var.computer_name
  tags                  = var.tags

  # Trusted Launch — required for Windows 11
  secure_boot_enabled = true
  vtpm_enabled        = true

  os_disk {
    name                 = "osdisk-${var.vm_name}"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-24h2-ent"
    version   = "latest"
  }

  # Auto-shutdown to save cost
  lifecycle {
    ignore_changes = [admin_password]
  }
}

# --- Auto-shutdown schedule ---
resource "azurerm_dev_test_global_vm_shutdown_schedule" "this" {
  virtual_machine_id    = azurerm_windows_virtual_machine.this.id
  location              = var.location
  enabled               = true
  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.auto_shutdown_timezone

  notification_settings {
    enabled = false
  }

  tags = var.tags
}

# --- Diagnostic settings for NIC ---
resource "azurerm_monitor_diagnostic_setting" "nic" {
  name                       = "diag-${azurerm_network_interface.vm.name}"
  target_resource_id         = azurerm_network_interface.vm.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric {
    category = "AllMetrics"
  }
}
