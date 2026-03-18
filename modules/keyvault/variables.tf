variable "project_name" {
  description = "Project or workload name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "region_abbr" {
  description = "Abbreviated region name for resource naming (e.g., eus2 for eastus2)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy into"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for diagnostic logs"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "owner_object_id" {
  description = "Entra ID object ID of the user who should be Key Vault Administrator"
  type        = string
}

variable "tenant_id" {
  description = "Entra ID tenant ID"
  type        = string
}
