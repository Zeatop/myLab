# =============================================================================
# vms.tf - Création des VMs (clone du template Ubuntu)
#
# Avec Proxmox, une seule ressource remplace les 4 qu'on avait avec libvirt :
# - libvirt_volume (disque)       → intégré dans proxmox_vm_qemu
# - libvirt_cloudinit_disk        → intégré (ipconfig0, ciuser, sshkeys)
# - libvirt_volume.vm_cloudinit   → plus nécessaire
# - libvirt_domain                → proxmox_vm_qemu
# =============================================================================

# Filtrer uniquement les VMs qui se clonent depuis le template Ubuntu
locals {
  ubuntu_vms = { for k, v in var.vms : k => v if v.clone == true }
}

resource "proxmox_vm_qemu" "vm" {
  for_each = local.ubuntu_vms

  # --- Identité ---
  name        = each.key
  vmid        = each.value.vmid
  target_node = var.proxmox_node
  desc        = "VM ${each.key} - provisionné par Terraform"

  # --- Clone du template ---
  clone      = var.template_name
  full_clone = true

  # --- Ressources ---
  cores   = each.value.vcpu
  memory  = each.value.memory
  sockets = 1
  cpu     = "host"

  # --- OS ---
  os_type = "cloud-init"

  # --- Disque principal ---
  scsihw = "virtio-scsi-pci"
  disk {
    size    = each.value.disk
    type    = "scsi"
    storage = "local-lvm"
  }

  # --- Réseau ---
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # --- Cloud-init ---
  # Remplace cloud-init.yml et network-config.yml
  ciuser  = "zeatop"
  sshkeys = var.ssh_public_key

  # Configuration IP statique
  ipconfig0 = "ip=${each.value.ip}/24,gw=${each.value.gateway}"

  # DNS
  nameserver = "192.168.1.254"

  # --- QEMU Guest Agent ---
  agent = 1

  # --- Démarrage automatique ---
  onboot = true

  # --- Lifecycle ---
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# --- Output : IPs des VMs ---
output "vm_ips" {
  description = "IPs des VMs créées"
  value = {
    for name, vm in proxmox_vm_qemu.vm :
    name => vm.default_ipv4_address
  }
}
