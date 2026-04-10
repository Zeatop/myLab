# Terraform — Provisionnement des VMs sur Proxmox

## Description

Ce répertoire contient les fichiers Terraform permettant de provisionner automatiquement les VMs sur Proxmox VE 9.1. L'ensemble de l'infrastructure tourne sur un seul serveur physique (AMD Ryzen 7 5800H, 28 Go RAM, 460 Go SSD).

## Architecture

```
Serveur physique (Proxmox VE 9.1)
│
├── opnsense        Firewall / Routeur (installation manuelle depuis ISO)
├── ci-cd           Jenkins + SonarQube
├── k8s-master      Control plane Kubernetes
├── k8s-worker-1    Applications + Traefik (Ingress)
├── k8s-worker-2    Applications
├── bdd             MongoDB
└── elk             Elasticsearch + Kibana + Prometheus + Grafana
```

## Plan des VMs

| VM | VMID | RAM | vCPU | Disque | IP |
|---|---|---|---|---|---|
| OPNsense | 100 | 1 Go | 1 | 10 Go | 192.168.1.2 |
| CI/CD | 110 | 4 Go | 4 | 50 Go | 192.168.1.10 |
| K8s Master | 120 | 3 Go | 2 | 30 Go | 192.168.1.20 |
| K8s Worker 1 | 121 | 4 Go | 4 | 80 Go | 192.168.1.21 |
| K8s Worker 2 | 122 | 4 Go | 4 | 80 Go | 192.168.1.22 |
| BDD | 130 | 4 Go | 2 | 60 Go | 192.168.1.30 |
| ELK | 140 | 3 Go | 2 | 50 Go | 192.168.1.40 |

**Total : 23 Go RAM, 19 vCPU, 360 Go disque** — 5 Go restants pour l'hôte Proxmox.

## Structure des fichiers

```
Terraform/
├── main.tf          # Provider Proxmox + authentification API
├── variables.tf     # Specs de toutes les VMs (RAM, CPU, disque, IP)
├── vms.tf           # Création des VMs par clone du template
├── test_vms.sh      # Script de démarrage et vérification des VMs
└── README.md        # Ce fichier
```

## Prérequis

- Proxmox VE 9.1 installé et accessible sur https://192.168.1.144:8006
- Terraform installé sur le serveur Proxmox
- Template Ubuntu 24.04 cloud-init créé (ID 9000)
- Token API Proxmox configuré pour l'utilisateur terraform
- Variables d'environnement configurées dans ~/.bashrc :
  - `TF_VAR_proxmox_api_token` : le secret du token API
  - `TF_VAR_ssh_public_key` : la clé publique SSH

## Utilisation

```bash
terraform init
terraform plan
terraform apply

# Vérifier les VMs
sudo ./test_vms.sh
```

## Différences avec l'ancienne version (KVM/libvirt)

- Plus besoin de cloud-init.yml ni network-config.yml (intégrés dans la ressource Proxmox)
- Plus besoin de network.tf (le bridge vmbr0 est géré par Proxmox)
- Plus de problèmes AppArmor / permissions QEMU (Proxmox gère tout)
- Une seule ressource Terraform par VM au lieu de quatre
- OPNsense ajouté comme firewall/routeur

## Notes

- OPNsense (VMID 100) s'installe manuellement depuis un ISO, pas via Terraform
- Le template Ubuntu 24.04 (ID 9000) doit être créé une seule fois via CLI
- Les IPs sont sur le réseau local (192.168.1.x) via le bridge vmbr0
