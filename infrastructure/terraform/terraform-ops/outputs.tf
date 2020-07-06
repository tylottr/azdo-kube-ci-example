output "terraform_group_id" {
  description = "ID of the Terraform group"
  value       = azuread_group.terraform.object_id
}

output "terraform_client_id" {
  description = "Client ID of the Terraform Service Principal"
  value       = azuread_service_principal.terraform.application_id
}

output "terraform_object_id" {
  description = "Object ID of the Terraform Service Principal"
  value       = azuread_service_principal.terraform.object_id
}

output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "terraform_storage_account_name" {
  description = "Name of the Terraform Storage Account"
  value       = azurerm_storage_account.state.name
}

output "cloudshell_storage_account_name" {
  description = "Name of the Terraform Storage Account"
  value       = azurerm_storage_account.shell.name
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}
