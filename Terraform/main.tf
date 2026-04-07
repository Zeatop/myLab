# =============================================================================
# main.tf - Provider et image de base
# =============================================================================

# On déclare le provider libvirt, c'est le "connecteur" entre Terraform et KVM
# L'URI indique qu'on se connecte à l'hyperviseur KVM local
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"  # Le provider communautaire pour KVM
      version = "~> 0.8"             # On fixe une version pour éviter les surprises
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"  # Connexion locale à KVM (pas de SSH, on est sur le serveur)
}

# =============================================================================
# L'image de base Ubuntu 24.04 au format cloud image (qcow2)
# C'est un disque "template" qu'on va cloner pour chaque VM
# =============================================================================
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-24.04-base.qcow2"           # Nom du fichier dans le pool libvirt
  pool   = "default"                             # Le pool de stockage par défaut de libvirt
  source = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  format = "qcow2"                               # Format du disque (standard pour KVM)
}