# Terraform: azdo-kube-ci-example

This configuration is used to create an AKS Cluster and ACR. 

## Prerequisites

Prior to deployment you need the following:

- [terraform](https://www.terraform.io/) - 0.13
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

## Post-Deployment

Following deploymen you will need to configure your cluster based on your requirements e.g. Ingress, Cert-Manager, Monitoring.

This configuration has some Helm setups and other manifests that may be of use as a starting point.

A few key points in this section:

- You want to at least run `helm install nginx stable/nginx --version 1.29.2 --namespace kube-system --values .files/kubermetes/helm/values/nginx.yaml` against the cluster to have a solid Ingress configuration. Or use your own Ingress configuration

### Connecting to the Cluster

You can connect to your new cluster using the following command: `az aks get-credentials --name $(terraform output aks_name) --resource-group $(terraform output resource_group_name)`

- If using AAD RBAC integration you must be in one of the created AD groups to properly authenticate.

### Kubernetes Manifests

The below manifests will help create some baseline configurations in the cluster.

You can apply these manifests with `kubectl apply -f [MANIFEST]` where `MANIFEST` is either a folder or file. These files are all under [files/kubernetes/manifests](files/kubernetes/manifests).

**RBAC**

In the [files/kubernetes/manifests/rbac](rbac) folder we have the below files:

- [files/kubernetes/manifests/rbac/aks-aad.yaml](aks-aad.yaml): Needs updating prior to apply, but this is used to create group mappings to Azure Active Directory. This includes Cluster Admin and Cluster View roles.
- [files/kubernetes/manifests/rbac/cluster-admin.yaml](cluster-admin.yaml): Creates a Cluster Admin service account.
- [files/kubernetes/manifests/rbac/cluster-viewer.yaml](cluster-viewer.yaml): Creates a Cluster View service account.
- [files/kubernetes/manifests/rbac/default-helm.yaml](default-helm.yaml): Creates a Cluster-scope Helm service account that can only access Tiller.

**Cert Manager**

In the [files/kubernetes/manifests/cert-manager](cert-manager) folder we have the below files:

- [files/kubernetes/manifests/cert-manager/certificate.yaml](certificate.yaml): Needs updating. This is used to actually generate certificates as a resource. We can also use [Ingress Shims](https://cert-manager.io/docs/usage/ingress/) to create certificates directly through Ingresses.
- [files/kubernetes/manifests/cert-manager/clusterissuers.yaml](clusterissuers.yaml): Needs updating prior to apply, but this is used to create Production and Staging ClusterIssuers for generating certificates. 

**Storage Classes**

In the [files/kubernetes/manifests/storage-classes](storage-classes) folder we have the below files:

- [files/kubernetes/manifests/storage-classes/aks-disk.yaml](aks-disk.yaml): A collection of storage classes for AKS Managed Disk resources.
- [files/kubernetes/manifests/storage-classes/aks-file.yaml](aks-file.yaml): A collection of storage classes for AKS File resources

**Apps**

In the [files/kubernetes/manifests/apps](apps) folder we a demonstration application using Nginx.

### Kubernetes Helm

Helm is a package manager and can be used to template or consume templated Kubernetes manifests. You can download and read up on Helm [here](https://helm.sh/).

A number of basic Values files have been set up with version pinning. In the comments are steps to use the charts but we can use the following while within the [files/kubernetes/helm/values](files/kubernetes/helm/values) directory:

> Nginx Ingress is really the "main" one to use here, as it allows external access into cluster resources e.g. microservices

- Nginx Ingress: `helm install nginx-ingress stable/nginx-ingress --version 1.29.2 --namespace kube-system --values ./nginx-ingress.yaml`
- Cert Manager: `helm install cert-manager jetstack/cert-manager --version v0.13.1 --namespace kube-system --values ./cert-manager.yaml`
- Grafana: `helm install grafana stable/grafana --version 5.0.5 --namespace monitoring --values ./grafana.yaml`
- Prometheus: `helm install prometheus stable/prometheus --version 11.0.2 --namespace monitoring --values ./prometheus.yaml`
- Loki: `helm install loki loki/loki-stack --version 0.32.1 --namespace monitoring --values ./loki.yaml`
