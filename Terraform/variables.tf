# =============================================================================
# variables.tf - Specs des VMs
# =============================================================================

# Token API Proxmox (via TF_VAR_proxmox_api_token)
variable "proxmox_api_token" {
  description = "Token API Proxmox pour l'authentification"
  type        = string
  sensitive   = true
}

# Clé publique SSH (via TF_VAR_ssh_public_key)
variable "ssh_public_key" {
  description = "Clé publique SSH pour l'accès aux VMs"
  type        = string
}

# Nom du noeud Proxmox
variable "proxmox_node" {
  description = "Nom du noeud Proxmox"
  type        = string
  default     = "mylab"
}

# ID du template Ubuntu cloud-init
variable "template_id" {
  description = "ID du template Ubuntu 24.04"
  type        = number
  default     = 9000
}

# Nom du template à cloner
variable "template_name" {
  description = "Nom du template Ubuntu 24.04"
  type        = string
  default     = "ubuntu-24.04-template"
}

# =============================================================================
# Plan des VMs
#
# Budget RAM : 28 Go total - 2 Go hôte Proxmox = 26 Go pour les VMs
#
# Ancien plan (26 Go) :
#   ci-cd: 5 Go, k8s-master: 4 Go, workers: 5+5 Go, bdd: 4 Go, elk: 3 Go
#
# Nouveau plan (26 Go) avec OPNsense :
#   opnsense: 1 Go, ci-cd: 4 Go, k8s-master: 3 Go, workers: 4+4 Go,
#   bdd: 4 Go, elk: 3 Go, restant hôte: 3 Go
# =============================================================================
variable "vms" {
  default = {
    "opnsense" = {
      vmid    = 100
      memory  = 1024        # 1 Go — suffisant pour un firewall/routeur
      vcpu    = 1
      disk    = "10G"
      ip      = "192.168.1.2"
      gateway = "192.168.1.254"
      clone   = false       # OPNsense s'installe depuis un ISO, pas un clone
    }
    "ci-cd" = {
      vmid    = 110
      memory  = 4096        # 4 Go (réduit de 5 Go)
      vcpu    = 4
      disk    = "50G"
      ip      = "192.168.1.10"
      gateway = "192.168.1.254"
      clone   = true
    }
    "k8s-master" = {
      vmid    = 120
      memory  = 4096        # 4 Go (réduit de 4 Go)
      vcpu    = 2
      disk    = "30G"
      ip      = "192.168.1.20"
      gateway = "192.168.1.254"
      clone   = true
    }
    "k8s-worker-1" = {
      vmid    = 121
      memory  = 4096        # 4 Go (réduit de 5 Go)
      vcpu    = 4
      disk    = "80G"
      ip      = "192.168.1.21"
      gateway = "192.168.1.254"
      clone   = true
    }
    "k8s-worker-2" = {
      vmid    = 122
      memory  = 4096        # 4 Go (réduit de 5 Go)
      vcpu    = 4
      disk    = "80G"
      ip      = "192.168.1.22"
      gateway = "192.168.1.254"
      clone   = true
    }
    "bdd" = {
      vmid    = 130
      memory  = 4096        # 4 Go — inchangé pour MongoDB
      vcpu    = 2
      disk    = "60G"
      ip      = "192.168.1.30"
      gateway = "192.168.1.254"
      clone   = true
    }
    "elk" = {
      vmid    = 140
      memory  = 3072        # 3 Go — inchangé
      vcpu    = 2
      disk    = "50G"
      ip      = "192.168.1.40"
      gateway = "192.168.1.254"
      clone   = true
    }
  }
}
