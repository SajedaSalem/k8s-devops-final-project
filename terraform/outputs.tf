output "public_ips" {
  description = "Public IP addresses of the Kubernetes nodes"

  value = {
    for name, pip in azurerm_public_ip.nodes :
    name => pip.ip_address
  }
}

output "private_ips" {
  description = "Private IP addresses of the Kubernetes nodes"

  value = {
    for name, nic in azurerm_network_interface.nodes :
    name => nic.private_ip_address
  }
}

output "ssh_commands" {
  description = "Ready-to-use SSH commands"

  value = {
    for name, pip in azurerm_public_ip.nodes :
    name => "ssh -i ~/.ssh/k8slab_key ${var.admin_username}@${pip.ip_address}"
  }
}