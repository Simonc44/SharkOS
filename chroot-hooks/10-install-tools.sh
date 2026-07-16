#!/usr/bin/env bash
# =============================================================================
# SharkOS — 10-install-tools.sh (CHROOT HOOK — v3)
# Objectif : ISO légère (~1.8 GB) combinant Kali Linux + design Apple + ergonomie Windows
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 10] Installation des outils SharkOS..."
echo ""

# =============================================================================
# 1. MISE À JOUR DE BASE
# =============================================================================
echo "[1/12] Mise à jour des listes APT..."
apt-get update -qq
apt-get install -y --no-install-recommends \
  curl wget git unzip zip ca-certificates \
  lsb-release software-properties-common \
  apt-transport-https gnupg2

# =============================================================================
# 2. ZSH + OH MY ZSH
# =============================================================================
echo "[2/12] Installation de ZSH..."
apt-get install -y --no-install-recommends \
  zsh \
  zsh-syntax-highlighting \
  zsh-autosuggestions \
  fonts-powerline \
  fonts-font-awesome

# Créer l'utilisateur shark AVANT de lui assigner un shell
if ! id "shark" &>/dev/null; then
  useradd -m -s "$(command -v zsh)" -G sudo,audio,video,plugdev,netdev shark 2>/dev/null || \
  useradd -m -s "$(command -v zsh)" shark 2>/dev/null || true
fi

echo "shark:shark" | chpasswd 2>/dev/null || true
echo "root:shark" | chpasswd 2>/dev/null || true

export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes

for TARGET_USER in root shark; do
  if [[ "$TARGET_USER" == "root" ]]; then
    HOME_DIR="/root"
  else
    HOME_DIR="/home/$TARGET_USER"
  fi

  mkdir -p "$HOME_DIR"

  if [[ ! -d "$HOME_DIR/.oh-my-zsh" ]]; then
    echo "   → Oh My Zsh pour $TARGET_USER..."
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git \
      "$HOME_DIR/.oh-my-zsh" 2>/dev/null || true
  fi

  if [[ -d "$HOME_DIR/.oh-my-zsh" ]]; then
    ZSH_CUSTOM="$HOME_DIR/.oh-my-zsh/custom"
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
      git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true
    fi
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
      git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true
    fi
  fi

  if [[ -f "/etc/skel/.zshrc" ]]; then
    cp "/etc/skel/.zshrc" "$HOME_DIR/.zshrc"
  fi

  chown -R "$TARGET_USER:$TARGET_USER" "$HOME_DIR" 2>/dev/null || true
done

ZSH_PATH="$(command -v zsh)"
chsh -s "$ZSH_PATH" root 2>/dev/null || true
chsh -s "$ZSH_PATH" shark 2>/dev/null || true

# =============================================================================
# 3. OUTILS SÉCURITÉ ESSENTIELS (réseau + base)
# =============================================================================
echo "[3/12] Outils réseau et sécurité de base..."
apt-get install -y --no-install-recommends \
  nmap \
  masscan \
  wireshark \
  tcpdump \
  ufw \
  gufw \
  net-tools \
  iputils-ping \
  traceroute \
  dnsutils \
  dnsrecon \
  dnsenum \
  whois \
  netcat-openbsd \
  ncat \
  socat \
  hping3 \
  arp-scan \
  netdiscover \
  ngrep \
  mitmproxy \
  bettercap \
  ettercap-text-only \
  macchanger \
  arpwatch \
  whatweb

# Wireshark sans root pour le groupe shark
echo "wireshark-common wireshark-common/install-setuid boolean true" \
  | debconf-set-selections
dpkg-reconfigure -f noninteractive wireshark-common 2>/dev/null || true
usermod -aG wireshark shark 2>/dev/null || true

# =============================================================================
# 4. OUTILS KALI — RECONNAISSANCE & OSINT
# =============================================================================
echo "[4/12] Outils OSINT et reconnaissance..."
apt-get install -y --no-install-recommends \
  theharvester \
  recon-ng \
  exiftool \
  maltego 2>/dev/null || true   # GUI, peut échouer sur certains dépôts

# =============================================================================
# 5. OUTILS KALI — WEB
# =============================================================================
echo "[5/12] Outils d'audit web..."
apt-get install -y --no-install-recommends \
  sqlmap \
  nikto \
  gobuster \
  dirb \
  wfuzz \
  curl \
  httpie \
  wordlists 2>/dev/null || true

# =============================================================================
# 6. OUTILS KALI — EXPLOITATION
# =============================================================================
echo "[6/12] Metasploit + ExploitDB..."

# Ajouter le dépôt Metasploit officiel
if ! dpkg -l metasploit-framework &>/dev/null 2>&1; then
  curl --silent --location \
    https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb \
    > /tmp/msfinstall 2>/dev/null || true
  if [[ -f /tmp/msfinstall ]]; then
    chmod 755 /tmp/msfinstall
    /tmp/msfinstall 2>/dev/null || true
  fi
  rm -f /tmp/msfinstall
fi

# ExploitDB (searchsploit) — via apt
apt-get install -y --no-install-recommends exploitdb 2>/dev/null || \
  pip3 install searchsploit 2>/dev/null || true

# =============================================================================
# 7. OUTILS KALI — MOTS DE PASSE
# =============================================================================
echo "[7/12] Outils de cracking de mots de passe..."
apt-get install -y --no-install-recommends \
  hydra \
  hydra-gtk \
  john \
  hashcat \
  crunch \
  cewl \
  medusa \
  hashid \
  ophcrack 2>/dev/null || true

# =============================================================================
# 8. OUTILS KALI — WI-FI
# =============================================================================
echo "[8/12] Suite Wi-Fi (aircrack-ng, wifite, reaver)..."
apt-get install -y --no-install-recommends \
  aircrack-ng \
  wifite \
  reaver \
  pixiewps \
  cowpatty 2>/dev/null || true

# =============================================================================
# 9. OUTILS KALI — FORENSICS & REVERSE
# =============================================================================
echo "[9/12] Forensics, reverse engineering..."
apt-get install -y --no-install-recommends \
  binwalk \
  foremost \
  scalpel \
  volatility3 \
  bulk-extractor \
  dc3dd \
  gdb \
  radare2 \
  ltrace \
  strace \
  binutils \
  hexdump \
  file \
  xxd \
  rkhunter \
  fail2ban 2>/dev/null || true

# =============================================================================
# 10. MACCHANGER — Rotation MAC automatique
# =============================================================================
echo "[10/12] Macchanger — rotation MAC automatique..."

cat > /usr/local/bin/sharkos-mac-randomize << 'MACSCRIPT'
#!/usr/bin/env bash
echo "🦈 SharkOS : Randomisation des adresses MAC..."
for IFACE in $(ip link show | awk -F': ' '/^[0-9]+: (wl|en|eth)/{print $2}' | tr -d '@' | cut -d'@' -f1); do
  ip link set "$IFACE" down 2>/dev/null || continue
  macchanger -r "$IFACE" 2>/dev/null && echo "  ✓ $IFACE → nouvelle MAC" || true
  ip link set "$IFACE" up 2>/dev/null || true
done
echo "🦈 Randomisation MAC terminée."
MACSCRIPT
chmod +x /usr/local/bin/sharkos-mac-randomize

cat > /etc/systemd/system/sharkos-mac-randomize.service << 'EOF'
[Unit]
Description=SharkOS — Randomisation MAC au démarrage
DefaultDependencies=no
Before=network.target
After=udev.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/sharkos-mac-randomize
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /etc/NetworkManager/dispatcher.d/
cat > /etc/NetworkManager/dispatcher.d/99-sharkos-mac << 'NMHOOK'
#!/usr/bin/env bash
IFACE="$1"
EVENT="$2"
if [[ "$EVENT" == "up" ]] && [[ "$IFACE" == wl* ]]; then
  /usr/local/bin/sharkos-mac-randomize &>/dev/null &
fi
NMHOOK
chmod +x /etc/NetworkManager/dispatcher.d/99-sharkos-mac
systemctl enable sharkos-mac-randomize.service 2>/dev/null || true

# =============================================================================
# 11. ANONYMAT — Tor + Proxychains
# =============================================================================
echo "[11/12] Tor + Proxychains..."
apt-get install -y --no-install-recommends \
  tor \
  proxychains4 2>/dev/null || true

# Configuration proxychains pour utiliser Tor par défaut
if [[ -f /etc/proxychains4.conf ]]; then
  sed -i 's/^socks4.*/socks5 127.0.0.1 9050/' /etc/proxychains4.conf 2>/dev/null || true
fi

# =============================================================================
# 12. SNAP + CLAMAV + WINE + FLATPAK + UTILITAIRES
# =============================================================================
echo "[12/12] Snap, ClamAV, Wine, Flatpak, utilitaires..."

# Snap
apt-get install -y --no-install-recommends snapd squashfuse fuse3
ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true
systemctl enable snapd.service 2>/dev/null || true
systemctl enable snapd.apparmor.service 2>/dev/null || true

cat > /usr/local/bin/sharkos-snap-setup << 'SNAPSETUP'
#!/usr/bin/env bash
echo "🦈 Apps Snap disponibles :"
echo "  sudo snap install discord"
echo "  sudo snap install spotify"
echo "  sudo snap install code --classic"
echo "  sudo snap install vlc"
echo "  sudo snap install burpsuite-community-edition"
echo "  sudo snap install zaproxy"
echo "  sudo snap install maltego"
SNAPSETUP
chmod +x /usr/local/bin/sharkos-snap-setup

# ClamAV
apt-get install -y --no-install-recommends clamav clamav-daemon clamav-freshclam clamtk
freshclam --quiet 2>/dev/null || echo "   ⚠️  ClamAV : mise à jour au premier boot"
systemctl enable clamav-freshclam.service 2>/dev/null || true

# Wine + Lutris + Proton-GE
dpkg --add-architecture i386
apt-get update -qq
apt-get install -y --no-install-recommends \
  wine wine32 wine64 winetricks cabextract zenity

if apt-cache show lutris &>/dev/null; then
  apt-get install -y --no-install-recommends lutris 2>/dev/null || true
fi
apt-get install -y --no-install-recommends steam-installer 2>/dev/null || \
  echo "   ⚠️  steam-installer absent — sudo snap install steam"

cat > /usr/local/bin/sharkrun << 'SHARKRUN'
#!/usr/bin/env bash
if [[ -z "${1:-}" ]]; then
  echo "Usage: sharkrun <fichier.exe> [arguments...]"
  exit 1
fi
EXE="$1"; shift
echo "🦈 Lancement de $EXE via Wine..."
WINEPREFIX="${WINEPREFIX:-$HOME/.wine-sharkos}" wine "$EXE" "$@"
SHARKRUN
chmod +x /usr/local/bin/sharkrun

# Proton-GE
GE_DIR="/etc/skel/.steam/root/compatibilitytools.d"
mkdir -p "$GE_DIR"
GE_URL=$(curl --connect-timeout 8 --max-time 15 -s \
  https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest \
  | grep "browser_download_url.*GE-Proton.*\.tar\.gz" | head -n 1 \
  | cut -d : -f 2,3 | tr -d ' "') || true
[[ -z "${GE_URL:-}" ]] && \
  GE_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-10/GE-Proton9-10.tar.gz"
if wget --connect-timeout=8 --timeout=15 -q "$GE_URL" -O /tmp/proton-ge.tar.gz; then
  tar -xzf /tmp/proton-ge.tar.gz -C "$GE_DIR/"
  rm -f /tmp/proton-ge.tar.gz
  echo "   ✓ Proton-GE installé"
else
  echo "   ⚠️  Proton-GE : réseau indisponible, installer plus tard"
fi

# Flatpak
apt-get install -y --no-install-recommends flatpak xdg-desktop-portal-gtk
flatpak remote-add --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# Utilitaires système
apt-get install -y --no-install-recommends \
  neofetch htop inxi dconf-cli gdebi-core imagemagick

# Xubuntu default settings
if [[ ! -d "/tmp/xubuntu-default-settings" ]]; then
  git clone --depth=1 \
    https://github.com/Xubuntu/xubuntu-default-settings.git \
    /tmp/xubuntu-default-settings 2>/dev/null || true
fi
if [[ -d "/tmp/xubuntu-default-settings" ]]; then
  [[ -d "/tmp/xubuntu-default-settings/etc/xdg" ]] && \
    cp -r /tmp/xubuntu-default-settings/etc/xdg/* /etc/xdg/ 2>/dev/null || true
  [[ -d "/tmp/xubuntu-default-settings/usr/share" ]] && \
    cp -r /tmp/xubuntu-default-settings/usr/share/* /usr/share/ 2>/dev/null || true
fi

# Neofetch config SharkOS
mkdir -p /etc/sharkos /etc/skel/.config/neofetch
cat > /etc/sharkos/neofetch.conf << 'NEOFETCH'
print_info() {
    info "🦈 SharkOS" distro
    info "Kernel" kernel
    info "Uptime" uptime
    info "Shell" shell
    info "Desktop" de
    info "Theme" theme
    info "Icons" icons
    info "Terminal" term
    info "CPU" cpu
    info "RAM" memory
    info "Disk" disk
    prin ""
    prin "🦈 Rapide. Furtif. Létal."
}
ascii_distro="Debian"
colors=(4 4 4 4 4 4)
bold="on"
NEOFETCH
cp /etc/sharkos/neofetch.conf /etc/skel/.config/neofetch/config.conf

echo ""
echo "✅ [HOOK 10] Installation terminée — outils Kali + design Apple + Wine Windows OK."
echo ""
