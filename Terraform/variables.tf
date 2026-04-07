# =============================================================================
# variables.tf - Les specs de tes VMs centralisées ici
# =============================================================================

variable "vms" {
  default = {
    "ci-cd" = {
      memory  = 5120
      vcpu    = 4
      disk    = 53687091200
      ip      = "192.168.122.10"
      mac     = "52:54:00:00:01:10"
    }
    "k8s-master" = {
      memory  = 4096
      vcpu    = 2
      disk    = 32212254720
      ip      = "192.168.122.20"
      mac     = "52:54:00:00:01:20"
    }
    "k8s-worker-1" = {
      memory  = 5120
      vcpu    = 4
      disk    = 85899345920
      ip      = "192.168.122.21"
      mac     = "52:54:00:00:01:21"
    }
    "k8s-worker-2" = {
      memory  = 5120
      vcpu    = 4
      disk    = 85899345920
      ip      = "192.168.122.22"
      mac     = "52:54:00:00:01:22"
    }
    "bdd" = {
      memory  = 4096
      vcpu    = 2
      disk    = 64424509440
      ip      = "192.168.122.30"
      mac     = "52:54:00:00:01:30"
    }
    "elk" = {
      memory  = 3072
      vcpu    = 2
      disk    = 53687091200
      ip      = "192.168.122.40"
      mac     = "52:54:00:00:01:40"
    }
  }
}

variable "ssh_public_key" {
  description = "Clé publique SSH pour l'accès aux VMs"
  type        = string
}
