#############
# Monitoring
#############

resource "azurerm_log_analytics_workspace" "main" {
  count = var.enable_monitoring && var.log_analytics_workspace_id != null ? 1 : 0

  name                = "${local.resource_prefix}-oms"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  sku               = "PerGB2018"
  retention_in_days = 30
}

##########
# Storage
##########

resource "azurerm_container_registry" "main" {
  count = var.enable_acr ? 1 : 0

  name                = lower(replace("${local.resource_prefix}acr", "/[-_]/", ""))
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  sku                      = var.acr_sku
  georeplication_locations = length(var.acr_georeplication_locations) < 1 ? null : var.acr_georeplication_locations

  admin_enabled = var.enable_acr_admin
}

resource "azurerm_role_assignment" "main_acr_pull" {
  count = var.enable_acr ? 1 : 0

  scope                = azurerm_container_registry.main[count.index].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

##########
# Compute 
##########

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.resource_prefix
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  kubernetes_version = var.aks_kubernetes_version

  dns_prefix = local.resource_prefix

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true

    dynamic azure_active_directory {
      /*
       * If enabling RBAC and app settings are not set,
       * an error will be returned. This is by design
       * to avoid accidentally creating a cluster without
       * AAD integration.
       **
      */
      for_each = var.enable_aks_aad_rbac ? [true] : []

      content {
        tenant_id         = var.aks_aad_tenant_id
        client_app_id     = var.aks_aad_client_app_id
        server_app_id     = var.aks_aad_server_app_id
        server_app_secret = var.aks_aad_server_app_secret
      }
    }
  }

  api_server_authorized_ip_ranges = ["0.0.0.0/0"]

  network_profile {
    network_plugin    = var.enable_aks_advanced_networking ? "azure" : "kubenet"
    load_balancer_sku = "Standard"

    pod_cidr           = var.enable_aks_advanced_networking ? null : "10.244.0.0/16"
    network_policy     = var.aks_network_policy
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = var.aks_service_cidr
    dns_service_ip     = cidrhost(var.aks_service_cidr, 10)
  }

  default_node_pool {
    name                  = "default"
    type                  = "VirtualMachineScaleSets"
    tags                  = var.tags
    enable_auto_scaling   = true
    enable_node_public_ip = false

    vm_size    = var.aks_node_size
    node_count = var.aks_node_min_count
    min_count  = var.aks_node_min_count
    max_count  = var.aks_node_max_count

    vnet_subnet_id = var.enable_aks_advanced_networking ? data.azurerm_subnet.main[0].id : null
  }

  addon_profile {
    kube_dashboard {
      // Disabling to reduce default resource usage. If needed enable manually via Helm or Azure.
      enabled = false
    }

    oms_agent {
      enabled                    = var.enable_monitoring
      log_analytics_workspace_id = var.enable_monitoring ? coalesce(var.log_analytics_workspace_id, azurerm_log_analytics_workspace.main[0].id) : null
    }
  }

  lifecycle {
    ignore_changes = [
      default_node_pool,
      kubernetes_version,
      service_principal,
      role_based_access_control,
      addon_profile
    ]
  }
}

data "azurerm_monitor_diagnostic_categories" "main_aks" {
  resource_id = azurerm_kubernetes_cluster.main.id
}

resource "azurerm_monitor_diagnostic_setting" "main_aks" {
  count = var.enable_monitoring ? 1 : 0

  name                       = "${local.resource_prefix}-diag"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = coalesce(var.log_analytics_workspace_id, azurerm_log_analytics_workspace.main[0].id)

  dynamic log {
    for_each = data.azurerm_monitor_diagnostic_categories.main_aks.logs
    iterator = log_category

    content {
      category = log_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 7
      }
    }
  }

  dynamic metric {
    for_each = data.azurerm_monitor_diagnostic_categories.main_aks.metrics
    iterator = metric_category

    content {
      category = metric_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 7
      }
    }
  }
}