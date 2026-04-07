# =============================================================================
# variables.tf - Les specs de tes VMs centralisées ici
# =============================================================================

# Une map qui contient toutes les VMs et leurs caractéristiques
# C'est ici que tu ajouteras les autres VMs (k8s-master, workers, bdd, elk)
variable "vms" {
  default = {
    "ci-cd" = {
      memory  = 5120              # RAM en Mo (5 Go = 5 x 1024)
      vcpu    = 4                 # Nombre de vCPU
      disk    = 53687091200       # Taille du disque en octets (50 Go = 50 x 1024^3)
      ip      = "192.168.122.10" # IP fixe dans le réseau NAT
      mac     = "52:54:00:00:01:10" # Adresse MAC pour la réservation DHCP
    }
    "k8s-master" = {
      memory  = 4096              # RAM en Mo (4 Go = 4 x 1024)
      vcpu    = 2                 # Nombre de vCPU
      disk    = 32212254720       # Taille du disque en octets (30 Go = 30 x 1024^3)
      ip      = "192.168.122.20" # IP fixe dans le réseau NAT
      mac     = "52:54:00:00:01:20" # Adresse MAC pour la réservation DHCP
    }
    "k8s-worker-1" = {
      memory  = 5120              # RAM en Mo (5 Go = 5 x 1024)
      vcpu    = 4                 # Nombre de vCPU
      disk    = 85899345920       # Taille du disque en octets (80 Go = 80 x 1024^3)
      ip      = "192.168.122.21" # IP fixe dans le réseau NAT
      mac     = "52:54:00:00:01:21" # Adresse MAC pour la réservation DHCP
    }
    "k8s-worker-2" = {
      memory  = 5120              # RAM en Mo (5 Go = 5 x 1024)
      vcpu    = 4                 # Nombre de vCPU
      disk    = 85899345920       # Taille du disque en octets (80 Go = 80 x 1024^3)
      ip      = "192.168.122.22" # IP fixe dans le réseau NAT
      mac     = "52:54:00:00:01:22" # Adresse MAC pour la réservation DHCP
     }
    "bdd" = {
      memory  = 4096              # RAM en Mo (4 Go = 4 x 1024)
      vcpu    = 2                 # Nombre de vCPU
      disk    = 64424509440       # Taille du disque en octets (60 Go = 60 x 1024^3)
      ip      = "192.168.122.30" # IP fixe dans le réseau NAT
      mac     = "52:54:00:00:01:30" # Adresse MAC pour la réservation DHCP
    }
    "elk" = {
      memory  = 3072              # RAM en Mo (3 Go = 3 x 1024)
      vcpu    = 2                 # Nombre de vCPU
      disk    = 53687091200       # Taille du disque en octets (50 Go = 50 x 1024^3)
      ip      = "192.168.122.40" # IP fixe dans le réseau NAT
      mac     = "52:54:00:00:01:40" # Adresse MAC pour la réservation DHCP
    }
  }
}