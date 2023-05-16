# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.90.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "main" {
  name = "learn-tf-rg-uksouth"
  location = "uksouth"
}

#Creates virtual network
resource "azurerm_virtual_network" "main" {
  name = "learn-tf-vnet-uksouth"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space = ["10.0.0.0/16"]
}

#Create subnet
resource "azurerm_subnet" "main" {
  name = "learn-tf-subnet-uksouth"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name = azurerm_resource_group.main.name
  address_prefixes = ["10.0.0.0/24"]
}

#Create public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "vm_public_ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
}

#Create network interface card (NIC)
resource "azurerm_network_interface" "internal" {
  name = "learn-tf-nic-int-uksouth"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

#Create Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name = "rdp_nsg"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name = "allow_rdp_sg"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "3389"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

#Associate NSG with network interface
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id = azurerm_network_interface.internal.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Create Virtual Machine
resource "azurerm_windows_virtual_machine" "main" {
  name = "learn-tf-vm-uk1"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = "Standard_B1s"
  admin_username = "user.admin"
  admin_password = "Password123!"

  network_interface_ids = [
    azurerm_network_interface.internal.id
  ]

  os_disk {
     caching = "ReadWrite"
     storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = "2022-DataCenter"
    version = "latest"
  }
}

output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}