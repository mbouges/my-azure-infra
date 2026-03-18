output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.this.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.this.name
}

output "resource_group_name" {
  description = "Name of the VM resource group"
  value       = azurerm_resource_group.vm.name
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

output "bastion_name" {
  description = "Name of the Bastion host (connect via Azure portal)"
  value       = azurerm_bastion_host.vm.name
}
