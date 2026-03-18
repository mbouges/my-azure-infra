variable "project_name" {
  description = "Project or workload name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "owner_object_id" {
  description = "Entra ID object ID of the user who owns the app registration"
  type        = string
}
