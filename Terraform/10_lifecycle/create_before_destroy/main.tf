
resource "azurerm_resource_group" "myrg1" {
    name        = var.rgname
    location    = var.location

    lifecycle {
      create_before_destroy = true
    }  
}

resource "azurerm_virtual_network" "myvnet1" {
    name  = "NextOpsVNET23"
    resource_group_name = azurerm_resource_group.myrg1.name
    location = azurerm_resource_group.myrg1.location
    address_space = ["${var.vnet_cidr_prefix}"]
    depends_on = [ azurerm_resource_group.myrg1 ]

    lifecycle {
      create_before_destroy = true
    }
}

resource "azurerm_subnet" "subnet1" {
    name = "Subnet1"
    resource_group_name = azurerm_resource_group.myrg1.name
    virtual_network_name = azurerm_virtual_network.myvnet1.name
    address_prefixes = ["${var.subnet1_cidr_prefix}"]  
    depends_on = [ azurerm_resource_group.myrg1, azurerm_virtual_network.myvnet1 ]

    lifecycle {
      create_before_destroy = true
    }
}

resource "azurerm_public_ip" "myVMPIP01" {
  name                = "NextOpsVML03PIP01"
  resource_group_name = azurerm_resource_group.myrg1.name
  location = azurerm_resource_group.myrg1.location
  allocation_method   = "Static"
  lifecycle {
      create_before_destroy = true
    }
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "NextOpsNSGT04"
  resource_group_name = azurerm_resource_group.myrg1.name
  location            = azurerm_resource_group.myrg1.location
  depends_on = [ azurerm_subnet.subnet1 ]
  lifecycle {
      create_before_destroy = true
    }
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.myrg1.name
  network_security_group_name = azurerm_network_security_group.nsg1.name

  depends_on = [ azurerm_network_security_group.nsg1 ]
  lifecycle {
      create_before_destroy = true
    }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id

  depends_on = [ azurerm_subnet.subnet1 ]
  lifecycle {
      create_before_destroy = true
    }
}

resource "azurerm_network_interface" "nic1" {
  name                = "NextOpsVML03-nic"
  resource_group_name = azurerm_resource_group.myrg1.name
  location            = azurerm_resource_group.myrg1.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.myVMPIP01.id
  }
  depends_on = [ azurerm_subnet.subnet1 ]
  lifecycle {
      create_before_destroy = true
    }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "NextOpsLVM03"
  resource_group_name             = azurerm_resource_group.myrg1.name
  location                        = azurerm_resource_group.myrg1.location
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  admin_password                  = "P@ssw0rd1234!"
  disable_password_authentication = false
  network_interface_ids = [ azurerm_network_interface.nic1.id ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  
  computer_name  = "NextOpsVML03"

  # provisioner "remote-exec" {
  #   inline = [    
  #     "ls -la /tmp",
  #     "hostname",
  #     "apt install net-tools -y",
  #     "ifconfig"
  #    ]

  #   connection {
  #    host     = self.public_ip_address
  #    user     = self.admin_username
  #    password = self.admin_password
  # }
    
  #}

  lifecycle {
      create_before_destroy = true
    }

  depends_on = [ azurerm_resource_group.myrg1,
  azurerm_network_interface.nic1,
  azurerm_virtual_network.myvnet1,
  azurerm_subnet.subnet1,
  azurerm_network_security_group.nsg1,
  azurerm_subnet_network_security_group_association.nsg_assoc1  
   ]
  
}