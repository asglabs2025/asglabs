variable "name" {
  description = "Base name for the NIC"
  type        = string
}

variable "location" {
  description = "Azure region for the NIC"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the NIC"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to attach the NIC"
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
