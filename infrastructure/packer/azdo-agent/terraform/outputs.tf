output "resource_group_name" {
  description = "Name of the resource group used for the VMSS agents"
  value       = azurerm_resource_group.main.name
}

output "vmss_id" {
  description = "ID of the VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.main.id
}

output "vmss_name" {
  description = "Name of the VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.main.name
}
