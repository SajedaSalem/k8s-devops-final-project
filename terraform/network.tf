resource "azurerm_resource_group" "k8slab" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "k8slab" {
  name                = "k8slab-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.k8slab.location
  resource_group_name = azurerm_resource_group.k8slab.name
}

resource "azurerm_subnet" "k8slab" {
  name                 = "k8slab-subnet"
  resource_group_name  = azurerm_resource_group.k8slab.name
  virtual_network_name = azurerm_virtual_network.k8slab.name
  address_prefixes     = [var.subnet_cidr]
}

resource "azurerm_network_security_group" "k8slab" {
  name                = "k8slab-nsg"
  location            = azurerm_resource_group.k8slab.location
  resource_group_name = azurerm_resource_group.k8slab.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_public_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Kubernetes-API"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = var.allowed_public_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Flask"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}