#!/usr/bin/env bash
# =============================================================================
# SharkOS — 01-build-iso.sh
# Lance la construction complète de l'ISO via live-build
# =============================================================================
set -euo pipefail

SHARK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$SHARK_DIR/iso-build"
ISO_NAME="SharkOS.iso"
START_TIME=$(date +%s)

echo ""
echo "🦈 ============================================"
echo "   SharkOS — Construction de l'ISO"
echo "============================================ 🦈"
echo ""

# --- Vérification root ---
if [[ $EUID -ne 0 ]]; then
  echo "[ERREUR] Exécute ce script en root : sudo bash scripts/01-build-iso.sh"
  exit 1
fi

# --- Vérification que le bootstrap a été fait ---
if [[ ! -d "$BUILD_DIR/auto" ]]; then
  echo "[ERREUR] Lance d'abord : sudo bash scripts/00-bootstrap.sh"
  exit 1
fi

cd "$BUILD_DIR"

# =============================================================================
# FICHIER AUTO/CONFIG — Configuration principale live-build
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
  --iso-preparer "SharkOS Build System" \
  --iso-publisher "SharkOS Project" \
  --iso-volume "SHARKOS" \
  --image-name "SharkOS" \
  --binary-images iso-hybrid \
  --memtest none \
  --firmware-binary false \
  --firmware-chroot false \
  "${@}"
AUTOCONFIG
chmod +x auto/config

# --- Fichier auto/clean ---
cat > auto/clean << 'AUTOCLEAN'
#!/bin/sh
set -e
lb clean --purge
AUTOCLEAN
chmod +x auto/clean

# --- Fichier auto/build ---
cat > auto/build << 'AUTOBUILD'
#!/bin/sh
set -e
lb build 2>&1 | tee ../sharkos-build.log
AUTOBUILD
chmod +x auto/build

# =============================================================================
# LISTE DE PAQUETS
# =============================================================================
cat > config/package-lists/sharkos.list.chroot << 'PACKAGES'
# === Base système ===
xorg
xfce4
xfce4-goodies
lightdm
lightdm-gtk-greeter
lightdm-gtk-greeter-settings

# === Dock & apparence ===
plank
gtk2-engines-murrine
gtk2-engines-pixbuf
libglib2.0-bin
sassc
gnome-themes-extra
dconf-cli

# === Terminal & shell ===
zsh
zsh-syntax-highlighting
zsh-autosuggestions
fonts-powerline
xfce4-terminal
curl
git
wget
unzip
zip

# === Outils de sécurité (essentiel Kali) ===
nmap
wireshark
ufw
gufw
net-tools
iputils-ping
traceroute

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

# === Fonts macOS-like ===
fonts-liberation
fonts-open-sans
fonts-noto

# === Utilitaires système ===
htop
neofetch
inxi
lsb-release
PACKAGES

# =============================================================================
# LANCEMENT DE LA BUILD
# =============================================================================
echo "[1/3] Configuration de live-build..."
bash auto/config

echo "[2/3] Construction en cours (peut prendre 20-40 min)..."
echo "      Log en temps réel : tail -f $SHARK_DIR/sharkos-build.log"
lb build 2>&1 | tee "$SHARK_DIR/sharkos-build.log"

# --- Renommage de l'ISO ---
echo "[3/3] Finalisation de l'ISO..."
if ls ./*.iso 2>/dev/null | head -n1 | grep -q ".iso"; then
  GENERATED_ISO=$(ls ./*.iso | head -n1)
  mv "$GENERATED_ISO" "$SHARK_DIR/$ISO_NAME"
  echo ""
  END_TIME=$(date +%s)
  DURATION=$(( (END_TIME - START_TIME) / 60 ))
  ISO_SIZE=$(du -sh "$SHARK_DIR/$ISO_NAME" | cut -f1)
  echo "🦈 ============================================"
  echo "   BUILD TERMINÉE AVEC SUCCÈS !"
  echo "============================================"
  echo "   ISO   : $SHARK_DIR/$ISO_NAME"
  echo "   Taille : $ISO_SIZE"
  echo "   Durée  : ${DURATION} minutes"
  echo "============================================ 🦈"
else
  echo "[ERREUR] Aucune ISO générée. Vérifie le log : $SHARK_DIR/sharkos-build.log"
  exit 1
fi
