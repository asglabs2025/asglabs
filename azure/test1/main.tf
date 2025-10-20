terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.3.0"
}

# ---------------------------------------
# Azure Provider using Service Principal
# ---------------------------------------
provider "azurerm" {
  features {}

  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

# ------------------------------
# Create a Resource Group
# ------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location

  tags     = merge(var.default_tags, var.tags)
}

# ------------------------------
# Create a Virtual Network
# ------------------------------
resource "azurerm_virtual_network" "vnet1" {
  name                = var.azure_vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.azure_vnet_address_space

  tags                = merge(var.default_tags, var.tags)
}

# ------------------------------
# Create a Subnet in the VNET
# ------------------------------
resource "azurerm_subnet" "subnet1" {
  name                 = var.azure_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name 
  virtual_network_name = azurerm_virtual_network.vnet1.name 
  address_prefixes     = var.azure_subnet_address_prefix
}

# -----------------------------------
# Create a NIC in the Resource Group
# -----------------------------------
resource "azurerm_network_interface" "nic" {
  name                = "${var.azure_vm_name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"

  } 
  tags     = merge(var.default_tags, var.tags)
}

# -----------------------------------
# Create a VM in the Resource Group
# -----------------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.azure_vm_name
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = var.azure_vm_size
  admin_username                  = var.azure_admin_username
  disable_password_authentication = true
  
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  # Admin SSH Key
  admin_ssh_key {
    username   = var.azure_admin_username
    public_key = file(var.ssh_public_key_path)
  }
  # OS disk configuration
  os_disk {
    name                          = "${var.azure_vm_name}-osdisk"  
    caching                       = "ReadWrite"
    storage_account_type          = var.os_storage_type
  }
  # Optional: delete data disks when VM is deleted
  # delete_data_disks_on_termination = true
  
  # Source Image
  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

    tags     = merge(var.default_tags, var.tags)

}


