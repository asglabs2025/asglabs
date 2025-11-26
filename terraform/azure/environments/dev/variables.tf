# Azure provider credentials
variable "azure_client_id" {}
variable "azure_client_secret" {}
variable "azure_subscription_id" {}
variable "azure_tenant_id" {}

# Resource group
variable "resource_group_name" {}
variable "resource_group_location" {}

# Virtual network
variable "azure_vnet_name" {}
variable "azure_vnet_address_space" {
  type = list(string)
}
variable "azure_subnet_name" {}
variable "azure_subnet_address_prefix" {
  type = list(string)
}

# VM
variable "azure_vm_name" {}
variable "azure_vm_size" {}
variable "azure_admin_username" {}
variable "ssh_public_key_path" {}
variable "os_storage_type" {}
variable "image_publisher" {}
variable "image_offer" {}
variable "image_sku" {}
variable "image_version" {}

# Tags
variable "default_tags" {
  type    = map(string)
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
