output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.this.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "default_subnet_id" {
  description = "ID of the default subnet"
  value       = azurerm_subnet.default.id
}

output "default_subnet_name" {
  description = "Name of the default subnet"
  value       = azurerm_subnet.default.name
}

output "default_nsg_id" {
  description = "ID of the default network security group"
  value       = azurerm_network_security_group.default.id
}
