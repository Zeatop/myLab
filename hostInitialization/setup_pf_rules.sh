#!/bin/sh

# =============================================================================
# setup_pf_rules.sh - Configuration des règles NAT/Firewall sur OPNsense
# Usage: ssh root@192.168.1.159 < setup_pf_rules.sh
# =============================================================================

CONF="/usr/local/etc/pf.custom.conf"
HOOK="/usr/local/etc/rc.syshook.d/start/99-custom-pf.sh"

echo "[*] Création des règles NAT/Firewall..."

# --- Création du fichier de règles ---
cat > $CONF << 'EOF'
# =============================================================================
# Règles NAT personnalisées pour le homelab
# Redirige les ports WAN vers les VMs du LAN (10.0.0.x)
# =============================================================================

# --- Port forwarding (WAN → LAN) ---
# Jenkins
rdr on vtnet0 proto tcp from any to (vtnet0) port 8080 -> 10.0.0.10 port 8080
# SonarQube
rdr on vtnet0 proto tcp from any to (vtnet0) port 9000 -> 10.0.0.10 port 9000
# Grafana
rdr on vtnet0 proto tcp from any to (vtnet0) port 3000 -> 10.0.0.40 port 3000
# Kibana
rdr on vtnet0 proto tcp from any to (vtnet0) port 5601 -> 10.0.0.40 port 5601
# Prometheus
rdr on vtnet0 proto tcp from any to (vtnet0) port 9090 -> 10.0.0.40 port 9090

# --- NAT sortant (LAN → Internet) ---
nat on vtnet0 from vtnet1:network to any -> (vtnet0)

# --- Firewall : tout autoriser ---
pass all
EOF

echo "[*] Règles écrites dans $CONF"
cat $CONF

# --- Chargement des règles ---
echo "[*] Chargement des règles..."
pfctl -e 2>/dev/null
pfctl -f $CONF

if [ $? -eq 0 ]; then
    echo "[OK] Règles chargées avec succès"
else
    echo "[ERREUR] Échec du chargement des règles"
    exit 1
fi

# --- Vérification ---
echo ""
echo "[*] Règles NAT actives :"
pfctl -s nat | grep rdr
echo ""
echo "[*] Règles Firewall actives :"
pfctl -s rules

# --- Script de démarrage automatique ---
echo ""
echo "[*] Création du script de démarrage..."
mkdir -p /usr/local/etc/rc.syshook.d/start

cat > $HOOK << 'BOOTEOF'
#!/bin/sh
# Charge les règles pf custom après le boot
sleep 15
pfctl -f /usr/local/etc/pf.custom.conf
logger "Custom pf rules loaded from /usr/local/etc/pf.custom.conf"
BOOTEOF

chmod +x $HOOK
echo "[OK] Script de démarrage créé : $HOOK"

echo ""
echo "========================================="
echo " Configuration terminée"
echo "========================================="
echo ""
echo " Services accessibles depuis le réseau :"
echo "   Jenkins    : http://192.168.1.159:8080"
echo "   SonarQube  : http://192.168.1.159:9000"
echo "   Grafana    : http://192.168.1.159:3000"
echo "   Kibana     : http://192.168.1.159:5601"
echo "   Prometheus : http://192.168.1.159:9090"
echo "========================================="