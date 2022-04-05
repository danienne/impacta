terraform {
  required_version = ">= 0.13"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "azurerm_resource_group" "rg-tarefainfracloud" {
  name     = "tarefainfracloudterraform"
  location = "australiaeast"
}

resource "azurerm_virtual_network" "vnet-tarefainfra" {
  name                = "vnet-tarefa"
  location            = azurerm_resource_group.rg-tarefainfracloud.location
  resource_group_name = azurerm_resource_group.rg-tarefainfracloud.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Production"
    faculdade = "Impacta"
    turma = "ES23"
  }
}

resource "azurerm_subnet" "sub-tarefainfra" {
  name                 = "sub-tarefa"
  resource_group_name  = azurerm_resource_group.rg-tarefainfracloud.name
  virtual_network_name = azurerm_virtual_network.vnet-tarefainfra.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "ip-tarefainfra" {
  name                = "ip-tarefa"
  resource_group_name = azurerm_resource_group.rg-tarefainfracloud.name
  location            = azurerm_resource_group.rg-tarefainfracloud.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_security_group" "nsg-tarefainfra" {
  name                = "nsg-tarefa"
  location            = azurerm_resource_group.rg-tarefainfracloud.location
  resource_group_name = azurerm_resource_group.rg-tarefainfracloud.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "web"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "nic-tarefainfra" {
  name                = "nic-tarefa"
  location            = azurerm_resource_group.rg-tarefainfracloud.location
  resource_group_name = azurerm_resource_group.rg-tarefainfracloud.name

  ip_configuration {
    name                            = "ip-tarefa-nic"
    subnet_id                       = azurerm_subnet.sub-tarefainfra.id
    private_ip_address_allocation   = "Dynamic"
    public_ip_address_id            = azurerm_public_ip.ip-tarefainfra.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-tarefainfra" {
  network_interface_id      = azurerm_network_interface.nic-tarefainfra.id
  network_security_group_id = azurerm_network_security_group.nsg-tarefainfra.id
}

resource "azurerm_virtual_machine" "vm-tarefainfra" {
  name                  = "vm-tarefa"
  location              = azurerm_resource_group.rg-tarefainfracloud.location
  resource_group_name   = azurerm_resource_group.rg-tarefainfracloud.name
  network_interface_ids = [azurerm_network_interface.nic-tarefainfra.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username =  var.user
    admin_password =  var.pwr_user
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
  
  tags = {
    environment = "staging"
  }
}

data "azurerm_public_ip" "ip-tarefa"{
    name = azurerm_public_ip.ip-tarefainfra.name
    resource_group_name = azurerm_resource_group.rg-tarefainfracloud.name
}

resource "null_resource" "install-apache" {
  connection {
    type = "ssh"
    host = data.azurerm_public_ip.ip-tarefa.ip_address
    user = var.user
    password = var.pwr_user
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y apache2",
    ]
  }

  depends_on = [
    azurerm_virtual_machine.vm-tarefainfra
  ]
}