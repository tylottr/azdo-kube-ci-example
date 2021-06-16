output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_name" {
  description = "Name of the AKS Cluster"
  value       = module.aks.aks_name
}

output "aks_config" {
  description = "Kubeconfig for the AKS Cluster"
  value       = module.aks.aks_kubeconfig
  sensitive   = true
}

output "aks_host" {
  description = "AKS Cluster Host"
  value       = module.aks.aks_kubeconfig_host
}

output "acr_name" {
  description = "Name of the container registry"
  value       = module.aks.acr_name
}

output "acr_login_server" {
  description = "Login server of the container registry"
  value       = module.aks.acr_login_server
}

output "acr_admin_user" {
  description = "Admin user for the container registry"
  value       = module.aks.acr_admin_user
}

output "acr_admin_password" {
  description = "Admin password for the container registry"
  value       = module.aks.acr_admin_password
  sensitive   = true
}
