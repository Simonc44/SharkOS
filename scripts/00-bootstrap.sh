#!/usr/bin/env bash
# =============================================================================
# SharkOS — 00-bootstrap.sh
# Prépare l'environnement live-build sur un hôte Debian/Ubuntu
# =============================================================================
set -euo pipefail

SHARK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$SHARK_DIR/iso-build"

echo ""
echo "🦈 ============================================"
echo "   SharkOS — Bootstrap de l'environnement"
echo "============================================ 🦈"
echo ""

# --- Vérification des droits root ---
if [[ $EUID -ne 0 ]]; then
  echo "[ERREUR] Ce script doit être exécuté en root."
  echo "         Utilise : sudo bash scripts/00-bootstrap.sh"
  exit 1
fi

# --- Mise à jour du système hôte ---
echo "[1/5] Mise à jour du système hôte..."
apt-get update -qq
apt-get upgrade -y -qq

# --- Installation des dépendances live-build ---
echo "[2/5] Installation de live-build et outils ISO..."
apt-get install -y -qq \
  live-build \
  squashfs-tools \
  xorriso \
  isolinux \
  syslinux-utils \
  syslinux-common \
  genisoimage \
  git \
  curl \
  wget \
  ca-certificates \
  debootstrap \
  rsync \
  dconf-cli

# --- Création de la structure iso-build ---
echo "[3/5] Création de la structure iso-build..."
mkdir -p "$BUILD_DIR/auto"
mkdir -p "$BUILD_DIR/config/hooks/live"
mkdir -p "$BUILD_DIR/config/includes.chroot/etc/skel"
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/share/sharkos"
mkdir -p "$BUILD_DIR/config/package-lists"

# --- Copie des hooks chroot ---
echo "[4/5] Copie des hooks chroot..."
for hook in "$SHARK_DIR/chroot-hooks"/*.sh; do
  cp "$hook" "$BUILD_DIR/config/hooks/live/"
  chmod +x "$BUILD_DIR/config/hooks/live/$(basename "$hook")"
done

# --- Copie des fichiers de config utilisateur ---
echo "[5/5] Copie des fichiers de config (skel)..."
cp "$SHARK_DIR/config/.zshrc" "$BUILD_DIR/config/includes.chroot/etc/skel/.zshrc"
cp "$SHARK_DIR/config/plank.dconf" "$BUILD_DIR/config/includes.chroot/usr/share/sharkos/plank.dconf"

if [[ -f "$SHARK_DIR/wallpapers/sharkos-wall.svg" ]]; then
  cp "$SHARK_DIR/wallpapers/sharkos-wall.svg" \
     "$BUILD_DIR/config/includes.chroot/usr/share/sharkos/sharkos-wall.svg"
fi

echo ""
echo "✅ Bootstrap terminé avec succès !"
echo "   Lance maintenant : sudo bash scripts/01-build-iso.sh"
echo ""
