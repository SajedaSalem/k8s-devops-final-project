resource "azurerm_public_ip" "nodes" {
  for_each = var.nodes

  name                = "${each.value.hostname}-pip"
  location            = azurerm_resource_group.k8slab.location
  resource_group_name = azurerm_resource_group.k8slab.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nodes" {
  for_each = var.nodes

  name                = "${each.value.hostname}-nic"
  location            = azurerm_resource_group.k8slab.location
  resource_group_name = azurerm_resource_group.k8slab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.k8slab.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip
    public_ip_address_id          = azurerm_public_ip.nodes[each.key].id
  }
}

resource "azurerm_network_interface_security_group_association" "nodes" {
  for_each = var.nodes

  network_interface_id      = azurerm_network_interface.nodes[each.key].id
  network_security_group_id = azurerm_network_security_group.k8slab.id
}

resource "azurerm_linux_virtual_machine" "nodes" {
  for_each = var.nodes

  name                = each.value.hostname
  computer_name       = each.value.hostname
  location            = azurerm_resource_group.k8slab.location
  resource_group_name = azurerm_resource_group.k8slab.name
  size                = var.vm_size
  admin_username      = var.admin_username


  custom_data = base64encode(
    templatefile("${path.module}/templates/cloud-init.yaml", {})
  )

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.nodes[each.key].id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-base"
    version   = "latest"
  }

  plan {
    publisher = "resf"
    product   = "rockylinux-x86_64"
    name      = "9-base"
  }


}