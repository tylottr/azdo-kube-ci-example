terraform {
  backend "azurerm" {
    # storage_account_name = "changeme"
    container_name = "tfstate"
    key            = "terraform/kcidemo/terraform.tfstate"
  }
}
