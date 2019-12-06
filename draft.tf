#----------providers--------
provider "azuread" {}
provider "azurerm" {}
#----------vars--------
variable "prefix" {default = "dpl0"}
variable "location" {default = "westeurope"}
variable "admin_username" {default = "oro"}
variable "rg_name" {default = "vm-cent"}
variable "vm_offer" {default = "CentOS"}
variable "vm_sku" {default = "7-CI"}
variable "vm_os_publisher" {default = "OpenLogic"}
variable "vm_size" {default = "Standard_DS1_v2"}
variable "vm_name" {default = "deploysrv"}
variable "vm_user" {default = "deploysrv"}
variable "admin_pass" {default="Or0Sup3rS4f3p4SS!!"}
#-------------main---------------
resource "azurerm_resource_group" "vm-cent" {
  name =  var.rg_name
  location = var.location
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm_nsg"
  location            = var.location
  resource_group_name = var.rg_name
  security_rule {
    access = "Allow"
    direction = "Inbound"
    name = "ssh"
    priority = 100
    protocol = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-virtualNetwork1"
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = ["10.0.0.0/16"]
 # dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

resource "azurerm_subnet" "subnet1" {
  name = "${var.prefix}-subnet1"
  resource_group_name = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix = "10.0.1.0/24"
}

resource "azurerm_public_ip" "azure_vm_public_ip" {
      name                         = "${var.prefix}-vm_pubip"
      location                     = var.location
      resource_group_name          = var.rg_name
      allocation_method            = "Dynamic"
      }

resource "azurerm_network_interface" "azure_vm_network_interface_card" {
    name                      = format("%s%s",var.vm_name,"-nic")
    location                  = var.location
    resource_group_name       = var.rg_name
    network_security_group_id = azurerm_network_security_group.vm_nsg.id
    ip_configuration {
        name                          = format("%s%s",var.vm_name,"-ipConf")
        subnet_id                     = azurerm_subnet.subnet1.id
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = azurerm_public_ip.azure_vm_public_ip.id
    }
}
#----------------creating vm------
resource "azurerm_virtual_machine" "azure_virtual_machine" {
    name                  = var.vm_name
    location              = var.location
    resource_group_name   = var.rg_name
    network_interface_ids = [azurerm_network_interface.azure_vm_network_interface_card.id]
    vm_size               = var.vm_size

    storage_os_disk {
        name              = format("%s%s",var.vm_name,"-OSDisk")
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }
    storage_image_reference {
        publisher = var.vm_os_publisher
        offer     = var.vm_offer
        sku       = var.vm_sku
        version   = "latest"
    }
    os_profile {
        computer_name  =  var.vm_name
        admin_username = var.vm_user
        admin_password = var.admin_pass
    }

    os_profile_linux_config {
        disable_password_authentication = false
       /* ssh_keys {
            path     = format("/home/%s/.ssh/authorized_keys",var.vm_user)
            key_data = file(var.vm_ssh_key_path)
        }*/
    }
}
#--------------------- OUTPUT
output "public_ip_address" {
  value = azurerm_public_ip.azure_vm_public_ip.ip_address
  description = "Public connect to the VM"
}

output "private_ip_address" {
  value = azurerm_network_interface.azure_vm_network_interface_card.private_ip_address
  description = "Private IP address of the VM"
}

 output "pass" {
   value = azurerm_virtual_machine.azure_virtual_machine.os_profile
 }

/*output "pubip" {
  value = [azurerm_public_ip.azure_vm_public_ip.ip_address]
}

output "vm_username" {
  value = azurerm_virtual_machine.azure_virtual_machine.os_profile.[0].admin_username
}

output "vm_password" {
  value =azurerm_virtual_machine.azure_virtual_machine.os_profile.[0].admin_password
}*/
