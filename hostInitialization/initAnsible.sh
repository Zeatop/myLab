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

# --- Installation de Ansible ---
log "Mise à jour des paquets..."
apt update

log "Installation des dépendances..."
apt install -y software-properties-common

log "Ajout du PPA d'Ansible..."
add-apt-repository --yes --update ppa:ansible/ansible

log "Installation d'Ansible..."
apt install -y ansible

# --- Vérification finale ---
echo ""
echo "========================================="
echo " Vérification de l'installation"
echo "========================================="
echo ""
 
if command -v ansible &> /dev/null; then
  echo "Ansible : $(ansible --version | head -1)"
  log "Installation terminée avec succès !"
else
  error "Ansible n'a pas été installé correctement"
fi