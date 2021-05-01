# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }

  required_version = ">= 0.14.9"
}
  provider "azurerm" {
    features {}
  }

  resource "azurerm_resource_group" "rg" {
    location = "eastus2"
    name = "myTFResourceGroup"

    tags = {
      Environment = "Terraform Getting Started"
      Team = "DevOps"
    }
  }

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  address_space = ["10.0.0.0/16"]
  location = "eastus2"
  name = "myTFVnet"
  resource_group_name = azurerm_resource_group.rg.name
}

variable "admin_username" {
  type = string
  description = "Administrator user name for VM"
}

variable "admin_password" {
  type = string
  description = "Password must meet Azure complexity requirements"
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name = "myTFSubnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  allocation_method = "Static"
  location = "eastus2"
  name = "myTFPublicIP"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  location = "eastus2"
  name = "myTFNSG"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    access = "Allow"
    direction = "Inbound"
    name = "SSH"
    priority = 1001
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  location = "eastus2"
  name = "myNIC"
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name = "myNICConfg"
    private_ip_address_allocation = "dynamic"
    subnet_id = azurerm_subnet.subnet.id
    public_ip_address_id = azurerm_public_ip.publicip.id
  }
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
  location = "eastus2"
  name = "myTFVM"
  network_interface_ids = [azurerm_network_interface.nic.id]
  resource_group_name = azurerm_resource_group.rg.name
  vm_size = "Standard_DS1_v2"

  storage_os_disk {
    create_option = "FromImage"
    name = "myOsDisk"
    caching = "ReadWrite"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "16.04.0-LTS"
    version = "latest"
  }

  os_profile {
    computer_name = "myTFVM"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

data "azurerm_public_ip" "ip" {
  name = azurerm_public_ip.publicip.name
  resource_group_name = azurerm_virtual_machine.vm.resource_group_name
  depends_on = [azurerm_virtual_machine.vm]
}