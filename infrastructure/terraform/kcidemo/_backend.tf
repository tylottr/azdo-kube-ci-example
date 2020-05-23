terraform {
  backend "azurerm" {
    # storage_account_name = "REPLACE_WITH_STORAGE_ACCOUNT_NAME"
    container_name = "tfstate"
    key            = "kcidemo/tfstate"
  }
}
