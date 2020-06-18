#########
# Global
#########
variable "tenant_id" {
  description = "The tenant id of this deployment"
  type        = string
  default     = null
}

variable "subscription_id" {
  description = "The subscription id of this deployment"
  type        = string
  default     = null
}

variable "location" {
  description = "The location of this deployment"
  type        = string
  default     = "Central US"
}

variable "resource_prefix" {
  description = "A prefix for the name of the resource, used to generate the resource names"
  type        = string
}

variable "tags" {
  description = "Tags given to the resources created by this template"
  type        = map(string)
  default     = {}
}

#################################
# Azure Devops specific variables
#################################
variable "vm_azdo_source_image_id" {
  description = "ID of a source image for the Linux Azure DevOps VMs"
  type        = string
}

#########
# Locals
#########
locals {
  resource_prefix = "${var.resource_prefix}-azdo"
}
