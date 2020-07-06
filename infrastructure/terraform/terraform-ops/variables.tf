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

####################
# Resource-Specific
####################
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
