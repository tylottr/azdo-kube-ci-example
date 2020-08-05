output "aks_resource_group_name" {
  value = module.aks.aks_resource_group_name
}

output "aks_name" {
  value = module.aks.aks_name
}

output "aks_config" {
  value     = module.aks.aks_kubeconfig
  sensitive = true
}

output "aks_host" {
  value = module.aks.aks_kubeconfig_host
}

output "acr_name" {
  value = module.aks.acr_name
}

output "acr_login_server" {
  value = module.aks.acr_login_server
}

output "acr_admin_user" {
  value = module.aks.acr_admin_user
}

output "acr_admin_password" {
  value     = module.aks.acr_admin_password
  sensitive = true
}
