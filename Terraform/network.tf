# =============================================================================
# network.tf - Configuration réseau avec IPs fixes
# =============================================================================

# On redéfinit le réseau "default" de libvirt pour y ajouter nos réservations DHCP
# Chaque VM aura une IP fixe grâce à l'association MAC -> IP
resource "libvirt_network" "vm_network" {
  name      = "vm-network"          # Nom du réseau
  mode      = "nat"                  # Mode NAT (les VMs accèdent à internet via le serveur)
  domain    = "lab.local"            # Nom de domaine interne (pour la résolution DNS entre VMs)
  addresses = ["192.168.122.0/24"]   # Le sous-réseau

  # Le serveur DHCP intégré à libvirt
  dhcp {
    enabled = true  # On active le DHCP mais avec des réservations fixes
  }

  # Pour chaque VM dans notre variable, on crée une réservation DHCP
  # dynamic = itère sur la map "vms" pour générer un bloc par VM
  dynamic "dns" {
    for_each = var.vms
    content {
      # Chaque VM sera joignable par son hostname sur le réseau
      # Ex: ping ci-cd.lab.local depuis une autre VM
      hostname = dns.key           # La clé de la map = le hostname
      ip       = dns.value.ip     # L'IP associée
    }
  }
}