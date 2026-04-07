# Terraform — Provisionnement des VMs

## Description

Ce répertoire contient les fichiers Terraform permettant de provisionner automatiquement les machines virtuelles KVM/libvirt du lab. L'ensemble de l'infrastructure tourne sur un seul serveur physique (AMD Ryzen 7 5800H, 28 Go RAM, 460 Go SSD) sous Ubuntu 24.04.

## Architecture

```
Serveur physique (KVM/libvirt)
│
├── ci-cd           Jenkins + SonarQube
├── k8s-master      Control plane Kubernetes
├── k8s-worker-1    Applications + Traefik (Ingress)
├── k8s-worker-2    Applications
├── bdd             MongoDB
└── elk             Elasticsearch + Kibana
```

## Plan des VMs

| VM | Hostname | RAM | vCPU | Disque | IP |
|---|---|---|---|---|---|
| CI/CD | ci-cd | 5 Go | 4 | 50 Go | 192.168.122.10 |
| K8s Master | k8s-master | 4 Go | 2 | 30 Go | 192.168.122.20 |
| K8s Worker 1 | k8s-worker-1 | 5 Go | 4 | 80 Go | 192.168.122.21 |
| K8s Worker 2 | k8s-worker-2 | 5 Go | 4 | 80 Go | 192.168.122.22 |
| BDD | bdd | 4 Go | 2 | 60 Go | 192.168.122.30 |
| ELK | elk | 3 Go | 2 | 50 Go | 192.168.122.40 |

**Total : 26 Go RAM, 18 vCPU, 350 Go disque**

## Plan d'adressage réseau

Le réseau est en mode NAT via `virbr0` (192.168.122.0/24). Les IPs sont réservées par groupe fonctionnel :

- **192.168.122.1** — Gateway (hôte KVM)
- **192.168.122.1x** — CI/CD
- **192.168.122.2x** — Cluster Kubernetes
- **192.168.122.3x** — Base de données
- **192.168.122.4x** — Monitoring / ELK

## Structure des fichiers

```
Terraform/
├── main.tf              # Provider libvirt + image de base Ubuntu 24.04
├── variables.tf         # Specs de toutes les VMs (RAM, CPU, disque, IP, MAC)
├── network.tf           # Réseau NAT + réservations DHCP + DNS interne
├── vms.tf               # Création des VMs (volumes, cloud-init, domaines)
├── cloud-init.yml       # Configuration au premier boot (utilisateur, SSH, hostname)
├── network-config.yml   # Configuration réseau statique des VMs
└── README.md            # Ce fichier
```

## Prérequis

- KVM et libvirt installés et actifs (`systemctl is-active libvirtd`)
- Terraform installé (`terraform version`)
- Le provider `dmacvicar/libvirt` (téléchargé automatiquement au `terraform init`)
- Une clé SSH générée sur le serveur (`ssh-keygen` si besoin) et renseignée dans `cloud-init.yml`

## Utilisation

```bash
# Initialiser Terraform (télécharge le provider libvirt)
terraform init

# Prévisualiser les changements
terraform plan

# Créer toutes les VMs
terraform apply

# Voir les IPs attribuées
terraform output vm_ips

# Détruire toute l'infrastructure
terraform destroy
```

## Cycle de vie

```
terraform apply
       │
       ▼
Création des volumes disque (clone de l'image Ubuntu)
       │
       ▼
Génération des disques cloud-init (user + réseau)
       │
       ▼
Démarrage des VMs
       │
       ▼
Cloud-init s'exécute au premier boot :
  → Configure le hostname
  → Crée l'utilisateur + clé SSH
  → Attribue l'IP fixe
       │
       ▼
VMs prêtes pour Ansible
```

## Configuration post-déploiement

La configuration logicielle (Docker, Kubernetes, Jenkins, MongoDB, etc.) est gérée par Ansible dans un répertoire séparé. Terraform ne gère que le provisionnement des VMs.

## Notes

- L'image Ubuntu 24.04 cloud est téléchargée une seule fois puis clonée pour chaque VM.
- Les adresses MAC sont fixées manuellement pour garantir l'attribution des IPs via DHCP.
- Le domaine interne `lab.local` permet la résolution DNS entre VMs (ex : `ping k8s-master.lab.local`).
- Le réseau NAT implique que les VMs sont accessibles depuis le serveur hôte mais pas directement depuis le réseau local. Un port forwarding sera configuré ultérieurement pour exposer les services.