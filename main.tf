# main.tf

# Specifies Azure as our cloud provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# A resource group is like a folder for all your Azure resources
resource "azurerm_resource_group" "rg" {
  name     = "ServiceNow-RG"
  location = "East US"
}

# A virtual network for the VM
resource "azurerm_virtual_network" "vnet" {
  name                = "sre-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# A subnet inside the network
resource "azurerm_subnet" "subnet" {
  name                 = "default-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# A network interface for the VM
resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# This is the actual Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "ServiceNowVM"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B1s" # A small, inexpensive size
  admin_username        = "azureuser"
  admin_password        = "Password1234!" # Note: For production, use SSH keys
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.nic.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
