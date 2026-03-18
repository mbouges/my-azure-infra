output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.this.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.this.name
}

output "public_ip_address" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.vm.ip_address
}

output "private_ip_address" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.vm.private_ip_address
}

output "admin_username" {
  description = "Admin username for RDP"
  value       = var.admin_username
}

output "admin_password_secret_name" {
  description = "Key Vault secret name containing the admin password"
  value       = azurerm_key_vault_secret.admin_password.name
}
