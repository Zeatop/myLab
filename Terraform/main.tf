# =============================================================================
# main.tf - Provider Proxmox
# =============================================================================

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 3.0"
    }
  }
}

provider "proxmox" {
  # URL de l'API Proxmox
  pm_api_url = "https://192.168.1.144:8006/api2/json"

  # Authentification par token API (créé dans l'UI Proxmox)
  pm_api_token_id     = "terraform@pam!terraform_token"
  pm_api_token_secret = var.proxmox_api_token

  # Accepter le certificat auto-signé de Proxmox
  pm_tls_insecure = true
}
