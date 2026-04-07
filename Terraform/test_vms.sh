#!/bin/bash

set -euo pipefail

# Couleurs pour les logs
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

# --- Vérifications préalables ---
[[ $EUID -ne 0 ]] && error "Ce script doit être lancé avec sudo"

# --- Démarrage des VMs ---
log "Démarrage des VMs..."
for vm in ci-cd k8s-master k8s-worker-1 k8s-worker-2 bdd elk; do
  sudo virsh start $vm
done

# --- Vérifier que les VMs ont bien leurs IPs ---
log "Vérification des IPs des VMs..."dddd
for vm in ci-cd k8s-master k8s-worker-1 k8s-worker-2 bdd elk; do
  echo -n "$vm: "
  sudo virsh domifaddr $vm
done

# Tester la connexion SSH sur une VM
ssh zeatop@192.168.122.10