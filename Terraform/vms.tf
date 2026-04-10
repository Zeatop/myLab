# =============================================================================
# vms.tf - Création des VMs Ubuntu via clone du template Proxmox
# =============================================================================

resource "proxmox_vm_qemu" "vm" {
  for_each = var.vms

  name        = each.key
  vmid        = each.value.vmid
  target_node = var.proxmox_node
  desc        = "VM ${each.key} - provisionné par Terraform"

  clone      = var.template_name
  full_clone = true

  cores   = each.value.vcpu
  memory  = each.value.memory
  sockets = 1
  cpu     = "host"

  os_type = "cloud-init"

  scsihw = "virtio-scsi-pci"
  disk {
    size    = each.value.disk
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  ciuser  = "zeatop"
  sshkeys = var.ssh_public_key

  ipconfig0  = "ip=${each.value.ip}/24,gw=${each.value.gateway}"
  nameserver = "192.168.1.254"

  agent = 1
  onboot = true

  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

output "vm_ips" {
  description = "IPs des VMs créées"
  value = {
    for name, vm in proxmox_vm_qemu.vm :
    name => vm.default_ipv4_address
  }
}