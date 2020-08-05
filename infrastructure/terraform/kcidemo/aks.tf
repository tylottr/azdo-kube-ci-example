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
}
