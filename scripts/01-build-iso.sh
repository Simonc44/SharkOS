#!/usr/bin/env bash
# =============================================================================
# SharkOS — 01-build-iso.sh (VERSION FINALE)
# Lance la construction complète de l'ISO via live-build
# Intègre : Xubuntu settings, WhiteSur, Snap, ClamAV, Proton, Macchanger
# Les wallpapers/logos sont en PNG (pas de SVG)
# =============================================================================
set -euo pipefail

SHARK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$SHARK_DIR/iso-build"
ISO_NAME="SharkOS.iso"
START_TIME=$(date +%s)

echo ""
echo "🦈 ============================================"
echo "   SharkOS — Construction de l'ISO v2.0"
echo "============================================ 🦈"
echo ""

# --- Vérification root ---
if [[ $EUID -ne 0 ]]; then
  echo "[ERREUR] Exécute ce script en root : sudo bash scripts/01-build-iso.sh"
  exit 1
fi

# --- Vérification bootstrap ---
if [[ ! -d "$BUILD_DIR/auto" ]]; then
  echo "[ERREUR] Lance d'abord : sudo bash scripts/00-bootstrap.sh"
  exit 1
fi

# --- Vérification PNG wallpaper ---
if [[ ! -f "$SHARK_DIR/wallpapers/wallpaper.png" ]]; then
  echo "⚠️  ATTENTION : Aucun fichier wallpapers/wallpaper.png trouvé."
  echo "   Place ton fond d'écran PNG dans : $SHARK_DIR/wallpapers/wallpaper.png"
  echo "   Un fond d'écran de remplacement sera généré automatiquement."
  echo ""
fi

# --- Vérification PNG logo ---
if [[ ! -f "$SHARK_DIR/wallpapers/logo.png" ]]; then
  echo "⚠️  ATTENTION : Aucun fichier wallpapers/logo.png trouvé."
  echo "   Place ton logo PNG dans : $SHARK_DIR/wallpapers/logo.png"
  echo ""
fi

cd "$BUILD_DIR"

# =============================================================================
# FICHIER AUTO/CONFIG
# =============================================================================
cat > auto/config << 'AUTOCONFIG'
#!/bin/sh
set -e
lb config noauto \
  --system live \
  --distribution bookworm \
  --debian-installer none \
  --archive-areas "main contrib non-free non-free-firmware" \
  --apt-options "--yes --no-install-recommends" \
  --bootappend-live "boot=live components quiet splash hostname=sharkos username=shark" \
  --iso-application "SharkOS" \
  --iso-preparer "SharkOS Build System v2.0" \
  --iso-publisher "SharkOS Project — Rapide. Furtif. Létal." \
  --iso-volume "SHARKOS" \
  --binary-images iso-hybrid \
  --memtest none \
  --firmware-binary false \
  --firmware-chroot false \
  "${@}"
AUTOCONFIG
chmod +x auto/config

cat > auto/clean << 'AUTOCLEAN'
#!/bin/sh
set -e
lb clean --purge
AUTOCLEAN
chmod +x auto/clean

# =============================================================================
# LISTE DE PAQUETS (inclus dans l'ISO)
# =============================================================================
cat > config/package-lists/sharkos.list.chroot << 'PACKAGES'
# === Base système ===
xorg
xfce4
xfce4-goodies
lightdm
lightdm-gtk-greeter
lightdm-gtk-greeter-settings

# === Dock ===
plank

# === Apparence GTK ===
gtk2-engines-murrine
gtk2-engines-pixbuf
libglib2.0-bin
sassc
gnome-themes-extra
dconf-cli
imagemagick

# === Terminal & Shell ===
zsh
zsh-syntax-highlighting
zsh-autosuggestions
fonts-powerline
fonts-font-awesome
xfce4-terminal
curl
git
wget
unzip
zip
rsync

# === Sécurité ===
nmap
wireshark
ufw
gufw
net-tools
iputils-ping
traceroute
dnsutils
whois
tcpdump
netcat-openbsd
macchanger

# === Antivirus ===
clamav
clamav-freshclam
clamtk

# === Snap ===
snapd
squashfuse
fuse

# === Flatpak ===
flatpak
xdg-desktop-portal-gtk

# === Compatibilité Windows (Wine) ===
wine
wine32
wine64
winetricks
cabextract
zenity
lutris

# === Applications de base ===
firefox-esr
thunar
mousepad
ristretto
xfce4-screenshooter
network-manager
network-manager-gnome
pulseaudio
pavucontrol
gvfs
gvfs-backends

# === Fonts ===
fonts-liberation
fonts-open-sans
fonts-noto
fonts-dejavu

# === Utilitaires système ===
htop
neofetch
inxi
lsb-release
gdebi-core
PACKAGES

# =============================================================================
# COPIE DES ASSETS PNG (wallpaper + logo)
# =============================================================================
echo "[PRÉ-BUILD] Copie des assets PNG..."
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/share/sharkos"
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/sharkos"

# Wallpaper PNG
if [[ -f "$SHARK_DIR/wallpapers/wallpaper.png" ]]; then
  cp "$SHARK_DIR/wallpapers/wallpaper.png" \
     "$BUILD_DIR/config/includes.chroot/usr/share/sharkos/wallpaper.png"
  cp "$SHARK_DIR/wallpapers/wallpaper.png" \
     "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/sharkos/sharkos.png"
  echo "   ✓ wallpaper.png copié"
fi

# Logo PNG (LightDM, GRUB splash, etc.)
if [[ -f "$SHARK_DIR/wallpapers/logo.png" ]]; then
  cp "$SHARK_DIR/wallpapers/logo.png" \
     "$BUILD_DIR/config/includes.chroot/usr/share/sharkos/logo.png"
  echo "   ✓ logo.png copié"
fi

# Copie du .zshrc dans skel
mkdir -p "$BUILD_DIR/config/includes.chroot/etc/skel"
cp "$SHARK_DIR/config/.zshrc" \
   "$BUILD_DIR/config/includes.chroot/etc/skel/.zshrc"

# Copie des hooks chroot (avec les numéros de priorité)
mkdir -p "$BUILD_DIR/config/hooks/live"
for HOOK in "$SHARK_DIR/chroot-hooks"/*.sh; do
  HOOK_NAME=$(basename "$HOOK")
  cp "$HOOK" "$BUILD_DIR/config/hooks/live/${HOOK_NAME}"
  chmod +x "$BUILD_DIR/config/hooks/live/${HOOK_NAME}"
  echo "   ✓ Hook copié : $HOOK_NAME"
done

# =============================================================================
# LANCEMENT DE LA BUILD
# =============================================================================
echo ""
echo "[BUILD] Configuration live-build..."
bash auto/config

echo "[BUILD] Construction en cours..."
echo "        Cela peut prendre 20-45 minutes selon ta connexion."
echo "        Log : tail -f $SHARK_DIR/sharkos-build.log"
echo ""

lb build 2>&1 | tee "$SHARK_DIR/sharkos-build.log"

# =============================================================================
# FINALISATION
# =============================================================================
echo ""
echo "[FIN] Recherche de l'ISO générée..."

ISO_FOUND=""
for F in ./*.iso ./*.hybrid.iso; do
  [[ -f "$F" ]] && ISO_FOUND="$F" && break
done

if [[ -n "$ISO_FOUND" ]]; then
  mv "$ISO_FOUND" "$SHARK_DIR/$ISO_NAME"
  END_TIME=$(date +%s)
  DURATION=$(( (END_TIME - START_TIME) / 60 ))
  ISO_SIZE=$(du -sh "$SHARK_DIR/$ISO_NAME" | cut -f1)

  echo ""
  echo "🦈 ============================================"
  echo "   BUILD SHARKOS TERMINÉE AVEC SUCCÈS !"
  echo "============================================"
  echo "   📀 ISO    : $SHARK_DIR/$ISO_NAME"
  echo "   💾 Taille : $ISO_SIZE"
  echo "   ⏱  Durée  : ${DURATION} minutes"
  echo ""
  echo "   → Pour flasher sur USB :"
  echo "     sudo bash scripts/02-flash-usb.sh /dev/sdX"
  echo ""
  echo "   → Pour tester en VM (VirtualBox/QEMU) :"
  echo "     qemu-system-x86_64 -m 2G -cdrom $SHARK_DIR/$ISO_NAME -boot d"
  echo "============================================ 🦈"
else
  echo ""
  echo "[ERREUR] Aucune ISO trouvée. Consulte le log :"
  echo "  cat $SHARK_DIR/sharkos-build.log | tail -50"
  exit 1
fi
