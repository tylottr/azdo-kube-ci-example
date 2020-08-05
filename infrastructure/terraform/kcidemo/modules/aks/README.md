# Terraform: Azure Kubernetes Service

This module is used to create an Azure Kubernetes cluster with some options to provide customizability for clusters requiring features such as RBAC integration and advanced networking.

## Features

This module is aimed at providing a set of related resources to enable AKS to integrate with AAD, utilise existing network infrastructure while providing monitoring options and a container registry if needed.

It provides the following:

- An Azure Kubernetes Service cluster with a default node pool supporting autoscaling
- Optional AAD RBAC integration
- Options for advanced networking
- Options for network policies
- Optional Log Analytics Workspace creation (Or provide your own workspace ID)

## Usage

### Basic

At its most simple we can utilise this module like this:

```hcl
resource "azurerm_resource_group" "main" {
  name     = "my-little-kube"
  location = "Central US"
}

module "aks" {
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  resource_prefix     = "my-little-kube"
}
```

## Variables

|Variable Name|Description|Type|Default|
|-|-|-|-|
|resource_group_name|The name of an existing resource group|string||
|location|The location of this deployment|string||
|resource_prefix|A prefix for the name of the resource, used to generate the resource names|string||
|tags|Tags given to the resources created by this template|map(string)|`{}`|
|enable_monitoring|Flag used to enable Log Analytics for monitoring the deployed resources|string|`false`|
|log_analytics_workspace_id|Log analytics workspace ID to use - defaults to creating a log analytics workspace|string|`null`|
|enable_aks_aad_rbac|Flag used to enable AAD RBAC Integration|bool|`false`|
|aks_aad_tenant_id|Tenant ID used for AAD RBAC (defaults to current tenant)|string|`null`|
|aks_aad_client_app_id|App ID of the client application used for AAD RBAC|string|`null`|
|aks_aad_server_app_id|App ID of the server application used for AAD RBAC|string|`null`|
|aks_aad_server_app_secret|App Secret of the server application used for AAD RBAC|string|`null`|
|enable_acr|Flag used to enable ACR|bool|`false`|
|acr_sku|SKU of the ACR|string|`"Basic"`|
|acr_georeplication_locations|Georeplication locations for ACR (Premium tier required)|list(string)|`[]`|
|enable_acr_admin|Flag used to enable ACR Admin|bool|`false`|
|aks_network_policy|Network policy that should be used ('calico' or 'azure')|bool|`null`|
|enable_aks_calico|Flag used to enable Calico CNI (Ignored if enable_aks_advanced_networking is true)|bool|`false`|
|enable_aks_advanced_networking|Flag used to enable Azure CNI|bool|`false`|
|aks_subnet_name|Name of the subnet for Azure CNI (Ignored if enable_aks_advanced_networking is false)|string|`null`|
|aks_subnet_vnet_name|Name of the aks_subnet_name's VNet for Azure CNI (Ignored if enable_aks_advanced_networking is false)|string|`null`|
|aks_subnet_vnet_resource_group_name|Name of the resource group for aks_subnet_vnet_name for Azure CNI (Ignored if enable_aks_advanced_networking is false)|string|`null`|
|aks_service_cidr|Service CIDR for AKS|string|`"10.0.0.0/16"`|
|aks_node_size|Size of nodes in the AKS cluster|string|`"Standard_B2ms"`|
|aks_node_min_count|Minimum number of nodes in the AKS cluster|number|`1`|
|aks_node_max_count|Maximum number of nodes in the AKS cluster|number|`1`|

## Outputs

|Output Name|Description|
|-|-|
|aks_id|Resource ID of the AKS Cluster|
|aks_name|Name of the AKS Cluster|
|aks_resource_group_name|Name of the AKS Cluster Resource Group|
|aks_node_resource_group_name|Name of the AKS Cluster Resource Group|
|aks_principal_id|Principal ID of the AKS Cluster identity|
|aks_kubeconfig|Kubeconfig for the AKS Cluster|
|aks_kubeconfig_host|AKS Cluster Host|
|aks_kubeconfig_cluster_ca_certificate|AKS Cluster CA Certificate|
|aks_kubeconfig_client_certificate|AKS Cluster Client Certificate|
|aks_kubeconfig_client_key|AKS Cluster Client Key|
|acr_id|Resource ID of the container registry|
|acr_name|Name of the container registry|
|acr_login_server|Login server of the container registry|
|acr_admin_user|Admin user for the container registry|
|acr_admin_password|Admin password for the container registry|

# Known Issues

> Remove or fill this section in.
