variable "vm_name" {
  description = "Name of the virtual machine (CAF: vm-<workload>-<env>-<region>)"
  type        = string
}

variable "computer_name" {
  description = "Windows computer name (max 15 characters)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to attach the VM NIC to"
  type        = string
}

variable "nsg_name" {
  description = "Name of the NSG to add the RDP allow rule to"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store admin password"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for diagnostics"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size (B-series recommended for cost)"
  type        = string
  default     = "Standard_B2ms"
}

variable "admin_username" {
  description = "Local admin username"
  type        = string
  default     = "azureadmin"
}

variable "os_disk_type" {
  description = "OS disk storage type (StandardSSD_LRS for cost, Premium_LRS for performance)"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "allowed_rdp_source_ip" {
  description = "Public IP address allowed to RDP into the VM (CIDR, e.g. 1.2.3.4/32). Use 'Internet' to allow all (not recommended)."
  type        = string
}

variable "auto_shutdown_time" {
  description = "Daily auto-shutdown time in HHmm format (24hr, e.g. 1900 = 7 PM)"
  type        = string
  default     = "1900"
}

variable "auto_shutdown_timezone" {
  description = "Timezone for auto-shutdown schedule"
  type        = string
  default     = "Central Standard Time"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
