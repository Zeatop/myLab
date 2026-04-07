#!/bin/bash

set -euo pipefail

# =============================================================================
# test_vms.sh - Configuration sécurité + démarrage + vérification des VMs
# Usage: sudo ./test_vms.sh
# =============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

VMS=("ci-cd" "k8s-master" "k8s-worker-1" "k8s-worker-2" "bdd" "elk")

# --- Vérifications préalables ---
[[ $EUID -ne 0 ]] && error "Ce script doit être lancé avec sudo"

# =============================================================================
# Étape 1 : Configuration de QEMU (qemu.conf)
# - user/group = root : QEMU tourne en root pour accéder aux fichiers disque
# - security_driver = none : désactive AppArmor par VM (couche 3)
# =============================================================================
log "Configuration de QEMU..."

QEMU_CONF="/etc/libvirt/qemu.conf"

# Passer QEMU en root (corrige la couche 1 : permissions Unix)
sed -i 's/^#user = "libvirt-qemu"/user = "root"/' "$QEMU_CONF"
sed -i 's/^#group = "kvm"/group = "root"/' "$QEMU_CONF"

# Désactiver le security_driver AppArmor par VM (corrige la couche 3)
if grep -q '^security_driver' "$QEMU_CONF"; then
  sed -i 's/^security_driver.*/security_driver = "none"/' "$QEMU_CONF"
else
  echo 'security_driver = "none"' >> "$QEMU_CONF"
fi

# Vérification
echo "  Configuration appliquée :"
grep -E "^user|^group|^security_driver" "$QEMU_CONF" | sed 's/^/    /'

# =============================================================================
# Étape 2 : AppArmor en mode complain pour libvirtd (couche 2)
# =============================================================================
log "Configuration AppArmor..."

if command -v aa-complain &> /dev/null; then
  aa-complain /usr/sbin/libvirtd 2>/dev/null || true
  aa-complain /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper 2>/dev/null || true
  log "AppArmor libvirt en mode complain"
else
  warn "apparmor-utils non installé, installation..."
  apt install -y apparmor-utils
  aa-complain /usr/sbin/libvirtd 2>/dev/null || true
  aa-complain /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper 2>/dev/null || true
  log "AppArmor libvirt en mode complain"
fi

# =============================================================================
# Étape 3 : Redémarrage de libvirtd
# =============================================================================
log "Redémarrage de libvirtd..."
systemctl restart libvirtd
sleep 2
log "libvirtd redémarré (status: $(systemctl is-active libvirtd))"

# =============================================================================
# Étape 4 : Démarrage des VMs
# =============================================================================
log "Démarrage des VMs..."
STARTED=0
FAILED=0

for vm in "${VMS[@]}"; do
  if virsh start "$vm" 2>/dev/null; then
    log "$vm démarré"
    ((STARTED++))
  else
    echo -e "${RED}[ERREUR]${NC} $vm n'a pas pu démarrer"
    ((FAILED++))
  fi
done

echo ""
echo "========================================="
echo " Résultat : $STARTED démarrées, $FAILED en erreur"
echo "========================================="

[[ $FAILED -gt 0 ]] && error "Certaines VMs n'ont pas démarré"

# =============================================================================
# Étape 5 : Attente de cloud-init + vérification des IPs
# =============================================================================
log "Attente de 30s pour cloud-init..."
sleep 30

log "Vérification des IPs..."
echo ""
for vm in "${VMS[@]}"; do
  echo -n "  $vm: "
  IP=$(virsh domifaddr "$vm" 2>/dev/null | grep -oP '192\.168\.122\.\d+' || echo "pas d'IP")
  echo "$IP"
done

# =============================================================================
# Étape 6 : Test de connectivité SSH
# =============================================================================
echo ""
log "Test SSH sur ci-cd (192.168.122.10)..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no zeatop@192.168.122.10 "echo 'SSH OK'" 2>/dev/null; then
  log "Connexion SSH réussie !"
else
  warn "SSH pas encore prêt. Réessaie dans quelques instants : ssh zeatop@192.168.122.10"
fi