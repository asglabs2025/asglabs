variable "node" {
  description = "The Proxmox node where the VM will be deployed"
  default     = "pve"
}

variable "machine_name" {
  description = "The name to assign to the VM"
  default     = "Controller-VM"
}

variable "machine" {
  description = "The machine type for the VM (e.g., q35 or i440fx)"
  default     = "q35"
}

variable "memory" {
  description = "Amount of RAM allocated to the VM in MB"
  default     = "4096"
}

locals {
  description = "${var.machine_name}"
}

variable "cores" {
  description = "Number of CPU cores assigned to the VM"
  default     = "2"
}

variable "disk_size" {
  description = "Size of the primary disk for the VM"
  default     = "30G"
}

variable "disk_storage" {
  description = "The storage location in Proxmox for the VM disk"
  default     = "M2"
}

variable "disk_iso" {
  description = "Path to the ISO image used for OS installation"
  default     = "isos:iso/Win11_24H2_EnglishInternational_x64.iso"
}

variable "bridge" {
  description = "Network bridge the VM will connect to"
  default     = "vmbr0"
}

variable "vlan" {
  description = "VLAN ID for the VM's network interface"
  default     = "50"
}
