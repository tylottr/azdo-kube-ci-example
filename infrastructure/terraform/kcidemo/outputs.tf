output "resource_group_name" {
  value = data.azurerm_resource_group.main.name
}

output "aks_name" {
  value = module.aks.aks_name
}

output "aks_config" {
  value     = module.aks.aks_kubeconfig
  sensitive = true
}
