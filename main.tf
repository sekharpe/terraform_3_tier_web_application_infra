resource "azurerm_resource_group" "Azure_resource_group" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "Vnet1" {
  name                = "Vnet1"
  location            = azurerm_resource_group.Azure_resource_group.location
  resource_group_name = azurerm_resource_group.Azure_resource_group.name
  address_space       = ["10.0.0.0/16"]
  

}
resource "azurerm_subnet" "public_subnet" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.Azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.Azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_subnet" "database_subnet" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.Azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_public_ip" "lb_pip" {
  name                = "lb-public-ip"
  location            = azurerm_resource_group.Azure_resource_group.location
  resource_group_name = azurerm_resource_group.Azure_resource_group.name
  allocation_method   = "Static"
  
}

# resource "azurerm_load_balancer" "lb" {
#   name                = "lb"
#   location            = azurerm_resource_group.Azure_resource_group.location
#   resource_group_name = azurerm_resource_group.Azure_resource_group.name
#   sku                 = "Standard"  # Required for Availability Zones
#   zones               = ["1", "2"]  # Specify the Availability Zones
#   frontend_ip_configuration {
#     name                 = "lb-frontend"
#     public_ip_address_id = azurerm_public_ip.lb_pip.id
#   }

#   backend_address_pool {
#     name = "lb-backend-pool"
#   }
# Load Balancer Resource
resource "azurerm_lb" "lb" {
  name                = "lb"
  location            = azurerm_resource_group.Azure_resource_group.location
  resource_group_name = azurerm_resource_group.Azure_resource_group.name
  sku                 = "Standard"
  

  frontend_ip_configuration {
    name                 = "lb-frontend"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
    #zones = [ "1", "2" ]
  }
}

# Backend Pool Resource
resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "lb-backend-pool"
}

resource "azurerm_lb_nat_pool" "lbnatpool" {
  name               = "nat-pool"
  loadbalancer_id    = azurerm_lb.lb.id
  protocol           = "Tcp"
  frontend_port_start = 50000
  frontend_port_end   = 50119
  backend_port       = 22  # Use 3389 for RDP, or 22 for SSH if using Linux VMs
  #frontend_ip_configuration_id = azurerm_lb.lb.frontend_ip_configuration[0].id
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  resource_group_name = azurerm_resource_group.Azure_resource_group.name
}


resource "azurerm_virtual_machine_scale_set" "vmscaleset" {
  name                = "vmscaleset"
  location            = azurerm_resource_group.Azure_resource_group.location
  resource_group_name = azurerm_resource_group.Azure_resource_group.name
  zones = ["1", "2"]
  upgrade_policy_mode = "Manual"

  
  


#   # automatic rolling upgrade
#   automatic_os_upgrade = true
#   upgrade_policy_mode  = "Rolling"

#   rolling_upgrade_policy {
#     max_batch_instance_percent              = 20
#     max_unhealthy_instance_percent          = 20
#     max_unhealthy_upgraded_instance_percent = 5
#     pause_time_between_batches              = "PT0S"
#   }

#   # required when using rolling upgrade policy
#   health_probe_id = azurerm_lb_probe.lb.id

  sku {
    name     = "Standard_B1s"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18_04-lts-gen2"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "testvm"
    admin_username       = "azureuser"
    admin_password       = "Sekhar@89"
  }

#   os_profile_linux_config {
#     disable_password_authentication = true

#     ssh_keys {
#       path     = "/home/myadmin/.ssh/authorized_keys"
#       key_data = file("~/.ssh/demo_key.pub")
#     }
#   }
 

  network_profile {
    name    = "vm_network_profile"
    primary = true

    ip_configuration {
      name                                   = "VmIPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.public_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      #load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.lbnatpool.id]
    }
  }

  tags = {
    environment = "staging"
  }
}








