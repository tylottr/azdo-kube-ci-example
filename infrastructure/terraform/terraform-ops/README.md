# Terraform: azdo-kube-ci-example Terraform Ops

Thie template will create some base resources for enabling Terraform usage

## Prerequisites

Prior to deployment you need the following:
* [terraform](https://www.terraform.io/) - 0.12
* [azcli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

In Azure, you need:
* An account with Owner privileges to the target subscription

## Variables

These are the variables used along with their defaults. For any without a value in default, the value must be filled in unless otherwise sateted otherwise the deployment will encounter failures.

**Global Variables**

|Variable Name|Description|Type|Default Value|
|-|-|-|-|
|tenant_id|The tenant id of this deployment|`null`|
|subscription_id|The subscription id of this deployment|`null`|
|location|The location of this deployment|`"Central US"`|
|resource_prefix|A prefix for the name of the resource, used to generate the resource names||
|tags|Tags given to the resources created by this template|`{}`|

**Resource-Specific Variables**

|Variable Name|Description|Type|Default Value|
|-|-|-|-|
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

## Deployment

Below describes the steps to deploy this template.

1. Set variables for the deployment
    * Terraform has a number of ways to set variables. See [here](https://www.terraform.io/docs/configuration/variables.html#assigning-values-to-root-module-variables) for more information.
2. Log into Azure with `az login` and set your subscription with `az account set --subscription='<replace with subscription id or name>'`
    * Terraform has a number of ways to authenticate. See [here](https://www.terraform.io/docs/providers/azurerm/guides/azure_cli.html) for more information.
3. Initialise Terraform with `terraform init`
    * By default, state is stored locally. State can be stored in different backends. See [here](https://www.terraform.io/docs/backends/types/index.html) for more information.
4. Set the workspace with `terraform workspace select <replace with environment>`
    * If the workspace does not exist, use `terraform workspace new <replace with environment>`
5. Generate a plan with `terraform plan -out tf.plan`
6. If the plan passes, apply it with `terraform apply tf.plan`

In the event the deployment needs to be destroyed, you can run `terraform destroy` in place of steps 5 and 6.
