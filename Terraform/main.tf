# =============================================================================
# main.tf - Provider BPG/Proxmox
# =============================================================================

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.78"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://192.168.1.144:8006/"
  api_token = "terraform@pam!terraform_token=${var.proxmox_api_token}"
  insecure  = true

  ssh {
    agent    = false
    username = "root"
    private_key = file("~/.ssh/id_ed25519")
    node {
      name    = "mylab"
      address = "192.168.1.144"
    }
  }
}