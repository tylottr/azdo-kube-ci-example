provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

provider "azuread" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
