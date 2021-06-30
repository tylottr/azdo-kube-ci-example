# Terraform: azdo-kube-ci-example Terraform Ops

Thie template will create some base resources for enabling Terraform usage

## Prerequisites

Prior to deployment you need the following:

- [terraform](https://www.terraform.io/)
- [azcli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

In Azure, you need:

- An account with Owner privileges to the target subscription

## Variables

|Variable Name|Description|Type|Default Value|
|-|-|-|-|
|tenant_id|The tenant id of this deployment|`null`|
|subscription_id|The subscription id of this deployment|`null`|
|location|The location of this deployment|`"Central US"`|
|resource_prefix|A prefix for the name of the resource, used to generate the resource names||
|tags|Tags given to the resources created by this template|`{}`|
|admin_object_ids|Object IDs for administrative objects with full access to the Key Vault and Storage Account|list(string)|`[]`|

## Outputs

|Output Name|Description|
|-|-|
|terraform_group_id|ID of the Terraform group|
|terraform_client_id|Client ID of the Terraform Service Principal|
|terraform_object_id|Object ID of the Terraform Service Principal|
|resource_group_name|Name of the Resource Group|
|resource_group_location|Location of the resource group|
|terraform_storage_account_name|Name of the Storage Account|
|cloudshell_storage_account_name|Name of the Terraform Storage Account|
|key_vault_name|Name of the Key Vault|

