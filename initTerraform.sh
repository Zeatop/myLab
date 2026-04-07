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

# --- Installation ---
log "Mise à jour des paquets..."
apt-get update
apt-get install -y gnupg software-properties-common

log 'Installation de la clé GPG de HashiCorp...'
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

log 'Vérification de la clé GPG...'
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

log 'Ajout du dépôt de HashiCorp...'
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

log 'Mise à jour des paquets après ajout du dépôt...'
apt-get update

log "Installation de Terraform depuis le nouveau dépôt..."
apt install -y terraform

# --- Vérification finale ---
echo ""
echo "========================================="
echo " Vérification de l'installation"
echo "========================================="
echo ""
 
if command -v terraform &> /dev/null; then
  echo "Terraform : $(terraform version | head -1)"
  log "Installation terminée avec succès !"
else
  error "Terraform n'a pas été installé correctement"
fi
