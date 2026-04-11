# =============================================================================
# variables.tf - Specs des VMs
# =============================================================================

variable "proxmox_api_token" {
  description = "Secret du token API Proxmox"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Clé publique SSH pour l'accès aux VMs"
  type        = string
}

variable "proxmox_node" {
  description = "Nom du noeud Proxmox"
  type        = string
  default     = "mylab"
}

variable "proxmox_root_password" {
  description = "Mot de passe root de Proxmox (pour SSH)"
  type        = string
  sensitive   = true
}

variable "vms" {
  default = {
    "ci-cd" = {
      vmid   = 110
      memory = 4096
      vcpu   = 4
      disk   = 50
      ip     = "10.0.0.10"
    }
    "k8s-master" = {
      vmid   = 120
      memory = 4096
      vcpu   = 2
      disk   = 30
      ip     = "10.0.0.20"
    }
    "k8s-worker-1" = {
      vmid   = 121
      memory = 4096
      vcpu   = 4
      disk   = 80
      ip     = "10.0.0.21"
    }
    "k8s-worker-2" = {
      vmid   = 122
      memory = 4096
      vcpu   = 4
      disk   = 80
      ip     = "10.0.0.22"
    }
    "bdd" = {
      vmid   = 130
      memory = 4096
      vcpu   = 2
      disk   = 60
      ip     = "10.0.0.30"
    }
    "elk" = {
      vmid   = 140
      memory = 3072
      vcpu   = 2
      disk   = 50
      ip     = "10.0.0.40"
    }
  }
}