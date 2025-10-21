terraform {
  required_version = ">= 1.6.0"
  backend "azurerm" {
    resource_group_name   = "asgstorage"
    storage_account_name  = "asgstorageaccount1"
    container_name        = "terraform-state"
    key                   = "dev.terraform.tfstate"
  }
}
