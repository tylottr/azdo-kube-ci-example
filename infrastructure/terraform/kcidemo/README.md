# Terraform: azdo-kube-ci-example

This configuration is used to create an AKS Cluster and ACR. 

## Prerequisites

Prior to deployment you need the following:

- [terraform](https://www.terraform.io/)
- [azcli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

In Azure, you need:

- An account with Owner privileges to the target subscription

## Variables

|Variable Name|Description|Type|Default|
|-|-|-|-|
|tenant_id|The tenant id of this deployment|string|`null`|
|subscription_id|The subscription id of this deployment|string|`null`|
|client_id|The client id of this deployment|string|`null`|
|client_secret|The client secret of this deployment|string|`null`|
|location|The location of this deployment|string|`"Central US"`|
|resource_prefix|A prefix for the name of the resource, used to generate the resource names|string||
|tags|Tags given to the resources created by this template|map(string)|`{}`|

## Outputs

|Output Name|Description|
|-|-|
|resource_group_name|Name of the resource group|
|aks_name|Name of the AKS Cluster|
|aks_config|Kubeconfig for the AKS Cluster|
|aks_host|AKS Cluster Host|
|acr_name|Name of the container registry|
|acr_login_server|Login server of the container registry|
|acr_admin_user|Admin user for the container registry|
|acr_admin_password|Admin password for the container registry|

## Post-Deployment

### Connecting to the Cluster

You can connect to your new cluster using the following command: `az aks get-credentials --name $(terraform output aks_name) --resource-group $(terraform output resource_group_name)`

- If using AAD RBAC integration you must be in one of the created AD groups to properly authenticate.

### Kubernetes Manifests

Additional manifests can be deployed - there are numerous manifests and helm configurations under [kubernetes](../../kubernetes) that can get you started. There is a section in [the base README](../../../README.md) covering usage under Infrastructure Configuration.
