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
QEMU_CONF="/etc/libvirt/qemu.conf"

# --- Vérifications préalables ---
[[ $EUID -ne 0 ]] && error "Ce script doit être lancé avec sudo"

# =============================================================================
# Étape 1 : Configuration de QEMU (qemu.conf)
#
# Couche 1 - Permissions Unix :
#   QEMU tourne par défaut en libvirt-qemu:kvm, mais Terraform crée les
#   fichiers disque en root:root. On passe QEMU en root pour résoudre ça.
#
# Couche 3 - AppArmor par VM :
#   libvirt génère dynamiquement un profil AppArmor par VM via virt-aa-helper.
#   security_driver = "none" désactive ce mécanisme.
# =============================================================================
log "Configuration de QEMU..."

# user = root
if grep -q '^user = "root"' "$QEMU_CONF"; then
  log "user = root déjà configuré"
else
  sed -i 's/^#user = "libvirt-qemu"/user = "root"/' "$QEMU_CONF"
  sed -i 's/^user = .*/user = "root"/' "$QEMU_CONF"
  grep -q '^user = "root"' "$QEMU_CONF" || echo 'user = "root"' >> "$QEMU_CONF"
fi

# group = root
if grep -q '^group = "root"' "$QEMU_CONF"; then
  log "group = root déjà configuré"
else
  sed -i 's/^#group = "kvm"/group = "root"/' "$QEMU_CONF"
  sed -i 's/^group = .*/group = "root"/' "$QEMU_CONF"
  grep -q '^group = "root"' "$QEMU_CONF" || echo 'group = "root"' >> "$QEMU_CONF"
fi

# security_driver = none
if grep -q '^security_driver = "none"' "$QEMU_CONF"; then
  log "security_driver = none déjà configuré"
else
  sed -i '/^security_driver/d' "$QEMU_CONF"
  echo 'security_driver = "none"' >> "$QEMU_CONF"
fi

echo "  Configuration appliquée :"
grep -E "^user|^group|^security_driver" "$QEMU_CONF" | sed 's/^/    /'

# =============================================================================
# Étape 2 : AppArmor en mode complain pour libvirtd (couche 2)
#
# Le profil /etc/apparmor.d/usr.sbin.libvirtd restreint ce que le daemon
# libvirt peut faire. Le mode complain logue au lieu de bloquer.
# =============================================================================
log "Configuration AppArmor..."

if ! command -v aa-complain &> /dev/null; then
  warn "Installation de apparmor-utils..."
  apt install -y apparmor-utils > /dev/null 2>&1
fi

aa-complain /usr/sbin/libvirtd 2>/dev/null || true
aa-complain /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper 2>/dev/null || true
log "AppArmor libvirt en mode complain"

# =============================================================================
# Étape 3 : Arrêt complet et redémarrage de libvirtd
#
# Un simple restart ne suffit pas car les sockets maintiennent le daemon
# en vie avec l'ancienne configuration. Il faut tout stopper.
# =============================================================================
log "Redémarrage complet de libvirtd..."

systemctl stop libvirtd.service libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket 2>/dev/null || true
sleep 1
systemctl start libvirtd
sleep 2

log "libvirtd redémarré (status: $(systemctl is-active libvirtd))"

# =============================================================================
# Étape 4 : Démarrage des VMs
#
# Note : on utilise STARTED=$((STARTED + 1)) au lieu de ((STARTED++))
# car ((STARTED++)) retourne un code 1 quand STARTED vaut 0,
# ce qui fait planter le script avec set -e.
# =============================================================================
log "Démarrage des VMs..."
STARTED=0
FAILED=0

for vm in "${VMS[@]}"; do
  STATE=$(virsh domstate "$vm" 2>/dev/null || echo "unknown")
  if [[ "$STATE" == "running" ]]; then
    log "$vm déjà en cours d'exécution"
    STARTED=$((STARTED + 1))
    continue
  fi

  if virsh start "$vm" 2>/dev/null; then
    log "$vm démarré"
    STARTED=$((STARTED + 1))
  else
    echo -e "${RED}[ERREUR]${NC} $vm n'a pas pu démarrer"
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
# Étape 5 : Attente de cloud-init + vérification des IPs
# =============================================================================
log "Attente de 60s pour cloud-init..."
sleep 60

log "Vérification des baux DHCP..."
echo ""
virsh net-dhcp-leases vm-network

echo ""
log "Vérification des IPs par VM..."
echo ""
for vm in "${VMS[@]}"; do
  IP=$(virsh domifaddr "$vm" 2>/dev/null | grep -oP '192\.168\.122\.\d+' || echo "pas d'IP")
  printf "  %-15s %s\n" "$vm:" "$IP"
done

# =============================================================================
# Étape 6 : Test de connectivité SSH
# =============================================================================
echo ""
log "Test SSH sur ci-cd (192.168.122.10)..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no zeatop@192.168.122.10 "echo 'SSH OK'" 2>/dev/null; then
  log "Connexion SSH réussie !"
else
  warn "SSH pas encore prêt. Réessaie dans quelques instants :"
  echo "  ssh zeatop@192.168.122.10"
fi