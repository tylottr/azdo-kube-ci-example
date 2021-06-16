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

Prior to these tasks ensure that you have ran `az login` and selected the correct target subscription with `az account set --subscription changeme`.

## 2. Infrastructure Configuration

> **NOTE:** While this guide is aimed at using Azure with Azure Kubernetes Service, Azure Container Registry and additional virtual machines, you can bring your own cluster/container registry instead.

This section covers creating the necessary resources in Azure for this demonstration.

### 1. Create base Azure Resources

To create our base Azure resources, we will use a Terraform configuration stored under [infrastructure/terraform/terraform-ops](infrastructure/terraform/terraform-ops) which will create an AD Group, Terraform service principal, resource group, two storage accounts (state and cloud shell) and a key vault.

This resource group will be used for our shared resources.

The below script will create the resources for us, initialise some variables we will later be using, and create a credential for the new Terraform service principal with a password. It will also retrieve the details for us to use later.

```bash
# Initialize our directory
cd infrastructure/terraform/terraform-ops
echo -e "resource_prefix = \"changeme\"" > terraform.tfvars

# Run Terraform
terraform init
terraform validate
terraform apply

# Collect information
resourceGroup=$(terraform output -raw resource_group_name)
location=$(terraform output -raw resource_group_location)
storageAccount=$(terraform output -raw terraform_storage_account_name)
keyVault=$(terraform output -raw key_vault_name)
terraformSpClientId=$(terraform output -raw terraform_client_id)
certName="TerraformSP-$(terraform output -raw terraform_object_id)"

# Generate credentials
terraformSpPassword=$(
  az ad sp credential reset \
    --name $terraformSpClientId \
    --credential-description "Terraform" \
    --output tsv --query password
)

# Return to our root
cd ../../..
```

### 2. (OPTIONAL) Run Packer to build the DevOps Agent base image

Packer configuration can be found under [infrastructure/packer/azdo-agent](infrastructure/packer/azdo-agent) for the agent.

You may need to set the client_id and client_secret variables depending on your configuration.

```bash
subscriptionId=$(az account show --output tsv --query id)
devopsImageName="linux-agent-image"
cd infrastructure/packer/azdo-agent
packer build -var resource_group=$resourceGroup -var image_name=$devopsImageName -var location=$location -var subscription_id=$subscriptionId agent.pkr.hcl

devopsImageId="/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/images/$devopsImageName"
echo "Image ID: $devopsImageId"
cd ../../..
```

### 3. Deploy the Azure Infrastructure

Under [infrastructure/terraform/kcidemo](infrastructure/terraform/kcidemo), there is a Terraform configuration that will use modules for configuration.

First we will create a file to store our generated source image from the last step.

```bash
# Initialize our directory
cd infrastructure/terraform/kcidemo
echo -e "resource_prefix = \"changeme\"" > terraform.tfvars

# Run Terraform
terraform init \
  -backend-config="resource_group_name=$resourceGroup" \
  -backend-config="storage_account_name=$storageAccount"
terraform validate
terraform apply

# Collect information
aksResourceGroup=$(terraform output -raw aks_resource_group_name)
aksName=$(terraform output -raw aks_name)
acrName=$(terraform output -raw acr_name)
acrAdminUser=$(terraform output -raw acr_admin_user)
acrAdminPassword=$(terraform output -raw acr_admin_password)
acrLoginServer=$(terraform output -raw acr_login_server)

# Return to our root
cd ../../..
```

Once the apply step finishes you should have an AKS cluster and ACR under your new resource group.

> **NOTE:** This does not include VMSS agents. For this you can use [this](infrastructure/terraform/azdo-vmss/README.md) template. You will also have to configure the pipelines to use this agent pool.

### 4. Deploy the Kubernetes Manifests

The below script will collect our AKS credentials and then apply the configuration used to give Azure DevOps a namespace to access and deploy to.

```bash
az aks get-credentials --resource-group $aksResourceGroup --name $aksName
kubectl apply -f infrastructure/kubernetes/kcidemo
```

## 3. Azure DevOps Configuration

> You must be using the preview feature [Multi-Stage Pipelines](https://docs.microsoft.com/en-us/azure/devops/project/navigation/preview-features?view=azure-devops) for this section.

The Azure DevOps Configuration uses a mixture of components, including its Repos, Pipelines and Tests for demonstration purposes.

We can create our project and set it as the default using the below commands

```bash
az devops project create --name kcidemo
```

On Project creation, it will give us a new repository with the same name as the project.

### Repository Setup

This demonstration assumes you will be using Azure DevOps to store your repository. If you prefer GitHub, there are annotations detailing what needs to be done to point to your own Github repository.

To change this repository to use Azure Repos, follow the below steps to get the Git URL, update your remote and push:

```bash
gitUrl=$(az repos list --project kcidemo --output tsv --query "[?name=='kcidemo'].remoteUrl")
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

To create this using a config file and variables above, run the below:

```bash
cat <<EOF | tee dockerlogin.json >/dev/null
{
  "id": "$(uuidgen)",
  "description": "",
  "administratorsGroup": null,
  "authorization": {
    "parameters": {
      "username": "$acrAdminUser",
      "password": "$acrAdminPassword",
      "email": "",
      "registry": "https://$acrLoginServer/v1/"
    },
    "scheme": "UsernamePassword"
  },
  "createdBy": null,
  "data": {
    "registrytype": "Others"
  },
  "name": "$acrLoginServer",
  "type": "dockerregistry",
  "url": "https://$acrLoginServer",
  "readersGroup": null,
  "groupScopeId": null,
  "serviceEndpointProjectReferences": null,
  "operationStatus": null
}
EOF

az devops service-endpoint create \
  --project kcidemo \
  --service-endpoint-configuration dockerlogin.json
```

#### AzureRM

AzureRM as a connection type is supported in the command line as-is.

We can create this with `az devops service-endpoint azurerm create`, allowing us to give it Service Principal credentials.

An example of doing this is below:

> **NOTE:** Propagation can cause this to fail if you create the role assignment quickly after the Service Principal creation.

```bash
AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$terraformSpPassword \
  az devops service-endpoint azurerm create \
  --project kcidemo \
  --name kcidemo \
  --azure-rm-tenant-id $(az account show --query tenantId --output tsv) \
  --azure-rm-subscription-id $(az account show --query id --output tsv) \
  --azure-rm-subscription-name $(az account show --query name --output tsv) \
  --azure-rm-service-principal-id $terraformSpClientId
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
az pipelines variable-group create --project kcidemo --name shared-app \
  --variables \
    appBasePath=application \
    appDomain=www.example.com \
    appKustomizePath=.devops/kubernetes/kustomize/app \
    containerRegistry=$acrLoginServer \
    kubernetesEnvironment=kcidemo \
    kubernetesResource=kcidemo
```

**Infrastructure - Terraform**

|Variable|Description|Variable Group|Value|
|-|-|-|-|
|terraformStateAzureSubscriptionName|The subscription used for Terraform state|shared-terraform|`"kcidemo"`|
|terraformStateStorageAccountName|The storage account used for Terraform state|shared-terraform|`"kcidemotfsa"`|
|terraformAzureSubscription|The service connection subscription to use for Terraform|shared-terraform|`"kcidemo"`|
|terraformWorkingDirectoryBase|The working directory base for Terraform|shared-terraform|`"infrastructure/terraform"`|

We can create and configure the variable group running the below commands

```bash
# create "shared" variable group
az pipelines variable-group create --project kcidemo --name shared-terraform \
  --variables \
    terraformStateAzureSubscriptionName=kcidemo \
    terraformStateStorageAccountName=$storageAccount \
    terraformAzureSubscription=kcidemo \
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
az pipelines variable-group create --project kcidemo --name shared-packer \
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
az pipelines create --project kcidemo --name www \
  --repository kcidemo --branch master --repository-type tfsgit \
  --yml-path application/www/azure-pipelines.yml --skip-run
```

2. Create the express pipeline

```bash
az pipelines create --project kcidemo --name express \
  --repository kcidemo --branch master --repository-type tfsgit \
  --yml-path application/express/azure-pipelines.yml --skip-run
```

3. Create the flask pipeline

```bash
az pipelines create --project kcidemo --name flask \
  --repository kcidemo --branch master --repository-type tfsgit \
  --yml-path application/flask/azure-pipelines.yml --skip-run
```

To then run a build you can use the `az pipelines run --name www` command.

**Infrastructure as Code**

Infrastructure as Code also supports the usage of pipelines for managing lifecycles.

Here we will create and configure our Terraform pipeline.

```bash
az pipelines create --project kcidemo --name terraformaksci \
  --repository kcidemo --branch master --repository-type tfsgit \
  --yml-path infrastructure/terraform/kcidemo/azure-pipelines.yml --skip-run

az pipelines variable create --project kcidemo --pipeline-name terraformaksci \
  --name terraformApply --value false --allow-override

az pipelines variable create --project kcidemo --pipeline-name terraformaksci \
  --name terraformDestroy --value false --allow-override

az pipelines variable create --project kcidemo --pipeline-name terraformaksci \
  --name resourcePrefix --value kcidemo --allow-override
```

And here we will create our Packer configuration.

```bash
az pipelines create --project kcidemo --name packerci \
  --repository kcidemo --branch master --repository-type tfsgit \
  --yml-path infrastructure/packer/azdo-agent/azure-pipelines.yml --skip-run

az pipelines variable create --project kcidemo --pipeline-name packerci \
  --name packerAzureLocation --value $location --allow-override

az pipelines variable create --project kcidemo --pipeline-name packerci \
  --name packerAzureResourceGroup --value $resourceGroup --allow-override
```

Finally we will create a pipeline for the VMSS agents

```bash
az pipelines create --project kcidemo --name terraformazdovmssci \
  --repository kcidemo --branch master --repository-type tfsgit \
  --yml-path infrastructure/terraform/azdo-vmss/azure-pipelines.yml --skip-run

az pipelines variable create --project kcidemo --pipeline-name terraformazdovmssci \
  --name terraformApply --value false --allow-override

az pipelines variable create --project kcidemo --pipeline-name terraformazdovmssci \
  --name terraformDestroy --value false --allow-override

az pipelines variable create --project kcidemo --pipeline-name terraformazdovmssci \
  --name resourcePrefix --value kcidemovmss --allow-override

az pipelines variable create --project kcidemo --pipeline-name terraformazdovmssci \
  --name vmAzdoSourceImageId --value $devopsImageId --allow-override
```

## 4. Cleanup

To clean everything up from this demonstration you can follow the below steps:

1. Delete the project from Azure DevOps in the portal or with the below commands
    1. Run `az devops project show --project kcidemo --query id --output tsv` to get the project ID
    2. Run `az devops project delete --id <replace with value from step 1>` to delete the project
2. Delete the demonstration resources with `kubectl delete -f infrastructure/kubernetes/kcidemo`
3. **(Optional)** Tear down Terraform-managed resources with `terraform destroy`
4. **(Optional)** Tear down created resource group with `az group delete --name $resourceGroup`
