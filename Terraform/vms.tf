# =============================================================================
# vms.tf - Création des VMs Ubuntu via clone du template
#
# Le provider bpg/proxmox utilise proxmox_virtual_environment_vm
# et gère le cloud-init via le bloc "initialization"
# =============================================================================
resource "proxmox_virtual_environment_file" "vendor_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data = <<-EOF
#cloud-config
packages:
  - qemu-guest-agent
runcmd:
  - systemctl enable --now qemu-guest-agent
EOF
    file_name = "vendor-data.yml"
  }
}
resource "proxmox_virtual_environment_vm" "vm" {
  for_each = var.vms

  name      = each.key
  vm_id     = each.value.vmid
  node_name = var.proxmox_node

  # Clone du template Ubuntu 24.04 (créé manuellement avec ID 9000)
  clone {
    vm_id = 9000
    full  = true
  }

  # CPU
  cpu {
    cores = each.value.vcpu
    type  = "host"
  }

  # RAM
  memory {
    dedicated = each.value.memory
  }

  # Disque principal
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = each.value.disk
    discard      = "on"
    iothread     = true
  }

  # Réseau
  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }

  # Cloud-init : remplace cloud-init.yml et network-config.yml
  initialization {
    datastore_id = "local-lvm"
    vendor_data_file_id = proxmox_virtual_environment_file.vendor_data.id

    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "10.0.0.1"
      }
    }

    dns {
      servers = ["10.0.0.1"]
    }

    user_account {
      username = "zeatop"
      keys     = [trimspace(var.ssh_public_key)]
    }
  }

  # QEMU Guest Agent
  agent {
    enabled = true
  }

  # Démarrage automatique
  on_boot = true

  # Arrêter la VM quand Terraform la supprime
  stop_on_destroy = true
  timeout_stop_vm = 30
}

# --- Output : IPs des VMs ---
output "vm_ips" {
  description = "IPs des VMs créées"
  value = {
    for name, vm in proxmox_virtual_environment_vm.vm :
    name => vm.ipv4_addresses
  }
}
