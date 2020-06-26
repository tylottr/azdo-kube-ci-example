# Azure Devops Pipelines - Kube CI Example

This repository contains a demonstration setup for creating an AKS Kubernetes environment with multiple Docker-based applications set up. Azure DevOps is used to delivery these applications through pipelines utilising self-hosted VSTS Agents.

Through it we deploy three applications:

* An Nginx container with a static website built into a Docker image
* An ExpressJS container
* A Python Flask container

> These are all stored under the [application](application) directory, if you want to look at the Dockerfiles and code.

This document consists of the following sections:

1. [Prerequisites](##1.-Prerequisites)
2. [Infrastructure Configuration](##2.-Infrastructure-Configuration)
3. [Azure DevOps Configuration](##3.-Azure-Devops-Configuration)
4. [Cleanup](##4.-Cleanup)

> **NOTE:** This demonstration has snippets written with bash in mind, so keep that in mind if not using bash.

## 1. Prerequisites

- An Azure Devops Organization is required in order to follow this example. 
    - If you don't already have one you can create one [here](https://azure.microsoft.com/en-us/services/devops/?nav=min).
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
    - The [Azure DevOps extension](https://github.com/Azure/azure-devops-cli-extension) should also be enabled.
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
    - This can be installed using `az aks install-cli`.
- [packer](https://www.packer.io/)
- [terraform](https://www.terraform.io/)

Prior to these tasks ensure that you have ran `az login` and selected the correct target subscription with `az account set --subscription <REPLACE_WITH_SUBSCRIPTION_ID_OR_NAME>`.

## 2. Infrastructure Configuration

> **NOTE:** While this guide is aimed at using Azure with Azure Kubernetes Service, Azure Container Registry and additional virtual machines, you can bring your own cluster/container registry instead.

This section covers creating the necessary resources in Azure for this demonstration.

### 1. Create base Azure Resources

We will use a single resource group for the demonstration, housing a storage account for our state, our DevOps Agents and our container resources.

> **NOTE:** Storage accounts are globally unique, so you will need to change the torage account name.

```bash
resourceGroup="kcidemo-rg"
location="centralus"
storageAccount="REPLACE_WITH_STORAGE_ACCOUNT_NAME"

az group create --location $location --name $resourceGroup
az storage account create --resource-group $resourceGroup --name $storageAccount
az storage container create --account-name $storageAccount --name tfstate
```

### 2. (OPTIONAL) Run Packer to build the DevOps Agent base image

Packer configuration can be found under [infrastructure/packer/azdo-agent](infrastructure/packer/azdo-agent) for the agent.

```bash
subscriptionId=$(az account show --output tsv --query id)
devopsImageName="linux-agent-image"
cd infrastructure/packer/azdo-agent
packer build -var resource_group=$resourceGroup -var image_name=$devopsImageName -var location=$location -var subscription_id=$subscriptionId agent.json

devopsImageId="/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/images/$devopsImageName"
echo "Image ID: $devopsImageId"
cd ../../..
```

### 3. Deploy the Azure Infrastructure

Under [infrastructure/terraform/kcidemo](infrastructure/terraform/kcidemo), there is a Terraform configuration that will use modules for configuration.

First we will create a file to store our generated source image from the last step.

```bash
cd infrastructure/terraform/kcidemo
echo -e "resource_prefix = \"REPLACE_WITH_SOMETHING_UNIQUE\"" > global.auto.tfvars
```

Next we update the _backend.tf file under this folder.

> **NOTE:** `storage_account_name` should match the value in step 1. The file should look something like below.

> **NOTE:** If using pipelines it may be best to leave `storage_account_name` unset as the pipeline templates set this value.

```hcl
terraform {
  backend "azurerm" {
    storage_account_name = "REPLACE_WITH_STORAGE_ACCOUNT_NAME"
    container_name       = "tfstate"
    key                  = "kcidemo/tfstate"
  }
}
```

Finally we will run through the Terraform workflow to create our environment.

```bash
terraform init -backend-config="resource_group_name=$resourceGroup"
terraform validate
terraform plan -out tf.plan -var resource_group_name="$resourceGroup"
terraform apply tf.plan
cd ../../..
```

Once the apply step finishes you should have an AKS cluster and ACR under your new resource group.

> **NOTE:** This does not include VMSS agents. For this you can use [this](infrastructure/terraform/vmss/README.md) template. You will also have to configure the pipelines to use this agent pool.

### 4. Deploy the Kubernetes Manifests

The below script will collect our AKS credentials and then apply the configuration used to give Azure DevOps a namespace to access and deploy to.

```bash
aks=$(az aks list --resource-group $resourceGroup --output tsv --query [0].name)
az aks get-credentials --resource-group $resourceGroup --name $aks
kubectl apply -f infrastructure/kubernetes/kcidemo
```

## 3. Azure DevOps Configuration

> You must be using the preview feature [Multi-Stage Pipelines](https://docs.microsoft.com/en-us/azure/devops/project/navigation/preview-features?view=azure-devops) for this section.

The Azure DevOps Configuration uses a mixture of components, including its Repos, Pipelines and Tests for demonstration purposes.

We can create our project and set it as the default using the below commands

```bash
az devops project create --name=kcidemo
```

On Project creation, it will give us a new repository with the same name as the project.

### Repository Setup

This demonstration assumes you will be using Azure DevOps to store your repository. If you prefer GitHub, there are annotations detailing what needs to be done to point to your own Github repository.

To change this repository to use Azure Repos, follow the below steps to get the Git URL, update your remote and push:

```bash
gitUrl=$(az repos list --project=kcidemo --output tsv --query "[?name=='kcidemo'].remoteUrl")
git remote set-url origin $gitUrl
git push --set-upstream origin master
```

### Service Connections

A Service Connection is used to allow Azure DevOps pipelines to interact with external resources and can be accessed through the Project Settings in the portal. They can also be managed with the `az devops service-endpoint` commands.

> The `az devops service-endpoint create` does require a configuration file. See [here](https://docs.microsoft.com/en-us/azure/devops/cli/service_endpoint?view=azure-devops#create-service-endpoint-using-configuration-file) for more information.

#### Docker Registry

The Docker Registry service connection is used to allow us to be more flexible in where we store our container images and supports Docker Hub, Azure Container Registry and a generic Other option.

> This resource can be easily created in the portal under the Project configuration Service Connections page. Use the "Other" type and fill in the values of your container registry there and name the service connection as the FQDN.
> * If using Azure Container Registry, you can get the login information from the Overview and Access Keys pages on the resource.

To retrieve ACR credentials through commandline follow the below commands:

```bash
registryName=$(az acr list --resource-group $resourceGroup --output tsv --query [0].name)
registryPassword=$(az acr credential show --name $registryName --output tsv --query passwords[0].value)

cat <<EOF
Service Connection Name : $registryName.azurecr.io
Docker Registry         : https://$registryName.azurecr.io/v1/
Docker ID               : $registryName
Docker Password         : $registryPassword
EOF
```

#### AzureRM

AzureRM as a connection type is supported in the command line as-is.

We can create this with `az devops service-endpoint azurerm create`, allowing us to give it Service Principal credentials.

An example of doing this is below:

> **NOTE:** Propagation can cause this to fail if you create the role assignment quickly after the Service Principal creation.

```bash
tenantId=$(az account show --output tsv --query tenantId)
subscriptionId=$(az account show --output tsv --query id)
subscriptionName=$(az account show --output tsv --query name)

servicePrincipalAppId=$(az ad app create --display-name "Azure DevOps CI (kcidemo) - $subscriptionName" --identifier-uris "https://azuredevopsci" --output tsv --query appId)
servicePrincipalObjectId=$(az ad sp create --id $servicePrincipalAppId --output tsv --query objectId)
az role assignment create --role "Contributor" --assignee $servicePrincipalObjectId --scope "/subscriptions/$subscriptionId"
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$(az ad sp credential reset --name $servicePrincipalAppId --credential-description "Azure DevOps" --output tsv --query password)

az devops service-endpoint azurerm create --project=kcidemo --name="Azure DevOps CI (kcidemo) - $subscriptionName" --azure-rm-tenant-id=$tenantId --azure-rm-subscription-id=$subscriptionId --azure-rm-subscription-name=$subscriptionName --azure-rm-service-principal-id=$servicePrincipalAppId
```

#### Kubernetes

The Kubernetes service connection is used to allow access into a Kubernetes cluster.

> This is automatically created as part of creating the Azure DevOps environment under [Environments](###Environments)

### DevOps Agents

> **NOTE:** As pipeline runs are done using the hosted agents, this section is optional. If using VMSS-backed agents, you can use [this](infrastructure/terraform/vmss/README.md) template.

DevOps Agents are supported through VMSS Orchestration which require dedicated node pools.

To create a VMSS Agent Pool, we follow the below steps:

1. Under our Azure DevOps Organization, go to Settings then Agent Pools
2. Select Add Agent Pool and ensure the Pool Type is set to Virtual Machine Scale Set
3. Choose the Project, Azure Subscription and Scale Set and give the pool a name
    - You may need to create a Service Connection to your Azure.

### Environments

An Environment is used to provide deployment and monitoring capabilities to Azure DevOps for particular resources and can be accessed under Pipelines in the portal. They are divided into the Environment itself, and then underlying resources.

To create an Environment Resource you need to collect information based on the resource type, in our case we are using Kubernetes.

|Field|Description|
|-|-|
|Cluster Name|The name of the cluster|
|Namespace|The namespace inside of the cluster|
|Server URL|FQDN of the Kubernetes API server retrieved with `kubectl config view --minify --output=jsonpath="{.clusters[0].cluster.server}"`|
|Secret|JSON secret from a service account with permissions|

> You may need to tick the `Accept untrusted certificates` tickbox to get this created.

> To retrieve the Secret: 
> 1. Run `kubectl get --namespace=kcidemo serviceaccounts azure-devops --output=jsonpath="{.secrets[*].name}"` to get the token name
> 2. Run `kubectl get --namespace=kcidemo secret <replace with value from step 1> --output=json` to get the required value

### Library

The Library in Azure DevOps can be accessed through the Pipelines section and allows us to store variable groups (with protected and nonprotected variables) and secure files. They can also be managed with the `az pipelines variables-group` commands.

This example uses two variable groups in its configuration, which in the case of the example, are configured like below:

> **NOTE:** These values will need updating to reflect your actual environment.

**Application**

|Variable|Description|Variable Group|Value|
|-|-|-|-|
|appBasePath|Base path of the applications being built in this repository starting from the repository root|shared-app|`"application"`|
|appDomain|The domain of the application to be inserted into Ingress rules, prefixed with `appName.`|shared-app|`"www.example.com"`|
|appKustomizePath|Path to the Kustomize folder used for the application starting from the repository root|shared-app|`".devops/kubernetes/kustomize/app"`|
|containerRegistry|The FQDN of the Container Registry|shared-app|`"kcidemoaksacr.azurecr.io"`|
|kubernetesEnvironment|The name of the environment being deployed to|shared-app|`"kcidemo`"|
|kubernetesResource|The name of the resource being deployed to|shared-app|`"kcidemo"`|

We can create and configure the variable group running the below commands

```bash
# create "shared" variable group
az pipelines variable-group create --project=kcidemo --name=shared-app \
  --variables \
    appBasePath=application \
    appDomain=www.example.com \
    appKustomizePath=.devops/kubernetes/kustomize/app \
    containerRegistry=kcidemoaksacr.azurecr.io \
    kubernetesEnvironment=kcidemo \
    kubernetesResource=kcidemo
```

**Infrastructure - Terraform**

|Variable|Description|Variable Group|Value|
|-|-|-|-|
|terraformAzureSubscription|The service connection subscription to use for Terraform|shared-terraform|`"kcidemo"`|
|terraformStorageAccount|The storage account used for Terraform state|shared-terraform|`"kcidemotfsa"`|
|terraformWorkingDirectoryBase|The working directory base for Terraform|shared-terraform|`"infrastructure/terraform"`|

We can create and configure the variable group running the below commands

```bash
# create "shared" variable group
az pipelines variable-group create --project=kcidemo --name=shared-terraform \
  --variables \
    terraformAzureSubscription=kcidemo \
    terraformStorageAccount=kcidemotfsa \
    terraformWorkingDirectoryBase=infrastructure/terraform
```

**Infrastructure - Packer**

|Variable|Description|Variable Group|Value|
|-|-|-|-|
|packerAzureSubscription|The service connection subscription to use for Packer|shared-packer|`"kcidemo"`|
|packerWorkingDirectoryBase|The working directory base for Packer|shared-packer|`"infrastructure/packer"`|

We can create and configure the variable group running the below commands

```bash
# create "shared" variable group
az pipelines variable-group create --project=kube-ci-example --name=shared-packer \
  --variables \
    packerAzureSubscription=kcidemo \
    packerWorkingDirectoryBase=infrastructure/packer
```

### Pipelines

A pipeline is a set of stages, jobs and steps that run as part of CI and can be accessed under Pipelines in the portal. They can also be managed with the `az pipelines` commands.

**Applications**

This demonstration uses three applications:

* www, a static page in an Nginx container
* express, an ExpressJS application
* flask, a Python Flask application

We can create and configure the pipelines running the below commands

> If using GitHub, make the following changes to the commands below:
>
> 1. Change `--repository` to be your Github `username/repository`
> 2. Change `--repository-type` to `github`

1. Create the www pipeline

```bash
az pipelines create --project=kcidemo --name=www \
  --repository=kcidemo --branch=master --repository-type=tfsgit \
  --yml-path=application/www/azure-pipelines.yml --skip-run
```

2. Create the express pipeline

```bash
az pipelines create --project=kcidemo --name=express \
  --repository=kcidemo --branch=master --repository-type=tfsgit \
  --yml-path=application/express/azure-pipelines.yml --skip-run
```

3. Create the flask pipeline

```bash
az pipelines create --project=kcidemo --name=flask \
  --repository=kcidemo --branch=master --repository-type=tfsgit \
  --yml-path=application/flask/azure-pipelines.yml --skip-run
```

To then run a build you can use the `az pipelines run --name=www` command.

**Infrastructure as Code**

Infrastructure as Code also supports the usage of pipelines for managing lifecycles.

Here we will create and configure our Terraform pipeline.

```bash
az pipelines create --project=kcidemo --name=terraformaksci \
  --repository=kcidemo --branch=master --repository-type=tfsgit \
  --yml-path=infrastructure/terraform/kcidemo/azure-pipelines.yml --skip-run

az pipelines variable create --project=kcidemo --pipeline-name=terraformaksci \
  --name=terraformApply --value=false --allow-override

az pipelines variable create --project=kcidemo --pipeline-name=terraformaksci \
  --name=terraformDestroy --value=false --allow-override

az pipelines variable create --project=kcidemo --pipeline-name=terraformaksci \
  --name=resourcePrefix --value=kcidemo --allow-override
```

And here we will create our Packer configuration.

```bash
az pipelines create --project=kcidemo --name=packerci \
  --repository=kcidemo --branch=master --repository-type=tfsgit \
  --yml-path=infrastructure/packer/azdo-agent/azure-pipelines.yml --skip-run

az pipelines variable create --project=kcidemo --pipeline-name=packerci \
  --name=packerAzureLocation --value=$location --allow-override

az pipelines variable create --project=kcidemo --pipeline-name=packerci \
  --name=packerAzureResourceGroup --value=$resourceGroup --allow-override
```

## 4. Cleanup

To clean everything up from this demonstration you can follow the below steps:

1. Delete the project from Azure DevOps in the portal or with the below commands
    1. Run `az devops project show --project=kcidemo --query=id --output=tsv` to get the project ID
    2. Run `az devops project delete --id=<replace with value from step 1>` to delete the project
2. Delete the demonstration resources with `kubectl delete -f infrastructure/kubernetes/kcidemo`
3. **(Optional)** Tear down Terraform-managed resources with `terraform destroy`
4. **(Optional)** Tear down created resource group with `az group delete --name $resourceGroup`
