# Config
terraform {
  required_version = ">= 0.12.24"

  required_providers {
    azurerm = ">= 2.9"
    azuread = ">= 0.10"
  }
}

# Providers
provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

provider "azuread" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
