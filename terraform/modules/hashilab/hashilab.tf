#variable declarations
variable "vnet-name" {
  type    = "string"
  default = "HashiLab-vnet"
}
variable "vnet-cidr" {
  type    = "string"
  default = "10.0.0.0/16"
}
variable "server-subnet-cidr" {
  type    = "string"
  default = "10.0.0.0/24"
}
variable "jumpbox-subnet-cidr" {
  type    = "string"
  default = "10.0.1.0/24"
}
variable "rg-name" {
  type    = "string"
  default = "HashiLab-rg"
}
variable "location" {
  type    = "string"
  default = "West US"
}
variable "admin-username" {
  type    = "string"
  default = "hashilord"
}
variable "admin-password" {
  type    = "string"
  default = "passwords-ARE-fun-to-set-7"
}
variable "inbound-rdp-allow-cidr" {
  type    = "string"
  default = "*"
}

# Build resource group
resource "azurerm_resource_group" "HashiLab" {
  name     = "${var.rg-name}"
  location = "${var.location}"

}

# Build a virtual network
resource "azurerm_virtual_network" "HashiLab" {
  name                = "${var.vnet-name}"
  resource_group_name = "${azurerm_resource_group.HashiLab.name}"
  location            = "${azurerm_resource_group.HashiLab.location}"
  address_space       = ["${var.vnet-cidr}"]
  tags = {
    environment = "HashiLab"
    deployedBy  = "terraform"
  }
}

# Build a server subnet
resource "azurerm_subnet" "Servers" {
  name                 = "HashiLab-Servers-subnet"
  virtual_network_name = "${azurerm_virtual_network.HashiLab.name}"
  resource_group_name  = "${azurerm_resource_group.HashiLab.name}"
  address_prefix       = "${var.server-subnet-cidr}"
}

# Build a jumpbox subnet
resource "azurerm_subnet" "Jumpboxes" {
  name                 = "HashiLab-Jumpboxes-subnet"
  virtual_network_name = "${azurerm_virtual_network.HashiLab.name}"
  resource_group_name  = "${azurerm_resource_group.HashiLab.name}"
  address_prefix       = "${var.jumpbox-subnet-cidr}"
}


# Build a NIC
resource "azurerm_network_interface" "vm1nic0" {
  name                = "consul001-nic0"
  resource_group_name = "${azurerm_resource_group.HashiLab.name}"
  location            = "${azurerm_resource_group.HashiLab.location}"

  ip_configuration {
    name                          = "consul001-ipconfig"
    subnet_id                     = "${azurerm_subnet.Servers.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags = {
    environment = "HashiLab"
    deployedBy  = "terraform"
  }
}

# Build a lab server VM
resource "azurerm_virtual_machine" "ConsulServer" {
  name                  = "consul001"
  location              = "${azurerm_resource_group.HashiLab.location}"
  resource_group_name   = "${azurerm_resource_group.HashiLab.name}"
  network_interface_ids = ["${azurerm_network_interface.vm1nic0.id}"]

  vm_size = "Standard_B1s"

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }
  storage_os_disk {
    name              = "osdisk-consul001"
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "consul001"
    admin_username = "${var.admin-username}"
    admin_password = "${var.admin-password}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }


  tags = {
    environment = "HashiLab"
    deployedBy  = "terraform"
    description = "Consul Application Server"
  }
}

# Build a jump box nic
resource "azurerm_public_ip" "jumpboxPip" {
  name                    = "jumpbox001-pip"
  resource_group_name     = "${azurerm_resource_group.HashiLab.name}"
  location                = "${azurerm_resource_group.HashiLab.location}"
  allocation_method       = "Dynamic"
  domain_name_label       = "hashilab-jumpbox"
  ip_version              = "IPv4"
  idle_timeout_in_minutes = 4

  tags = {
    environment = "HashiLab"
    deployedBy  = "terraform"
  }

}

# Build a NIC
resource "azurerm_network_interface" "vm2nic0" {
  name                      = "jumpbox001-nic0"
  resource_group_name       = "${azurerm_resource_group.HashiLab.name}"
  location                  = "${azurerm_resource_group.HashiLab.location}"
  network_security_group_id = "${azurerm_network_security_group.vm2nsg.id}"

  ip_configuration {
    name                          = "prdapp0001-ipconfig"
    subnet_id                     = "${azurerm_subnet.Jumpboxes.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jumpboxPip.id}"
  }

  tags = {
    environment = "HashiLab"
    deployedBy  = "terraform"
  }
}

# Build a network security group
resource "azurerm_network_security_group" "vm2nsg" {
  name                = "jumpbox-nsg"
  location            = "${azurerm_resource_group.HashiLab.location}"
  resource_group_name = "${azurerm_resource_group.HashiLab.name}"

  security_rule {
    name                       = "jumpbox-3389-allow"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "${var.inbound-rdp-allow-cidr}"
    destination_address_prefix = "${var.jumpbox-subnet-cidr}"
  }

  tags = {
    environment = "HashiLab"
    deployedBy  = "terraform"
  }

}
# Build a jump box vm
resource "azurerm_virtual_machine" "Jumpbox" {
  name                = "jumpbox001"
  location            = "${azurerm_resource_group.HashiLab.location}"
  resource_group_name = "${azurerm_resource_group.HashiLab.name}"

  network_interface_ids = ["${azurerm_network_interface.vm2nic0.id}"]

  vm_size = "Standard_B1s"

  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "rs4-pro"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-jumpbox001"
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "jumpbox001"
    admin_username = "${var.admin-username}"
    admin_password = "${var.admin-password}"
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true
    provision_vm_agent        = true
  }

  tags = {
    environment = "HashiLab"
    deployedBy  = "terraform"
    description = "Terraform jump box"
  }
}
