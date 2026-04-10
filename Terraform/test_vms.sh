#!/bin/bash

set -euo pipefail

# =============================================================================
# test_vms.sh - Démarrage + vérification des VMs sur Proxmox
# Usage: sudo ./test_vms.sh
# =============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

# VMIDs Proxmox (correspondant à variables.tf)
declare -A VMS=(
  ["ci-cd"]=110
  ["k8s-master"]=120
  ["k8s-worker-1"]=121
  ["k8s-worker-2"]=122
  ["bdd"]=130
  ["elk"]=140
)

# IPs attendues
declare -A IPS=(
  ["ci-cd"]="192.168.1.10"
  ["k8s-master"]="192.168.1.20"
  ["k8s-worker-1"]="192.168.1.21"
  ["k8s-worker-2"]="192.168.1.22"
  ["bdd"]="192.168.1.30"
  ["elk"]="192.168.1.40"
)

# --- Vérifications préalables ---
[[ $EUID -ne 0 ]] && error "Ce script doit être lancé avec sudo"

# =============================================================================
# Étape 1 : Démarrage des VMs
#
# Proxmox gère les permissions, pas besoin de configurer QEMU ou AppArmor
# =============================================================================
log "Démarrage des VMs..."
STARTED=0
FAILED=0

for vm in "${!VMS[@]}"; do
  VMID=${VMS[$vm]}
  STATUS=$(qm status $VMID 2>/dev/null | awk '{print $2}' || echo "unknown")

  if [[ "$STATUS" == "running" ]]; then
    log "$vm (VMID $VMID) déjà en cours d'exécution"
    STARTED=$((STARTED + 1))
    continue
  fi

  if qm start $VMID 2>/dev/null; then
    log "$vm (VMID $VMID) démarré"
    STARTED=$((STARTED + 1))
  else
    echo -e "${RED}[ERREUR]${NC} $vm (VMID $VMID) n'a pas pu démarrer"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "========================================="
echo " Résultat : $STARTED démarrées, $FAILED en erreur"
echo "========================================="

if [[ $FAILED -gt 0 ]]; then
  warn "Certaines VMs n'ont pas démarré, vérifiez les logs"
fi

# =============================================================================
# Étape 2 : Attente de cloud-init + vérification des IPs
# =============================================================================
log "Attente de 60s pour cloud-init..."
sleep 60

log "Vérification des IPs..."
echo ""
for vm in "${!VMS[@]}"; do
  VMID=${VMS[$vm]}
  EXPECTED_IP=${IPS[$vm]}

  # Récupérer l'IP via QEMU guest agent
  ACTUAL_IP=$(qm guest cmd $VMID network-get-interfaces 2>/dev/null | \
    grep -oP '"ip-address"\s*:\s*"\K192\.168\.1\.\d+' | head -1 || echo "pas d'IP")

  if [[ "$ACTUAL_IP" == "$EXPECTED_IP" ]]; then
    printf "  ${GREEN}%-15s %s${NC}\n" "$vm:" "$ACTUAL_IP"
  else
    printf "  ${YELLOW}%-15s %s (attendu: %s)${NC}\n" "$vm:" "$ACTUAL_IP" "$EXPECTED_IP"
  fi
done

# =============================================================================
# Étape 3 : Test de connectivité SSH
# =============================================================================
echo ""
log "Test SSH sur ci-cd (192.168.1.10)..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no zeatop@192.168.1.10 "echo 'SSH OK'" 2>/dev/null; then
  log "Connexion SSH réussie !"
else
  warn "SSH pas encore prêt. Réessaie dans quelques instants :"
  echo "  ssh zeatop@192.168.1.10"
fi
