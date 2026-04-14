# =============================================================================
# variables.tf - Specs des VMs et configuration réseau
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

variable "vms" {
  default = {
    "ci-cd" = {
      vmid   = 110
      memory = 6144
      vcpu   = 4
      disk   = 50
      ip     = "10.0.0.10"
    }
    "k8s-master" = {
      vmid   = 120
      memory = 2048
      vcpu   = 2
      disk   = 30
      ip     = "10.0.0.20"
    }
    "k8s-worker-1" = {
      vmid   = 121
      memory = 3072
      vcpu   = 4
      disk   = 80
      ip     = "10.0.0.21"
    }
    "k8s-worker-2" = {
      vmid   = 122
      memory = 3072
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

# =============================================================================
# Documentation réseau (non provisionné par Terraform, pour référence)
# =============================================================================
# 
# OPNsense (VMID 100) - installé manuellement via ISO
#   WAN: 192.168.1.159 (DHCP depuis Freebox)
#   LAN: 10.0.0.1 (gateway pour toutes les VMs)
#   Admin UI: https://192.168.1.159:8443
#
# Freebox → OPNsense port forwarding:
#   80  → 192.168.1.159:80
#   443 → 192.168.1.159:443
#
# OPNsense → K8s NAT rules (Traefik):
#   WAN:80  → 10.0.0.22:30000  (Traefik HTTP)
#   WAN:443 → 10.0.0.22:30001  (Traefik HTTPS)
#
# Domaines (DNS OVH → 82.67.163.199):
#   leo-jackson.com      → portfolio-xp (K8s)
#   leo-jackson.com/safemode → portfolio classique (K8s)
#   judgeai.app          → judge-front (K8s)
#   api.judgeai.app      → judge API (K8s)
#
# K8s Services (NodePorts):
#   30000 - Traefik HTTP
#   30001 - Traefik HTTPS
#   30080 - Portfolio classique
#   30081 - Portfolio XP
#   30090 - Judge Front
#   30091 - Judge API
#
# Traefik:
#   Helm chart v39.0.7, Traefik v3.6.12
#   Namespace: traefik
#   Node: k8s-worker-2 (nodeSelector)
#   Certificats Let's Encrypt: /opt/traefik-data/acme.json
#   Email: leo_jacson@hotmail.fr