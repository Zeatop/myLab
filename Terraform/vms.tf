# =============================================================================
# vms.tf - Création des VMs (boucle sur la variable "vms")
# =============================================================================

# --- Disque de chaque VM ---
# En v0.9+, on utilise "backing_store" au lieu de "base_volume_id"
# et "capacity" au lieu de "size"
resource "libvirt_volume" "vm_disk" {
  for_each = var.vms

  name = "${each.key}-disk.qcow2"
  pool = "default"

  # Le format est sous target.format.type
  target = {
    format = {
      type = "qcow2"
    }
  }

  # Clone depuis l'image de base via backing_store
  backing_store = {
    path   = libvirt_volume.ubuntu_base.path
    format = {
      type = "qcow2"
    }
  }

  # Taille du disque
  capacity      = each.value.disk
  capacity_unit = "bytes"
}

# --- Cloud-init pour la configuration initiale ---
# En v0.9+, meta_data est obligatoire
resource "libvirt_cloudinit_disk" "vm_init" {
  for_each = var.vms

  name = "${each.key}-cloudinit.iso"

  user_data = templatefile("${path.module}/config/cloud-init.yml", {
    hostname = each.key
    ssh_public_key = var.ssh_public_key
  })

  meta_data = jsonencode({
    "instance-id"    = each.key
    "local-hostname" = each.key
  })

  network_config = templatefile("${path.module}/config/network-config.yml", {
    ip      = each.value.ip
    gateway = "192.168.122.1"
    dns     = "192.168.122.1"
  })
}

# --- Upload du cloud-init ISO dans le pool ---
resource "libvirt_volume" "vm_cloudinit" {
  for_each = var.vms

  name = "${each.key}-cloudinit.iso"
  pool = "default"

  create = {
    content = {
      url = libvirt_cloudinit_disk.vm_init[each.key].path
    }
  }
}

# --- La VM elle-même ---
# En v0.9+, "type" est obligatoire, les disques sont sous "devices.disks",
# les interfaces sous "devices.interfaces"
resource "libvirt_domain" "vm" {
  for_each = var.vms

  name        = each.key
  type        = "kvm"
  memory      = each.value.memory
  memory_unit = "MiB"
  vcpu        = each.value.vcpu

  # Configuration de l'OS
  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = [{ dev = "hd" }]
  }

  # Features hyperviseur
  features = {
    acpi = true
  }

  # Périphériques : disques, interfaces réseau, console, graphics
  devices = {
    # Disques
    disks = [
      {
        # Disque principal (clone de l'image Ubuntu)
        source = {
          volume = {
            pool   = "default"
            volume = libvirt_volume.vm_disk[each.key].name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        # Disque cloud-init (ISO)
        device = "cdrom"
        source = {
          volume = {
            pool   = "default"
            volume = libvirt_volume.vm_cloudinit[each.key].name
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]

    # Interface réseau
    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = libvirt_network.vm_network.name
          }
        }
        mac = {
          address = each.value.mac
        }
      }
    ]

    # Console série (debug)
    consoles = [
      {
        type = "pty"
        target = {
          type = "serial"
          port = 0
        }
      }
    ]
  }
}

# --- Output : affiche les noms des VMs créées ---
output "vm_names" {
  description = "Noms des VMs créées"
  value       = [for name, vm in libvirt_domain.vm : vm.name]
}
