#########
# Global
#########

variable "tenant_id" {
  description = "The tenant id of this deployment"
  type        = string
  default     = null

  validation {
    condition     = var.tenant_id == null || can(regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", var.tenant_id))
    error_message = "The tenant_id must to be a valid UUID."
  }
}

variable "subscription_id" {
  description = "The subscription id of this deployment"
  type        = string
  default     = null

  validation {
    condition     = var.subscription_id == null || can(regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", var.subscription_id))
    error_message = "The subscription_id must to be a valid UUID."
  }
}

variable "client_id" {
  description = "The client id of this deployment"
  type        = string
  default     = null

  validation {
    condition     = var.client_id == null || can(regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", var.client_id))
    error_message = "The client_id must to be a valid UUID."
  }
}

variable "client_secret" {
  description = "The client secret of this deployment"
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

##########
# Compute
##########

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
