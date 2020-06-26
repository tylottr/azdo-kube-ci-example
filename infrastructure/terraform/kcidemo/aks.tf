###############
# Module - AKS
###############
module "aks" {
  source = "github.com/tylottr/tf-az-kubernetes.git?ref=v0.2.3"

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  location        = var.location

  resource_prefix = var.resource_prefix
  tags            = var.tags

  enable_acr       = true
  enable_acr_admin = true

  aks_node_size      = "Standard_B2ms"
  aks_node_min_count = 1
  aks_node_max_count = 2
}
