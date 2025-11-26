# ------------------------------
# Resource Group outputs
# ------------------------------
output "resource_group_name" {
  value = module.rg.name
}

# ------------------------------
# Network outputs
# ------------------------------
output "vnet_name" {
  value = module.network.vnet_name
}

output "subnet_id" {
  value = module.network.subnet_id
}

# ------------------------------
# NIC outputs
# ------------------------------
output "nic_id" {
  value = module.nic.id
}

output "nic_private_ip" {
  value = module.nic.private_ip
}

# ------------------------------
# VM outputs
# ------------------------------
output "vm_id" {
  value = module.vm.id
}

output "vm_name" {
  value = module.vm.name
}
