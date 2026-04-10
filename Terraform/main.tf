# =============================================================================
# main.tf - Provider Proxmox
# =============================================================================

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://192.168.1.144:8006/api2/json"
  pm_api_token_id     = "terraform@pam!terraform_token"
  pm_api_token_secret = var.proxmox_api_token
  pm_tls_insecure     = true
}