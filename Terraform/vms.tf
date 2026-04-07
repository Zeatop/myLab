# =============================================================================
# vms.tf - Création des VMs (boucle sur la variable "vms")
# =============================================================================

# --- Disque de chaque VM ---
# On crée un volume (disque) par VM, basé sur l'image Ubuntu de base
# "for_each" itère sur la map vms : une itération = une VM
resource "libvirt_volume" "vm_disk" {
  for_each = var.vms

  name           = "${each.key}-disk.qcow2"          # Ex: "ci-cd-disk.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_base.id      # Clone de l'image Ubuntu de base
  size           = each.value.disk                     # Taille du disque depuis la variable
  format         = "qcow2"
}

# --- Cloud-init pour la configuration initiale de chaque VM ---
# Cloud-init s'exécute au premier boot de la VM
# C'est lui qui configure le hostname, l'utilisateur, les clés SSH, etc.
resource "libvirt_cloudinit_disk" "vm_init" {
  for_each = var.vms

  name = "${each.key}-cloudinit.iso"   # Un petit disque ISO injecté dans la VM
  pool = "default"

  # La config cloud-init au format YAML
  user_data = templatefile("${path.module}/cloud-init.yml", {
    hostname = each.key                # Le nom de la VM (ci-cd, k8s-master, etc.)
  })

  # La config réseau (IP fixe, gateway, DNS)
  network_config = templatefile("${path.module}/network-config.yml", {
    ip      = each.value.ip
    gateway = "192.168.122.1"
    dns     = "192.168.122.1"
  })
}

# --- La VM elle-même ---
resource "libvirt_domain" "vm" {
  for_each = var.vms

  name   = each.key                  # Nom de la VM dans KVM (ex: "ci-cd")
  memory = each.value.memory         # RAM en Mo
  vcpu   = each.value.vcpu           # Nombre de CPU virtuels

  # On active QEMU guest agent (permet à libvirt de communiquer avec la VM)
  qemu_agent = true

  # Le disque principal : on référence le volume créé plus haut
  disk {
    volume_id = libvirt_volume.vm_disk[each.key].id
  }

  # Le disque cloud-init (lu au premier boot puis ignoré)
  disk {
    volume_id = libvirt_cloudinit_disk.vm_init[each.key].id
  }

  # Configuration réseau : on rattache la VM au réseau NAT
  network_interface {
    network_id     = libvirt_network.vm_network.id  # Notre réseau
    mac            = each.value.mac                  # MAC fixe = IP fixe via DHCP
    wait_for_lease = true  # Terraform attend que la VM ait son IP avant de continuer
  }

  # Console série (utile pour le debug si la VM ne boot pas)
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"   # Protocole d'affichage (pour virt-manager si besoin)
    listen_type = "address"
    autoport    = true
  }
}

# --- Output : affiche les IPs après le déploiement ---
output "vm_ips" {
  description = "IPs de toutes les VMs"
  value = {
    for name, vm in libvirt_domain.vm :
    name => vm.network_interface[0].addresses
  }
}