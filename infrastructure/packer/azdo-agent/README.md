# Azure DevOps Ubuntu Agent

Thie repository contains resources to help create an Azure DevOps agent.

This includes:

- `agent.json`, a Packer definition file to create an Azure VM image
    - Alternatively, you can look at [this repository](https://github.com/actions/virtual-environments/tree/master/images) for a much better version.
- `agent.yml`, an Ansible playbook that utilises the `azdo-ubuntu-agent` role stored under the roles directory.
- A Terraform configuration to deploy the new image to a VMSS resource, enabling the use of VMSS-backed agent pools.

## Pre-requisites

- [Packer](https://packer.io/)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [terraform](https://www.terraform.io/) - 0.12

## Variables

### Packer

The packer build is aimed at Azure only, however you can include your own Builders block to create images for other platforms e.g. AWS.

Variables can be set either with `-var` or with `-var-file` keywords.

|Variable|Description|Default Value|Required|
|-|-|-|-|
|subscription_id|The subscription to make the image in|Uses AZURE_SUBSCRIPTION_ID environment variable|No|
|client_id|The client id used to access the subscription|Uses AZURE_CLIENT_ID environment variable|No|
|client_secret|The client secret used to access the subscription|Uses AZURE_CLIENT_SECREt environment variable|No|
|location|The location to make the image in|`"centralus"`|No|
|resource_group|The resource group to make the image in||Yes|
|image_name|The name of the image|`"vsts-agent-{{ isotime \"2006-01-02\" }}"`|No|

### Ansible

The Ansible Playbook used contains tasks to help keep the disk space low over time and reduce manual management of created VMs.

**Docker Variables**

|Variable|Description|Default Value|
|-|-|-|
|docker_maintenance_tasks|Whether to run `docker system prune` as a cronjob for disk space management|`true`|
|docker_prune_crontime|The cron time for running a full docker prune|`"30 8 * * 1,6"`|

**Azure DevOps Agent Variables**

> NOTE: If installing the agent, ensure you also set the `azdo_agent_organization` and `azdo_agent_token` variables.

|Variable|Description|Default Value|
|-|-|-|
|azdo_agent_install|Whether to install and register the VSTS agent|`false`|
|azdo_agent_version|The version of the Azure DevOps agent to install|`"2.171.1"`|
|azdo_agent_pool|The agent pool to install the Azure DevOps agent to|`"Default"`|
|azdo_agent_organization|The organization to install the Azure DevOps agent to||
|azdo_agent_token|The PAT token used to install the Azure DevOps agent||
|azdo_agent_organization_url|The URL of the Azure DevOps organization|`"https://dev.azure.com/{{ azdo_agent_organization }}"`|

### Terraform

All configuration for Terraform is stored in a single `main.tf` for simplicity but will build a dedicated VNet and set of VMSS instances using the provided source image.

|Variable|Description|Default Value|
|-|-|-|
|tenant_id|The tenant id of this deployment|`null`|
|subscription_id|The subscription id of this deployment|`null`|
|client_id|The client id of this deployment|`null`|
|client_secret|The client secret of this deployment|`null`|
|location|The location of this deployment|`"Central US"`|
|resource_prefix|A prefix for the name of the resource, used to generate the resource names||
|tags|Tags given to the resources created by this template|`{}`|
|vm_source_image_id|ID of a source image for the Linux Azure DevOps VMs||
|vm_size|Size of instances to deploy|`"Standard_B2s"`|
|vm_disk_type|Type of disk to use on instances|`"StandardSSD_LRS"`|
|vm_disk_size_gb|Size of disk to use on instances|`127`|
|vm_disk_caching|Caching option to use on instances|`"None"`|

## Instructions

### Packer - Image Creation

The below steps will let you create a Managed Disk Image of the VSTS Agent in an interactive workflow.

1. `az login` to log into Azure
2. `packer build -var resource_group=<REPLACE_WITH_RESOURCE_GROUP_NAME> agent.json`

### Terraform - Create VMSS Infrastructure

The `main.tf` file is an example configuration to use but this can be deployed with the following process:

1. `az login` to log into Azure
2. `terraform init`
3. `terraform apply -var resource_prefix="azdo" -var vm_source_image_id="REPLACE_WITH_PACKER_IMAGE_ID"`
    - The `vm_source_image_id` can be pulled with `cat manifest.json | jq -r '.builds[0].artifact_id'`, as an example using `bash` and `jq`

### Ansible - Bootstrap existing VMs

If you want to run this against existing infrastructure, you can do so with `ansible-playbook agent.yml`. It may be worth using Dynamic Inventory for this, for example with the below azure_rm dynamic inventory configuration.

> **NOTE:** Ensure the file name ends in "azure_rm.yml" for this to work.

```yaml
plugin: azure_rm
auth_source: cli

include_vm_resource_groups:
- REPLACE_WITH_RESOURCE_GROUP_NAME

exclude_host_filters:
- powerstate != 'running'
```
