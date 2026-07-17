#!/usr/bin/env bash
# =============================================================================
# SharkOS — 10-install-tools.sh (CHROOT HOOK — v2 corrigé)
# FIXES :
#   - snap install retiré du chroot (impossble sans snapd démarré)
#   - steam-installer : fallback propre si absent du dépôt
#   - freshclam : timeout protégé + erreur non bloquante
#   - useradd : ordre corrigé (créer avant chsh)
#   - systemctl enable : toujours || true pour éviter crash en chroot
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 10] Installation des outils SharkOS..."
echo ""

# =============================================================================
# 1. MISE À JOUR DE BASE
# =============================================================================
echo "[1/10] Mise à jour des listes APT..."
apt-get update -qq
apt-get install -y --no-install-recommends \
  curl wget git unzip zip ca-certificates \
  lsb-release software-properties-common \
  apt-transport-https gnupg2

# =============================================================================
# 2. ZSH + OH MY ZSH
# =============================================================================
echo "[2/10] Installation de ZSH..."
apt-get install -y --no-install-recommends \
  zsh \
  zsh-syntax-highlighting \
  zsh-autosuggestions \
  fonts-powerline \
  fonts-font-awesome

# Créer l'utilisateur shark AVANT d'essayer de lui assigner un shell
if ! id "shark" &>/dev/null; then
  useradd -m -s "$(command -v zsh)" -G sudo,audio,video,plugdev,netdev shark 2>/dev/null || \
  useradd -m -s "$(command -v zsh)" shark 2>/dev/null || true
fi

# Définir le mot de passe par défaut pour 'shark' et 'root' (shark)
echo "shark:shark" | chpasswd 2>/dev/null || true
echo "root:shark" | chpasswd 2>/dev/null || true

# Installation Oh My Zsh en mode non-interactif
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

  # Copier le .zshrc SharkOS
  if [[ -f "/etc/skel/.zshrc" ]]; then
    cp "/etc/skel/.zshrc" "$HOME_DIR/.zshrc"
  fi

  # Droits
  chown -R "$TARGET_USER:$TARGET_USER" "$HOME_DIR" 2>/dev/null || true
done

# ZSH comme shell par défaut
ZSH_PATH="$(command -v zsh)"
chsh -s "$ZSH_PATH" root 2>/dev/null || true
chsh -s "$ZSH_PATH" shark 2>/dev/null || true

# =============================================================================
# 3. OUTILS SÉCURITÉ
# =============================================================================
echo "[3/10] Outils de sécurité..."
apt-get install -y --no-install-recommends \
  nmap \
  wireshark \
  ufw \
  gufw \
  net-tools \
  iputils-ping \
  traceroute \
  dnsutils \
  whois \
  tcpdump \
  netcat-openbsd \
  macchanger

# Wireshark sans root pour le groupe shark
echo "wireshark-common wireshark-common/install-setuid boolean true" \
  | debconf-set-selections
dpkg-reconfigure -f noninteractive wireshark-common 2>/dev/null || true
usermod -aG wireshark shark 2>/dev/null || true

# =============================================================================
# 4. MACCHANGER — Rotation MAC automatique
# =============================================================================
echo "[4/10] Macchanger — rotation MAC automatique..."

# Script global de randomisation
cat > /usr/local/bin/sharkos-mac-randomize << 'MACSCRIPT'
#!/usr/bin/env bash
# SharkOS — Randomisation MAC de toutes les interfaces réseau
echo "🦈 SharkOS : Randomisation des adresses MAC..."
for IFACE in $(ip link show | awk -F': ' '/^[0-9]+: (wl|en|eth)/{print $2}' | tr -d '@' | cut -d'@' -f1); do
  ip link set "$IFACE" down 2>/dev/null || continue
  macchanger -r "$IFACE" 2>/dev/null && echo "  ✓ $IFACE → nouvelle MAC" || true
  ip link set "$IFACE" up 2>/dev/null || true
done
echo "🦈 Randomisation MAC terminée."
MACSCRIPT
chmod +x /usr/local/bin/sharkos-mac-randomize

# Service systemd global
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

# Hook NetworkManager : re-randomise à chaque reconnexion Wi-Fi
mkdir -p /etc/NetworkManager/dispatcher.d/
cat > /etc/NetworkManager/dispatcher.d/99-sharkos-mac << 'NMHOOK'
#!/usr/bin/env bash
# SharkOS — Re-randomise la MAC à chaque connexion Wi-Fi
IFACE="$1"
EVENT="$2"
if [[ "$EVENT" == "up" ]] && [[ "$IFACE" == wl* ]]; then
  /usr/local/bin/sharkos-mac-randomize &>/dev/null &
fi
NMHOOK
chmod +x /etc/NetworkManager/dispatcher.d/99-sharkos-mac

# FIX : systemctl enable || true en chroot (pas de init actif)
systemctl enable sharkos-mac-randomize.service 2>/dev/null || true

# =============================================================================
# 5. SNAP (installé mais PAS configuré dans le chroot — impossible)
# =============================================================================
echo "[5/10] Snap..."
apt-get install -y --no-install-recommends \
  snapd \
  squashfuse \
  fuse3

# Lien symbolique Snap
ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true

# Activer les services Snap (pris en compte au premier boot live, pas maintenant)
systemctl enable snapd.service 2>/dev/null || true
systemctl enable snapd.apparmor.service 2>/dev/null || true

# NOTE : "snap install" est IMPOSSIBLE dans un chroot sans snapd démarré.
# Les snaps (Discord, Spotify, VSCode) s'installent après le boot avec :
#   sudo snap install discord
#   sudo snap install spotify
#   sudo snap install code --classic
# Un script post-boot est créé ci-dessous pour faciliter ça.

cat > /usr/local/bin/sharkos-snap-setup << 'SNAPSETUP'
#!/usr/bin/env bash
# SharkOS — Installation des apps Snap populaires (à lancer après le boot)
echo "🦈 SharkOS Snap Setup — Installation des apps modernes..."
echo ""
echo "Disponible maintenant :"
echo "  sudo snap install discord"
echo "  sudo snap install spotify"
echo "  sudo snap install code --classic"
echo "  sudo snap install vlc"
echo "  sudo snap install obsidian --classic"
echo ""
echo "Ou utilise le Snap Store graphique : snap-store"
echo ""
SNAPSETUP
chmod +x /usr/local/bin/sharkos-snap-setup

# =============================================================================
# 6. CLAMAV
# =============================================================================
echo "[6/10] ClamAV..."
apt-get install -y --no-install-recommends \
  clamav \
  clamav-daemon \
  clamav-freshclam \
  clamtk

# FIX : freshclam peut échouer si pas de réseau en chroot CI — non bloquant
freshclam --quiet 2>/dev/null || echo "   ⚠️  Définitions ClamAV : mise à jour au premier boot"

# Activer freshclam seulement (pas clamav-daemon pour rester léger)
systemctl enable clamav-freshclam.service 2>/dev/null || true
# clamav-daemon désactivé par défaut (scan à la demande avec 'sharkav')

# =============================================================================
# 7. WINE + LUTRIS (Compatibilité .exe / Proton)
# =============================================================================
echo "[7/10] Wine + Lutris (compatibilité Windows)..."

# Architecture 32-bit pour Wine
dpkg --add-architecture i386
apt-get update -qq

apt-get install -y --no-install-recommends \
  wine \
  wine32 \
  wine64 \
  winetricks \
  cabextract \
  zenity

# Lutris : installé si disponible dans le dépôt, sinon via PPA
if apt-cache show lutris &>/dev/null; then
  apt-get install -y --no-install-recommends lutris 2>/dev/null || true
else
  echo "   ⚠️  Lutris non disponible dans les dépôts — ajout du PPA..."
  add-apt-repository -y ppa:lutris-team/lutris 2>/dev/null || true
  apt-get update -qq 2>/dev/null || true
  apt-get install -y --no-install-recommends lutris 2>/dev/null || true
fi

# FIX : steam-installer souvent absent de Bookworm — tentative non bloquante
apt-get install -y --no-install-recommends steam-installer 2>/dev/null || \
  echo "   ⚠️  steam-installer non disponible — installe Steam via snap : sudo snap install steam"

# Script helper sharkrun
cat > /usr/local/bin/sharkrun << 'SHARKRUN'
#!/usr/bin/env bash
# SharkOS — Lance un fichier .exe avec Wine
# Usage : sharkrun fichier.exe [args...]
if [[ -z "${1:-}" ]]; then
  echo "Usage: sharkrun <fichier.exe> [arguments...]"
  echo "       sharkrun setup.exe"
  echo "       sharkrun 'C:\\Program Files\\app\\app.exe'"
  exit 1
fi
EXE="$1"
shift
echo "🦈 SharkOS : Lancement de $EXE via Wine..."
WINEPREFIX="${WINEPREFIX:-$HOME/.wine-sharkos}" wine "$EXE" "$@"
SHARKRUN
chmod +x /usr/local/bin/sharkrun

# =============================================================================
# 8. FLATPAK + UTILITAIRES
# =============================================================================
echo "[8/10] Flatpak + utilitaires système..."
apt-get install -y --no-install-recommends \
  flatpak \
  xdg-desktop-portal-gtk \
  neofetch \
  htop \
  inxi \
  dconf-cli \
  gdebi-core \
  imagemagick

# Ajouter Flathub
flatpak remote-add --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# =============================================================================
# 10. CONFIGURATION NEOFETCH SHARKOS
# =============================================================================
echo "[10/10] Neofetch SharkOS..."
mkdir -p /etc/sharkos
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

mkdir -p /etc/skel/.config/neofetch
cp /etc/sharkos/neofetch.conf /etc/skel/.config/neofetch/config.conf

echo ""
echo "✅ [HOOK 10] Installation des outils terminée."
echo ""
