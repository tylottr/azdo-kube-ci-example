###########
# Azure AD
###########

resource "azuread_application" "terraform" {
  display_name = "Terraform"
}

resource "azuread_service_principal" "terraform" {
  application_id = azuread_application.terraform.application_id

  app_role_assignment_required = false
  tags                         = ["Terraform"]
}

resource "azurerm_role_assignment" "subscription" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.terraform.object_id
}

resource "azuread_group" "terraform" {
  display_name = "Terraform Administrators"
  description  = "A group for Terraform Administrators with access to core Terraform resources."
}

resource "azuread_group_member" "terraform" {
  for_each = local.admin_object_ids

  group_object_id  = azuread_group.terraform.id
  member_object_id = each.value
}

resource "azuread_group_member" "terraform_sp" {
  group_object_id  = azuread_group.terraform.id
  member_object_id = azuread_service_principal.terraform.object_id
}

######################
# Resource Management
######################

resource "azurerm_resource_group" "main" {
  name     = "${var.resource_prefix}-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_role_assignment" "terraform_resource_group_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.terraform.object_id
}

##########
# Storage
##########

resource "azurerm_storage_account" "state" {
  name                = lower(replace("${var.resource_prefix}tfssa", "/[-_]/", ""))
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  account_kind             = "BlobStorage"
  account_tier             = "Standard"
  account_replication_type = "GRS"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "state" {
  name                 = "tfstate"
  storage_account_name = azurerm_storage_account.state.name

  container_access_type = "private"
}

resource "azurerm_storage_account" "shell" {
  name                = lower(replace("${var.resource_prefix}tfcssa", "/[-_]/", ""))
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_share" "shell" {
  name                 = "cloudshell"
  storage_account_name = azurerm_storage_account.shell.name
  quota                = 5
}

###########
# Security
###########

resource "azurerm_key_vault" "main" {
  name                = lower(replace("${var.resource_prefix}tfkv", "/[-_]/", ""))
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name  = "standard"

  enabled_for_template_deployment = true
}

resource "azurerm_key_vault_access_policy" "main" {
  key_vault_id = azurerm_key_vault.main.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azuread_group.terraform.object_id

  certificate_permissions = [
    "get", "list", "delete", "create",
    "import", "update", "managecontacts",
    "getissuers", "listissuers", "setissuers",
    "deleteissuers", "manageissuers", "recover",
    "purge", "backup", "restore"
  ]

  key_permissions = [
    "encrypt", "decrypt", "wrapKey", "unwrapKey",
    "sign", "verify", "get", "list",
    "create", "update", "import", "delete",
    "backup", "restore", "recover", "purge"
  ]

  secret_permissions = [
    "get", "list", "set", "delete",
    "backup", "restore", "recover", "purge"
  ]

  storage_permissions = [
    "backup", "delete", "deletesas", "get",
    "getsas", "list", "listsas", "purge",
    "recover", "regeneratekey", "restore",
    "set", "setsas", "update"
  ]
}
