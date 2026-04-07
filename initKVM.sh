#!/bin/bash
set -euo pipefail

# =============================================================================
# install_kvm.sh - Installation et configuration de KVM/libvirt
# Usage: sudo ./install_kvm.sh
# =============================================================================

# Couleurs pour les logs
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

# --- Vérifications préalables ---
[[ $EUID -ne 0 ]] && error "Ce script doit être lancé avec sudo"

# Vérifier le support de la virtualisation
VIRT_SUPPORT=$(grep -cE "vmx|svm" /proc/cpuinfo || true)
[[ $VIRT_SUPPORT -eq 0 ]] && error "La virtualisation n'est pas supportée par ton CPU"
log "Virtualisation supportée ($VIRT_SUPPORT threads)"

# --- Installation ---
log "Mise à jour des paquets..."
apt update -y && apt upgrade -y

log "Installation de KVM et libvirt..."
apt install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  bridge-utils \
  virtinst \
  virt-manager

# --- Configuration utilisateur ---
REAL_USER="${SUDO_USER:-$USER}"
usermod -aG libvirt "$REAL_USER"
usermod -aG kvm "$REAL_USER"
log "Utilisateur '$REAL_USER' ajouté aux groupes libvirt et kvm"

# --- Activation du service ---
systemctl enable --now libvirtd
log "Service libvirtd activé et démarré"

# --- Vérification finale ---
echo ""
echo "========================================="
echo " Vérification de l'installation"
echo "========================================="
echo ""

echo "Service libvirtd : $(systemctl is-active libvirtd)"
echo "Version QEMU     : $(qemu-system-x86_64 --version | head -1)"
echo "VMs existantes    :"
virsh list --all
echo ""

log "Installation terminée !"
echo -e "${GREEN}[INFO]${NC} Déconnecte-toi et reconnecte-toi pour que les permissions prennent effet."
echo -e "${GREEN}[INFO]${NC} Ensuite vérifie avec : virsh list --all (sans sudo)"