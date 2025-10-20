variable "name" {
  description = "Name of the VM"
  type        = string
}

variable "location" {
  description = "Azure region for the VM"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the VM"
  type        = string
}

variable "nic_id" {
  description = "Network Interface ID to attach to the VM"
  type        = string
}

variable "size" {
  description = "VM size"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the admin SSH public key"
  type        = string
}

variable "os_storage_type" {
  description = "OS disk storage type (e.g., Premium_LRS)"
  type        = string
}

variable "image_publisher" {
  description = "VM image publisher"
  type        = string
}

variable "image_offer" {
  description = "VM image offer"
  type        = string
}

variable "image_sku" {
  description = "VM image SKU"
  type        = string
}

variable "image_version" {
  description = "VM image version"
  type        = string
}

variable "default_tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}
