# =============================================================================
# network.tf - Configuration réseau avec IPs fixes
# =============================================================================

resource "libvirt_network" "vm_network" {
  name = "vm-network"

  # En v0.9+, le mode de forwarding est un objet sous "forward"
  forward = {
    mode = "nat"
  }

  # Le domaine DNS est un objet, pas une simple string
  domain = {
    name       = "lab.local"
    local_only = "yes"
  }

  # Les IPs sont maintenant configurées via le bloc "ips"
  # avec les réservations DHCP intégrées
  ips = [
    {
      address = "192.168.122.1"
      prefix  = 24
      family  = "ipv4"

      dhcp = {
        ranges = [
          {
            start = "192.168.122.100"
            end   = "192.168.122.254"
          }
        ]

        # Réservations DHCP : chaque MAC -> IP fixe
        hosts = [
          { mac = "52:54:00:00:01:10", name = "ci-cd",         ip = "192.168.122.10" },
          { mac = "52:54:00:00:01:20", name = "k8s-master",    ip = "192.168.122.20" },
          { mac = "52:54:00:00:01:21", name = "k8s-worker-1",  ip = "192.168.122.21" },
          { mac = "52:54:00:00:01:22", name = "k8s-worker-2",  ip = "192.168.122.22" },
          { mac = "52:54:00:00:01:30", name = "bdd",           ip = "192.168.122.30" },
          { mac = "52:54:00:00:01:40", name = "elk",           ip = "192.168.122.40" },
        ]
      }
    }
  ]

  # DNS activé pour la résolution entre VMs
  dns = {
    enable = "yes"

    # Entrées DNS statiques pour chaque VM
    hosts = [
      { hostname = "ci-cd",        ip = "192.168.122.10" },
      { hostname = "k8s-master",   ip = "192.168.122.20" },
      { hostname = "k8s-worker-1", ip = "192.168.122.21" },
      { hostname = "k8s-worker-2", ip = "192.168.122.22" },
      { hostname = "bdd",          ip = "192.168.122.30" },
      { hostname = "elk",          ip = "192.168.122.40" },
    ]
  }

  autostart = true
}
