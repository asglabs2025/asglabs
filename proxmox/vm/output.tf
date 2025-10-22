output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_vm_qemu.vm.id
}

output "vm_name" {
  description = "The hostname of the VM"
  value       = proxmox_vm_qemu.vm.name
}

output "vm_status" {
  description = "The status of the VM (running/stopped)"
  value       = proxmox_vm_qemu.vm.vm_state
}

output "vm_iso" {
  description = "The iso used for the VM"
  value       = proxmox_vm_qemu.vm.disk[1].iso
}

output "vm_node" {
  description = "The Proxmox node where the VM was created"
  value       = proxmox_vm_qemu.vm.target_node
}

