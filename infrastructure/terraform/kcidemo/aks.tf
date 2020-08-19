###############
# Module - AKS
###############

module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  resource_prefix = var.resource_prefix
  tags            = var.tags

  enable_acr       = true
  enable_acr_admin = true

  aks_kubernetes_version = "latest"

  // Explicit dependency on azurerm_resource_group.main used due to a problem with the
  // module not picking up the implicit dependency.
  depends_on = [azurerm_resource_group.main]
}
