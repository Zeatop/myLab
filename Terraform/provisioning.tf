# =============================================================================
# provisioning.tf - Post-provisioning des VMs
#
# Crée les dossiers nécessaires sur les nodes K8s après le déploiement
# des VMs. Ces dossiers sont utilisés par les hostPath volumes K8s.
# =============================================================================

# --- Dossier Traefik (certificats Let's Encrypt) sur k8s-worker-2 ---
resource "null_resource" "traefik_data_dir" {
  depends_on = [proxmox_virtual_environment_vm.vm["k8s-worker-2"]]

  connection {
    type        = "ssh"
    host        = "10.0.0.22"
    user        = "zeatop"
    private_key = file("~/.ssh/id_ed25519")

    # Passer par le Proxmox host comme bastion (les VMs sont sur le LAN interne)
    bastion_host        = "192.168.1.144"
    bastion_user        = "root"
    bastion_private_key = file("~/.ssh/id_ed25519")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/traefik-data",
      "sudo chmod 777 /opt/traefik-data",
      "echo '[OK] Traefik data directory created on k8s-worker-2'"
    ]
  }
}

# --- Dossier ChromaDB (Judge AI) sur les workers ---
resource "null_resource" "judge_data_dirs" {
  for_each = toset(["k8s-worker-1", "k8s-worker-2"])

  depends_on = [proxmox_virtual_environment_vm.vm]

  connection {
    type        = "ssh"
    host        = var.vms[each.key].ip
    user        = "zeatop"
    private_key = file("~/.ssh/id_ed25519")

    bastion_host        = "192.168.1.144"
    bastion_user        = "root"
    bastion_private_key = file("~/.ssh/id_ed25519")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /data/judge/chroma_db",
      "sudo chmod 777 /data/judge/chroma_db",
      "echo '[OK] Judge ChromaDB directory created on ${each.key}'"
    ]
  }
}