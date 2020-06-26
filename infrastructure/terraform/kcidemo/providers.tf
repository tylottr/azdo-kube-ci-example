# Config
terraform {
  required_version = ">= 0.12.28"

  required_providers {
    azurerm = ">= 2.9"
  }
}

# Providers
provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
