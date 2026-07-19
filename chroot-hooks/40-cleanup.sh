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
echo "[1/5] APT cleanup..."
apt-get autoremove -y --purge 2>/dev/null || true
apt-get clean 2>/dev/null || true
apt-get autoclean 2>/dev/null || true
rm -rf /var/lib/apt/lists/* 2>/dev/null || true
rm -rf /tmp/*.zip /tmp/*.tar.gz /tmp/WhiteSur* /tmp/Dracula* \
       /tmp/papirus* /tmp/catppuccin* 2>/dev/null || true

# =============================================================================
# 2. SERVICES PERFORMANCE (Garuda active tout ça)
# =============================================================================
echo "[2/5] Services performance..."

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
echo "[3/5] TRIM SSD..."
systemctl enable fstrim.timer 2>/dev/null || true

# =============================================================================
# 4. SYSCTL + BBR
# =============================================================================
echo "[4/5] BBR + sysctl..."
# Charger BBR au boot
echo 'net.core.default_qdisc=fq' >> /etc/sysctl.d/99-sharkos-performance.conf 2>/dev/null || true
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.d/99-sharkos-performance.conf 2>/dev/null || true

# Module BBR
echo 'tcp_bbr' >> /etc/modules 2>/dev/null || true

# =============================================================================
# 5. RÉSUMÉ + MOTD
# =============================================================================
echo "[5/5] MOTD SharkOS..."
cat > /etc/motd << 'MOTD'

  ███████╗██╗  ██╗ █████╗ ██████╗ ██╗  ██╗ ██████╗ ███████╗
  ██╔════╝██║  ██║██╔══██╗██╔══██╗██║ ██╔╝██╔═══██╗██╔════╝
  ███████╗███████║███████║██████╔╝█████╔╝ ██║   ██║███████╗
  ╚════██║██╔══██║██╔══██║██╔══██╗██╔═██╗ ██║   ██║╚════██║
  ███████║██║  ██║██║  ██║██║  ██║██║  ██╗╚██████╔╝███████║
  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝

  🦈 SharkOS 2.0 — Dragon Edition
  ⚡ Kernel  : Liquorix (gaming/performance)
  💾 Memory  : Zram zstd 50% RAM
  🎮 Gaming  : Lutris + Wine + GameMode + MangoHud
  🛡️  Security: Nmap, Wireshark, Aircrack, Hashcat, Hydra...
  🎨 Theme   : Dracula + Papirus-Dark + Powerlevel10k

  Login : shark / shark

MOTD

# Désactiver les journaux d'erreurs inutiles
mkdir -p /etc/rsyslog.d
cat > /etc/rsyslog.d/99-sharkos.conf << 'EOF'
# SharkOS — réduire le bruit
:msg, contains, "kernel: usb" stop
:msg, contains, "kernel: NET" stop
EOF

# Journald : limiter la taille
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/sharkos.conf << 'EOF'
[Journal]
SystemMaxUse=256M
RuntimeMaxUse=64M
Compress=yes
EOF

echo ""
echo "✅ [HOOK 40] Nettoyage terminé — SharkOS Dragon Edition prêt."
echo ""
