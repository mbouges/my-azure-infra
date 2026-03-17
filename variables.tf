variable "project_name" {
  description = "Project or workload name used in resource naming"
  type        = string
  default     = "personal"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "address_space" {
  description = "Address space for the virtual network (CIDR notation)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "Address prefix for the default subnet (CIDR notation)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 10
}

variable "budget_contact_emails" {
  description = "Email addresses to receive budget alert notifications"
  type        = list(string)
}

variable "owner_email" {
  description = "Owner email address — used for tagging, security alerts, and budget notifications"
  type        = string
}

variable "allowed_locations" {
  description = "List of allowed Azure regions enforced by Azure Policy"
  type        = list(string)
  default     = ["eastus2", "eastus"]
}

variable "allowed_vm_skus" {
  description = "List of allowed VM SKUs to prevent expensive deployments"
  type        = list(string)
  default = [
    "Standard_B1s",
    "Standard_B1ms",
    "Standard_B2s",
    "Standard_B2ms",
    "Standard_B1ls",
    "Standard_D2s_v3",
    "Standard_D2as_v5",
    "Standard_B2ats_v2",
    "Standard_B2als_v2",
  ]
}
