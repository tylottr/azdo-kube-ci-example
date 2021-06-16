###################
# Global Variables
###################

variable "resource_group_name" {
  description = "The name of an existing resource group"
  type        = string
}

variable "location" {
  description = "The location of this deployment"
  type        = string
}

variable "resource_prefix" {
  description = "A prefix for the name of the resource, used to generate the resource names"
  type        = string
}

variable "tags" {
  description = "Tags given to the resources created by this template"
  type        = map(string)
  default     = {}
}

#############
# Monitoring
#############

variable "enable_monitoring" {
  description = "Flag used to enable Log Analytics for monitoring the deployed resources"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log analytics workspace ID to use - defaults to creating a log analytics workspace"
  type        = string
  default     = null

  validation {
    condition     = var.log_analytics_workspace_id == null || can(regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", var.log_analytics_workspace_id))
    error_message = "The log_analytics_workspace_id must to be a valid UUID."
  }
}

###########
# Security
###########

variable "enable_aks_aad_rbac" {
  description = "Flag used to enable AAD RBAC Integration"
  type        = bool
  default     = false
}

variable "aks_aad_tenant_id" {
  description = "Tenant ID used for AAD RBAC (defaults to current tenant)"
  type        = string
  default     = null

  validation {
    condition     = var.aks_aad_tenant_id == null || can(regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", var.aks_aad_tenant_id))
    error_message = "The aks_aad_tenant_id must to be a valid UUID."
  }
}

variable "aks_aad_admin_group_object_ids" {
  description = "Object IDs of AAD Groups that have Admin role over the cluster"
  type        = list(string)
  default     = null

  validation {
    // If null, pass. If a list, ensure we don't have any entries that aren't UUIDs.
    condition     = var.aks_aad_admin_group_object_ids == null || !can(index([for uuid in var.aks_aad_admin_group_object_ids : can(regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", uuid))], false))
    error_message = "The aks_aad_admin_group_object_ids must be valid UUIDs."
  }
}

##########
# Storage
##########

variable "enable_acr" {
  description = "Flag used to enable ACR"
  type        = bool
  default     = false
}

variable "acr_sku" {
  description = "SKU of the ACR"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "The acr_sku must be 'Basic', 'Standard' or 'Premium'."
  }
}

variable "acr_georeplication_locations" {
  description = "Georeplication locations for ACR (Premium tier required)"
  type        = list(string)
  default     = []
}

variable "enable_acr_admin" {
  description = "Flag used to enable ACR Admin"
  type        = bool
  default     = false
}

##########
# Compute
##########

variable "aks_kubernetes_version" {
  description = "Version of Kubernetes to use in the cluster - leave blank for latest"
  type        = string
  default     = null

  validation {
    condition     = var.aks_kubernetes_version == null || var.aks_kubernetes_version == "latest" || can(regex("\\d+\\.\\d+\\.\\d+", var.aks_kubernetes_version))
    error_message = "The aks_kubernetes_version value must be 'latest' or semantic versioning e.g. '1.18.4'."
  }
}

variable "aks_load_balancer_sku" {
  description = "SKU to use for the AKS Load Balancer"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.aks_load_balancer_sku)
    error_message = "The aks_load_balancer_sku must be 'Basic' or 'Standard'."
  }
}

variable "enable_aks_kube_dashboard" {
  description = "Flag used to enable AKS Kube Dashboard addon"
  type        = bool
  default     = false
}

variable "aks_network_policy" {
  description = "Network policy that should be used ('calico' or 'azure')"
  type        = string
  default     = null

  validation {
    condition     = var.aks_network_policy == null || var.aks_network_policy == "calico" || var.aks_network_policy == "azure"
    error_message = "The aks_network_policy must be 'null', 'calico' or 'azure'."
  }
}

variable "enable_aks_advanced_networking" {
  description = "Flag used to enable Azure CNI"
  type        = bool
  default     = false
}

variable "aks_subnet_name" {
  description = "Name of the subnet for Azure CNI (Ignored if enable_aks_advanced_networking is false)"
  type        = string
  default     = null
}

variable "aks_subnet_vnet_name" {
  description = "Name of the aks_subnet_name's VNet for Azure CNI (Ignored if enable_aks_advanced_networking is false)"
  type        = string
  default     = null
}

variable "aks_subnet_vnet_resource_group_name" {
  description = "Name of the resource group for aks_subnet_vnet_name for Azure CNI (Ignored if enable_aks_advanced_networking is false)"
  type        = string
  default     = null
}

variable "aks_service_cidr" {
  description = "Service CIDR for AKS"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(regex("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/\\d{2}", var.aks_service_cidr))
    error_message = "The aks_service_cidr must be a valid CIDR range."
  }
}

variable "aks_default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "default"
}

variable "aks_node_size" {
  description = "Size of nodes in the AKS cluster"
  type        = string
  default     = "Standard_B2ms"
}

variable "aks_node_min_count" {
  description = "Minimum number of nodes in the AKS cluster"
  type        = number
  default     = 1

  validation {
    condition     = var.aks_node_min_count > 0
    error_message = "The aks_node_min_count is less than 1."
  }
}

variable "aks_node_max_count" {
  description = "Maximum number of nodes in the AKS cluster"
  type        = number
  default     = 1

  validation {
    condition     = var.aks_node_max_count > 0
    error_message = "The aks_node_max_count is less than 1."
  }
}

variable "aks_default_node_pool_availability_zones" {
  description = "Availability zones to use with the default node pool"
  type        = list(number)
  default     = null
}

variable "aks_default_node_pool_labels" {
  description = "Node labels to apply to the default node pool"
  type        = map(string)
  default     = null
}

#########
# Locals
#########

locals {
  resource_prefix = "${var.resource_prefix}-aks"

  kubeconfig = {
    kubeconfig_raw         = coalesce(azurerm_kubernetes_cluster.main.kube_admin_config_raw, azurerm_kubernetes_cluster.main.kube_config_raw)
    host                   = coalescelist(azurerm_kubernetes_cluster.main.kube_admin_config, azurerm_kubernetes_cluster.main.kube_config)[0].host
    cluster_ca_certificate = base64decode(coalescelist(azurerm_kubernetes_cluster.main.kube_admin_config, azurerm_kubernetes_cluster.main.kube_config)[0].cluster_ca_certificate)
    client_certificate     = base64decode(coalescelist(azurerm_kubernetes_cluster.main.kube_admin_config, azurerm_kubernetes_cluster.main.kube_config)[0].client_certificate)
    client_key             = base64decode(coalescelist(azurerm_kubernetes_cluster.main.kube_admin_config, azurerm_kubernetes_cluster.main.kube_config)[0].client_key)
  }
}
