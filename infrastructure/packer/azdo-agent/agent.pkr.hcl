variable "subscription_id" {
  description = "The subscription id of this image"
  type        = string
  default     = env("AZURE_SUBSCRIPTION_ID")

  validation {
    condition     = var.subscription_id == null || can(regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", var.subscription_id))
    error_message = "The subscription_id must to be a valid UUID."
  }
}

variable "client_id" {
  description = "The client ID used to authenticate to Azure"
  type        = string
  default     = env("AZURE_CLIENT_ID")

  validation {
    condition     = var.client_id == null || can(regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", var.client_id))
    error_message = "The client_id must to be a valid UUID."
  }
}

variable "client_secret" {
  description = "The client secret used to authenticate to Azure"
  type        = string
  default     = env("AZURE_CLIENT_SECRET")
}

variable "location" {
  description = "The location of this image"
  type        = string
  default     = "centralus"
}

variable "resource_group" {
  description = "The resource group for this image"
  type        = string
}

locals {
  image_name = "vsts-agent-${formatdate("YYYY-MM-DD", timestamp())}"
  image = {
    image_offer     = "UbuntuServer"
    image_publisher = "Canonical"
    image_sku       = "18.04-LTS"
    image_os_type   = "Linux"
  }
}

source "azure-arm" "ubuntu" {
  azure_tags = {
    "Created By" = "packer"
  }

  client_id                         = var.client_id
  client_secret                     = var.client_secret
  subscription_id                   = var.subscription_id
  managed_image_resource_group_name = var.resource_group
  location                          = var.location

  image_offer        = local.image.image_offer
  image_publisher    = local.image.image_publisher
  image_sku          = local.image.image_sku
  managed_image_name = local.image_name
  os_type            = local.image.image_os_type
}

build {
  description = "Creates an Azure DevOps Agent base image"

  sources = ["source.azure-arm.ubuntu"]

  provisioner "ansible" {
    ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False", "ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'", "ANSIBLE_NOCOLOR=True", "ANSIBLE_NOCOWS=1"]
    playbook_file    = "agent.yml"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
