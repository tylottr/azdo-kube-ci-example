resource "azurerm_resource_group" "main" {
  name     = var.resource_prefix
  location = var.location
  tags     = var.tags
}
