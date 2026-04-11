#!/bin/bash

set -euo pipefail

# =============================================================================
# setup_lan_bridge.sh - Création du bridge LAN (vmbr1) pour OPNsense
# Usage: ./setup_lan_bridge.sh
# =============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

# --- Vérifications préalables ---
[[ $EUID -ne 0 ]] && error "Ce script doit être lancé en root"

# --- Vérifier si vmbr1 existe déjà ---
if ip link show vmbr1 &>/dev/null; then
  log "Le bridge vmbr1 existe déjà"
  ip addr show vmbr1 | grep "inet "
  exit 0
fi

# --- Ajouter le bridge vmbr1 dans la config réseau ---
log "Ajout du bridge vmbr1 (LAN 10.0.0.0/24)..."

cat >> /etc/network/interfaces << 'EOF'

# =============================================================================
# vmbr1 - Bridge LAN interne pour les VMs (derrière OPNsense)
#
# Ce bridge crée un réseau privé isolé du réseau domestique.
# OPNsense fait le routage entre vmbr0 (WAN) et vmbr1 (LAN).
# Les VMs sur ce réseau utilisent des IPs en 10.0.0.x
# =============================================================================
auto vmbr1
iface vmbr1 inet static
    address 10.0.0.254
    netmask 255.255.255.0
    bridge-ports none
    bridge-stp off
    bridge-fd 0
EOF

# --- Activer le bridge ---
log "Activation du bridge..."
ifreload -a

# --- Vérification ---
if ip link show vmbr1 &>/dev/null; then
  echo ""
  echo "========================================="
  echo " Bridge vmbr1 créé avec succès"
  echo "========================================="
  echo ""
  ip addr show vmbr1 | grep "inet "
  echo ""
  log "Prochaine étape : configurer OPNsense avec WAN (vmbr0) et LAN (vmbr1)"
else
  error "Le bridge vmbr1 n'a pas été créé"
fi