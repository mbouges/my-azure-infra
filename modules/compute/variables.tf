variable "project_name" {
  description = "Project or workload name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vm_name" {
  description = "Name of the virtual machine (CAF: vm-<workload>-<env>-<region>)"
  type        = string
}

variable "computer_name" {
  description = "Windows computer name (max 15 characters)"
  type        = string
}

variable "location" {
  description = "Azure region for the VM and its networking"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store admin password (can be in a different region)"
  type        = string
}

variable "address_space" {
  description = "Address space for the VM VNet (CIDR notation)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_prefix" {
  description = "Address prefix for the VM subnet (CIDR notation)"
  type        = string
  default     = "10.1.1.0/24"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D2s_v3"
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
