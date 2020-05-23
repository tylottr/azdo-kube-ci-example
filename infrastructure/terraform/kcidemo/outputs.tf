output "aks_name" {
  value = module.aks.aks_name
}

output "resource_group_name" {
  value = data.azurerm_resource_group.main.name
}
