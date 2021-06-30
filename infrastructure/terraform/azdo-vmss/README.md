# Terraform: azdo-kube-ci-example VMSS Agents

This template is used to create a VMSS-based Azure DevOps Agent pool.

## Prerequisites

Prior to deployment you need the following:

- [terraform](https://www.terraform.io/)
- [azcli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

In Azure, you need:

- An account with Owner privileges to the target subscription

## Variables

|Variable Name|Description|Type|Default Value|
|-|-|-|-|
|tenant_id|The tenant id of this deployment|string|`null`|
|subscription_id|The subscription id of this deployment|string|`null`|
|client_id|The client id of this deployment|string|`null`|
|client_secret|The client secret of this deployment|string|`null`|
|location|The location of this deployment|string|`"Central US"`|
|resource_prefix|A prefix for the name of the resource, used to generate the resource names|string||
|tags|Tags given to the resources created by this template|map(string)|`{}`|
|vm_azdo_source_image_id|ID of a source image for the Linux Azure DevOps VMs|string||

## Outputs

|Output Name|Description|
|-|-|
|resource_group_name|Name of the resource group used for the VMSS agents|
|vmss_id|ID of the VM Scale Set|
|vmss_name|Name of the VM Scale Set|

