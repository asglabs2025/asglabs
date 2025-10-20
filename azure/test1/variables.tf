# --------------
# Tag settings
# --------------

# Base tags for all resources
variable "default_tags" {
  description  = "A map of tags to assign to Azure resources"
  type         = map(string)
  default      = {
    owner      = "aman"
    managed_by = "terraform"
 }
}

# Optional environment or project specific tags
variable "tags" {
  description  = "Additional tags defined per environment"
  type         = map(string)
  default      = {}
}

# ------------------------------------
# Azure Service Principal credentials
# ------------------------------------
variable "azure_client_id" {
  description = "The Application (client) ID of the Azure Service Principal"
  type        = string
}

variable "azure_client_secret" {
  description = "The client secret of the Azure Service Principal"
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "The Azure subscription ID where resources will be created"
  type        = string
}

variable "azure_tenant_id" {
  description = "The Azure Active Directory tenant ID"
  type        = string
}

# ------------------------
# Resource group settings
# ------------------------
variable "resource_group_name" {
  description = "The name of the resource group to create"
  type        = string
}

variable "resource_group_location" {
  description = "The Azure region where the resource group will be created"
  type        = string
}

# --------------
# VNet settings
# --------------

variable "azure_vnet_name" {
 description = "The Azure VNET name"
  type        = string
}

variable "azure_vnet_address_space" {
 description = "The Azure VNET address space"
  type        = list(string)
}

variable "azure_subnet_name" {
 description = "The Azure subnet address name"
  type        = string
}

variable "azure_subnet_address_prefix" {
 description = "The Azure subnet address prefix"
  type        = list(string)
}

# ------------
# VM settings
# ------------
variable "azure_vm_name" {
  description = "Name of the Azure VM"
  type        = string
}

variable "azure_vm_size" {
  description = "VM size/SKU"
  type        = string
}

variable "azure_admin_username" {
  description = "Local admin username"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Local admin password"
  type        = string
}

variable "os_storage_type" {
  description = "OS storage type e.g. Standard_LRS, Premium_LRS etc"
  type        = string
}

variable "image_publisher" {
  description = "OS image publisher, e.g., Canonical"
  type        = string
}

variable "image_offer" {
  description = "OS image offer, e.g., UbuntuServer"
  type        = string
}

variable "image_sku" {
  description = "OS image SKU, e.g., 20_04-lts"
  type        = string
}

variable "image_version" {
  description = "OS image version"
  type        = string
}
