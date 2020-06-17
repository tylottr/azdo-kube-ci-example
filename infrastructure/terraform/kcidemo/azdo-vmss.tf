##########
# SSH Key
##########
resource "tls_private_key" "azdo" {
  algorithm = "RSA"
}

##################
# Virtual Network
##################
resource "azurerm_virtual_network" "azdo" {
  name                = "${var.resource_prefix}-azdo-vnet"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  address_space = ["10.10.0.0/24"]
}

resource "azurerm_subnet" "azdo" {
  name                = "azdo"
  resource_group_name = data.azurerm_resource_group.main.name

  virtual_network_name = azurerm_virtual_network.azdo.name
  address_prefixes     = [azurerm_virtual_network.azdo.address_space[0]]
}

##########
# Compute
##########
resource "azurerm_linux_virtual_machine_scale_set" "azdo" {
  name                = "${var.resource_prefix}-azdo-vmss"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  sku       = "Standard_B2s"
  instances = 1

  admin_username = "vmadmin"
  admin_ssh_key {
    username   = "vmadmin"
    public_key = tls_private_key.azdo.public_key_openssh
  }

  source_image_id = var.vm_azdo_source_image_id

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching              = "None"
    disk_size_gb         = 127
  }

  network_interface {
    name    = "primary"
    primary = true

    ip_configuration {
      name      = "ipconfig"
      primary   = true
      subnet_id = azurerm_subnet.azdo.id
    }
  }

  upgrade_mode  = "Manual"
  overprovision = false

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      tags,
      instances
    ]
  }
}
