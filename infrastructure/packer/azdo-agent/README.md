# Packer - Azure DevOps Linux Agent

This Packer build will create an Azure DevOps Linux agent provisioned using Ansible.

## Pre-requisites

* [Packer](https://packer.io/)
* [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

Alternatively, you can look at [this repository](https://github.com/actions/virtual-environments/tree/master/images) for a much better version.

## Variables

**Packer Variables**

|Variable|Description|Default Value|Required|
|-|-|-|-|
|subscription_id|The subscription to make the image in|Uses AZURE_SUBSCRIPTION_ID environment variable|No|
|client_id|The client id used to access the subscription|Uses AZURE_CLIENT_ID environment variable|No|
|client_secret|The client secret used to access the subscription|Uses AZURE_CLIENT_SECREt environment variable|No|
|location|The location to make the image in|`"centralus"`|No|
|resource_group|The resource group to make the image in||Yes|
|image_name|The name of the image|`"vsts-agent-{{ isotime \"2006-01-02\" }}"`|No|

**Ansible Variables**

> NOTE: If installing the agent, ensure you also set the `azdo_agent_organization` and `azdo_agent_token` variables.

|Variable|Description|Default Value|
|-|-|-|
|azdo_agent_install|Whether to install and register the VSTS agent|`false`|
|azdo_agent_user|The user to run Azure DevOps under|`"azdo"`|
|azdo_agent_agent_version|The version of the Azure DevOps agent to install|`"2.164.6"`|
|azdo_agent_agent_pool|The agent pool to install the Azure DevOps agent to|`"Default"`|
|azdo_agent_organization|The organization to install the Azure DevOps agent to||
|azdo_agent_token|The PAT token used to install the Azure DevOps agent||
|azdo_agent_organization_url|The URL of the Azure DevOps organization|`"https://dev.azure.com/{{ azdo_agent_organization }}"`|

## Image Creation

The below steps will let you create a Managed Disk Image of the VSTS Agent in an interactive workflow. An example of an automated workflow can be found in the azure-pipelines.yml file.

1. `az login` to log into Azure
2. `az account set -s <REPLACE_WITH_SUBSCRIPTION_ID_OR_NAME>` to select the correct subscription
3. `packer build -var resource_group=<REPLACE_WITH_RESOURCE_GROUP_NAME> agent.json`

## As a Playbook

If you want to run this against existing infrastructure, you can do so with `ansible-playbook default.yml`. It would be recommended to use Dynamic Inventory, like with the configuration below.

> **NOTE:** Ensure the file name ends in "azure_rm.yml" for this to work.

```yaml
plugin: azure_rm
auth_source: cli

include_vm_resource_groups:
- REPLACE_WITH_RESOURCE_GROUP_NAME

exclude_host_filters:
- powerstate != 'running'
```
