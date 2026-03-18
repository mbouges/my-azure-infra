# -----------------------------------------------------------------------------
# Windows 11 VM for IDE / Development
# Self-contained in its own region: creates RG, VNet, subnet, NSG
# Cost-optimized: auto-shutdown, Standard SSD
# Trusted Launch enabled (required for Windows 11)
# Admin password stored in Key Vault (in primary region)
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

# --- Resource Group (in VM region) ---
resource "azurerm_resource_group" "vm" {
  name     = "rg-${var.project_name}-vm-${var.environment}-${var.location}"
  location = var.location
  tags     = var.tags
}

# --- VNet ---
resource "azurerm_virtual_network" "vm" {
  name                = "vnet-${var.project_name}-vm-${var.environment}-${var.location}"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  address_space       = [var.address_space]
  tags                = var.tags
}

# --- Subnet ---
resource "azurerm_subnet" "vm" {
  name                 = "snet-vm-${var.environment}-${var.location}"
  resource_group_name  = azurerm_resource_group.vm.name
  virtual_network_name = azurerm_virtual_network.vm.name
  address_prefixes     = [var.subnet_prefix]
}

# --- NSG ---
resource "azurerm_network_security_group" "vm" {
  name                = "nsg-vm-${var.environment}-${var.location}"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  tags                = var.tags
}

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
  resource_group_name         = azurerm_resource_group.vm.name
  network_security_group_name = azurerm_network_security_group.vm.name
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# --- Azure Bastion Developer (free SKU — browser-based RDP via Azure portal) ---
resource "azurerm_bastion_host" "vm" {
  name                = "bas-${var.project_name}-vm-${var.environment}-${var.location}"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  sku                 = "Developer"
  virtual_network_id  = azurerm_virtual_network.vm.id
  tags                = var.tags
}

# --- NIC (private only — Bastion provides secure access) ---
resource "azurerm_network_interface" "vm" {
  name                = "nic-${var.vm_name}"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

# --- Windows 11 VM ---
resource "azurerm_windows_virtual_machine" "this" {
  name                  = var.vm_name
  location              = azurerm_resource_group.vm.location
  resource_group_name   = azurerm_resource_group.vm.name
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
