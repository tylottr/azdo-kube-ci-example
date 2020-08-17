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

###########
# Security
###########

variable "admin_object_ids" {
  description = "Object IDs for administrative objects with full access to the Key Vault and Storage Account"
  type        = list(string)
  default     = []
}

#########
# Locals
#########

locals {
  admin_object_ids = toset(concat(
    [data.azurerm_client_config.current.object_id],
    var.admin_object_ids
  ))
}
