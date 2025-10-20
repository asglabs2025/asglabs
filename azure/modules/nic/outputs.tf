output "id" {
  value = azurerm_network_interface.nic.id
}

output "private_ip" {
  value = azurerm_network_interface.nic.ip_configuration[0].private_ip_address
}
