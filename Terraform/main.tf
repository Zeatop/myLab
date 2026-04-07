# =============================================================================
# main.tf - Provider et image de base
# =============================================================================

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# =============================================================================
# Image de base Ubuntu 24.04 cloud image
# En v0.9+, on utilise "create.content.url" au lieu de "source"
# et "target.format.type" au lieu de "format"
# =============================================================================
resource "libvirt_volume" "ubuntu_base" {
  name = "ubuntu-24.04-base.qcow2"
  pool = "default"

  # Télécharge l'image depuis le web
  create = {
    content = {
      url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    }
  }

  # Le format est maintenant sous target.format.type
  target = {
    format = {
      type = "qcow2"
    }
  }
}
