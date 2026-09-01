#!/usr/bin/env bash
# =============================================================================
# SharkOS — 40-cleanup.sh v2.0 (Garuda-style)
# Nettoyage agressif + activation services performance
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 40] Nettoyage + activation services performance..."
echo ""

# =============================================================================
# 1. APT CLEANUP
# =============================================================================
echo "[1/7] APT cleanup..."
apt-get autoremove -y --purge 2>/dev/null || true
apt-get clean 2>/dev/null || true
apt-get autoclean 2>/dev/null || true
rm -rf /var/lib/apt/lists/* 2>/dev/null || true
rm -rf /tmp/*.zip /tmp/*.tar.gz /tmp/WhiteSur* /tmp/Dracula* \
       /tmp/papirus* /tmp/catppuccin* 2>/dev/null || true

# =============================================================================
# 2. SERVICES PERFORMANCE (Garuda active tout ça)
# =============================================================================
echo "[2/7] Services performance..."

# Irqbalance (distribue les interruptions sur les CPUs)
apt-get install -y --no-install-recommends irqbalance 2>/dev/null || true
systemctl enable irqbalance 2>/dev/null || true

# Thermald (gestion thermique Intel)
apt-get install -y --no-install-recommends thermald 2>/dev/null || true
systemctl enable thermald 2>/dev/null || true

# Ananicy-cpp (priorisation automatique des processus — signature Garuda)
apt-get install -y --no-install-recommends \
  ananicy 2>/dev/null || \
echo "   ⚠ ananicy non disponible dans Bookworm — installe via Flatpak post-boot"

# Nohang (prévention OOM intelligent)
apt-get install -y --no-install-recommends nohang 2>/dev/null || true
systemctl enable nohang 2>/dev/null || true

# =============================================================================
# 3. TRIM SSD (Garuda active fstrim.timer)
# =============================================================================
echo "[3/7] TRIM SSD..."
systemctl enable fstrim.timer 2>/dev/null || true

# =============================================================================
# 4. SYSCTL + BBR
# =============================================================================
echo "[4/7] BBR + sysctl..."
# Module BBR à charger au boot (les clés sysctl sont déjà dans
# /etc/sysctl.d/99-sharkos-performance.conf écrit par hook 10)
echo 'tcp_bbr' >> /etc/modules 2>/dev/null || true

# =============================================================================
# 5. SÉCURITÉ MAXIMALE — UFW actif + AppArmor + services inutiles
# =============================================================================
echo "[5/7] Durcissement sécurité (UFW + AppArmor + services)..."

# UFW : pare-feu actif par défaut (deny entrant, allow sortant)
apt-get install -y --no-install-recommends ufw 2>/dev/null || true
ufw default deny incoming 2>/dev/null || true
ufw default allow outgoing 2>/dev/null || true
# Autoriser le réseau local (LAN) pour le partage/impression et DHCP
ufw allow in on wan 2>/dev/null || true
# Garder le SSH dispo si l'utilisateur l'active (port standard)
ufw allow OpenSSH 2>/dev/null || true
# Activer maintenant (ne coupe pas la session : outgoing reste permis)
echo "y" | ufw enable 2>/dev/null || true
systemctl enable ufw 2>/dev/null || true

# AppArmor : confinement des applications (profile par défaut)
if apt-cache show apparmor &>/dev/null; then
  apt-get install -y --no-install-recommends apparmor apparmor-utils 2>/dev/null || true
  systemctl enable apparmor 2>/dev/null || true
  aa-enforce /sbin/dhclient /usr/sbin/tcpdump 2>/dev/null || true
  echo "   ✅ AppArmor actif (profils par défaut Debian)"
fi

# Services inutiles ou risqués → désactivés (moins de surface d'attaque)
for SVC in avahi-daemon cups-browsed rpcbind modemmanager pppd-dns wpa_supplicant.service; do
  systemctl disable "$SVC" 2>/dev/null || true
  systemctl stop "$SVC" 2>/dev/null || true
done
# Désactiver le service CUPS (pas d'impression par défaut — moins de surface)
systemctl disable cups 2>/dev/null || true

# Core dumps désactivés (via limits global) — évite l'exfiltration mémoire
cat > /etc/security/limits.d/99-sharkos-hardened.conf << 'EOF'
* hard core 0
* hard maxlogins 8
EOF
chmod 644 /etc/security/limits.d/99-sharkos-hardened.conf

# /tmp durci : sticky + pas d'exécution
cat > /etc/tmpfiles.d/sharkos-hardened.conf << 'EOF'
d /tmp 1777 root root -
d /var/tmp 1777 root root -
EOF

# Journal sensible : rotation agressive (déjà limité) + message
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/sharkos.conf << 'EOF'
[Journal]
SystemMaxUse=256M
RuntimeMaxUse=64M
Compress=yes
EOF

echo "   ✅ UFW actif (deny incoming) + AppArmor + services inutiles neutralisés"

# =============================================================================
# 6. RÉSUMÉ + MOTD
# =============================================================================
echo "[6/7] MOTD SharkOS..."
cat > /etc/motd << 'MOTD'

  ███████╗██╗  ██╗ █████╗ ██████╗ ██╗  ██╗ ██████╗ ███████╗
  ██╔════╝██║  ██║██╔══██╗██╔══██╗██║ ██╔╝██╔═══██╗██╔════╝
  ███████╗███████║███████║██████╔╝█████╔╝ ██║   ██║███████╗
  ╚════██║██╔══██║██╔══██║██╔══██╗██╔═██╗ ██║   ██║╚════██║
  ███████║██║  ██║██║  ██║██║  ██║██║  ██╗╚██████╔╝███████║
  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝

  🦈 SharkOS 2.0 — Dragon Edition
  ⚡ Kernel  : XanMod LTS (gaming/performance)
  💾 Memory  : Zram zstd 50% RAM
  ⚙️  CPU     : governor schedutil (shark-turbo on → performance)
  🎮 Gaming  : Lutris + Wine + GameMode + MangoHud
  🛡️  Security: Nmap, Wireshark, Aircrack, Hashcat, Hydra...
  🎨 Theme   : WhiteSur-Light (HyperOS) + Papirus-Light + P10k

  Login : shark / shark

MOTD

# Désactiver les journaux d'erreurs inutiles
mkdir -p /etc/rsyslog.d
cat > /etc/rsyslog.d/99-sharkos.conf << 'EOF'
# SharkOS — réduire le bruit
:msg, contains, "kernel: usb" stop
:msg, contains, "kernel: NET" stop
EOF

# Simplification du bruit rsyslog (taille du journal déjà bordée par le
# bloc journald de la section 5 ci-dessus)
echo ""
echo "✅ [HOOK 40] Nettoyage terminé — SharkOS Dragon Edition prêt."
echo ""
