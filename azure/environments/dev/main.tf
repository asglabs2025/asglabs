terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
  required_version = ">= 1.6.0"
}

provider "azurerm" {
  features {}

  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

# ------------------------------
# Resource Group
# ------------------------------
module "rg" {
  source   = "../../modules/resource-group"
  name     = var.resource_group_name
  location = var.resource_group_location
  default_tags = var.default_tags
  tags         = var.tags
}

# ------------------------------
# Network (VNet + Subnet)
# ------------------------------
module "network" {
  source              = "../../modules/network"
  name                = var.azure_vnet_name
  resource_group_name = module.rg.name
  location            = module.rg.location
  address_space       = var.azure_vnet_address_space
  subnet_name         = var.azure_subnet_name
  subnet_prefixes     = var.azure_subnet_address_prefix
  default_tags        = var.default_tags
  tags                = var.tags
}

# ------------------------------
# NIC
# ------------------------------
module "nic" {
  source              = "../../modules/nic"
  name                = var.azure_vm_name
  location            = module.rg.location
  resource_group_name = module.rg.name
  subnet_id           = module.network.subnet_id
  default_tags        = var.default_tags
  tags                = var.tags
}

# ------------------------------
# VM
# ------------------------------
module "vm" {
  source              = "../../modules/vm"
  name                = var.azure_vm_name
  location            = module.rg.location
  resource_group_name = module.rg.name
  nic_id              = module.nic.id
  size                = var.azure_vm_size
  admin_username      = var.azure_admin_username
  ssh_public_key_path = var.ssh_public_key_path
  os_storage_type     = var.os_storage_type
  image_publisher     = var.image_publisher
  image_offer         = var.image_offer
  image_sku           = var.image_sku
  image_version       = var.image_version
  default_tags        = var.default_tags
  tags                = var.tags
}
