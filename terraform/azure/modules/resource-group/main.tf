resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.location
  tags     = merge(var.default_tags, var.tags)
}
