variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "germanywestcentral"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "k8slab-rg"
}

variable "vnet_cidr" {
  description = "Virtual network CIDR"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "vnet_cidr must be valid CIDR notation."
  }
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be valid CIDR notation."
  }
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D2s_v7"
}

variable "admin_username" {
  description = "Initial VM administrator username"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/k8slab_key.pub"
}

variable "nodes" {
  description = "Kubernetes nodes and their static private IPs"

  type = map(object({
    hostname   = string
    private_ip = string
  }))

  default = {
    cp1 = {
      hostname   = "k8slab-cp1"
      private_ip = "10.0.1.10"
    }

    w1 = {
      hostname   = "k8slab-w1"
      private_ip = "10.0.1.11"
    }


  }
}

variable "allowed_public_ip" {
  description = "Your public IP in CIDR format for SSH and Kubernetes API access"
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_public_ip, 0))
    error_message = "allowed_public_ip must be valid CIDR notation, for example 203.0.113.10/32."
  }
}