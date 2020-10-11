provider "azurerm" {
features {}
}

variable "rgname" {
    description = "resource group name"
    default     = "azure_sitecore_rg"
}
variable "location" {
    description = "location name"
    default     = "East Us"
}

variable "vnet_name" {
     description = "name for vnet"
     default     = "sitecore_vnet"
}
variable "address_space" {
     default     = ["10.0.0.0/16"]
}
variable "subnet_name" {
     default     = "public_subnet"
}
variable "address_prefixes" {
      default     = ["10.0.2.0/24"]
}
#for security
variable "external_ip" {
    type        = list(string)
   default      = ["your public ip to allow traffic to server"]
}
variable "numbercount" {
    type 	  = number
    default       = 2
} 

# Virtual Resource_group
resource "azurerm_resource_group" "azure_rg" {
  name     =  var.rgname
  location =  var.location
}


# Virtual Network
resource "azurerm_virtual_network" "vnet" {
    name                 = var.vnet_name
    address_space        = var.address_space
    location             = var.location
    resource_group_name  = var.rgname
}
# Subnet for virtual machine
resource "azurerm_subnet" "public_subnet" {
  name                  =  var.subnet_name
  address_prefixes      =  var.address_prefixes
  virtual_network_name  =  var.vnet_name
  resource_group_name   =  var.rgname
}




# Add a Public IP address
resource "azurerm_public_ip" "vmip" {
    count                  = var.numbercount
    name                   = "vm-ip-${count.index}"
    resource_group_name    =  var.rgname
    allocation_method      = "Static"
    location               = var.location
}

# Add a Network security group
resource "azurerm_network_security_group" "vm-nsg" {
    name                   = "vm-nsg"
    location               = var.location
    resource_group_name    =  var.rgname
    
    security_rule {
        name                       = "PORT_SSH"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        #source_address_prefixes   = var.external_ip
        source_address_prefix      = "*"
        destination_address_prefix = "*"
  }
}
#Associate NSG with  subnet
resource "azurerm_subnet_network_security_group_association" "nsgsubnet" {
    subnet_id                    = azurerm_subnet.public_subnet.id 
    network_security_group_id    = azurerm_network_security_group.vm-nsg.id 
}

# NIC with Public IP Address
resource "azurerm_network_interface" "terranic" {
    count                  = var.numbercount
    name                   = "vm-nic-${count.index}"
    location               = var.location
    resource_group_name    =  var.rgname
    
    ip_configuration {
        name                          = "external"
        subnet_id                     = azurerm_subnet.public_subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = element(azurerm_public_ip.vmip.*.id, count.index)
  }
  
}
#Data Disk for Virtual Machine
resource "azurerm_managed_disk" "datadisk" {
 count                = var.numbercount
 name                 = "datadisk_existing_${count.index}"
 location             = var.location
 resource_group_name  = var.rgname
 storage_account_type = "Standard_LRS"
 create_option        = "Empty"
 disk_size_gb         = "20"
}

#Aure Virtual machine
resource "azurerm_virtual_machine" "terravm" {
    name                  = "vm-sitecore-${count.index}"
    location              = var.location
    resource_group_name   = var.rgname
    count 		  = var.numbercount
    network_interface_ids = [element(azurerm_network_interface.terranic.*.id, count.index)]
    vm_size               = "Standard_DS1_v2"
    delete_os_disk_on_termination = true
    delete_data_disks_on_termination = true


storage_os_disk {
    name                 = "osdisk-${count.index}"
    caching              = "ReadWrite"
    create_option        = "FromImage"
    managed_disk_type    = "Premium_LRS"
    disk_size_gb         = "30"
  }

 storage_data_disk {
   name              = element(azurerm_managed_disk.datadisk.*.name, count.index)
   managed_disk_id   = element(azurerm_managed_disk.datadisk.*.id, count.index)
   create_option     = "Attach"
   lun               = 1
   disk_size_gb      = element(azurerm_managed_disk.datadisk.*.disk_size_gb, count.index)
 }

   storage_image_reference {
   publisher = "Oracle"
   offer     = "Oracle-Linux"
   sku       = "78"
   version   = "latest"
 }
  os_profile {
        computer_name = "hostname"
        admin_username = "sitecore"
}
os_profile_linux_config {
      disable_password_authentication = true
       
        ssh_keys {
        path     = "/home/sitecore/.ssh/authorized_keys"
        key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAmxajbA1QS8tIE4i4CyQm1UBuA5e64UpjYhGm/IjBR029dAtPsJT/vRMik941ykoDS4bDQxCGQ+q6iCE1W5saBtyg8IrbXg56tBqvn9LkZyGxVnaMzpQa1g7jWVSkiq0K6CNa0yQ1vYrT+5CiC8AGyqNUDVuKNQFRUE8IWilAUFLb1t3kMgwkHg0CSDBgBZZ59jaB3KlZETwIdZZ2xn/NrdoJOsZBXJXO4U1/zvfzSntmZXgDuJCQxDDRXTaY/GKH27rOWrK6S1EFNx/xjq6+Tgf0JcMzN3QakXVoQzpPleMbxN06TgRypBUkahnCIK7XFk8ukQ2qOWIbKfwFfMdfRQ== rsa-key-20201011"
      }
    }
connection {
        host = azurerm_public_ip.admingwip.id
        user = "sitecore"
        type = "ssh"
        private_key = "${file("./id_rsa")}"
        timeout = "1m"
        agent = true
  }

}    
