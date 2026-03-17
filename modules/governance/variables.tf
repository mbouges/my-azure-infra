variable "location" {
  description = "Azure region (required for policy assignments with managed identity)"
  type        = string
}

variable "allowed_locations" {
  description = "List of allowed Azure regions for resource deployment"
  type        = list(string)
  default     = ["eastus2", "eastus"]
}

variable "allowed_vm_skus" {
  description = "List of allowed VM SKUs to prevent expensive deployments. Empty list disables the policy."
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
