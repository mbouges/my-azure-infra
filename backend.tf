# Remote backend using Azure Storage created by the bootstrap configuration.
# Update the values below after running bootstrap/terraform apply.
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-dev-eastus2"
    storage_account_name = "sttfstatedeveus221b6"
    container_name       = "tfstate"
    key                  = "personal.terraform.tfstate"
  }
}
