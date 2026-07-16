#!/usr/bin/env bash
# =============================================================================
# SharkOS — 00-bootstrap.sh (v2 — corrigé)
# Prépare l'environnement live-build sur un hôte Debian/Ubuntu
# FIXES : copie logo.png, suppression ref SVG, chemins robustes
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
  dconf-cli \
  imagemagick \
  file

# --- Vérification que les wallpapers PNG existent ---
echo "[3/5] Vérification des assets PNG..."
WARN=0

# Déterminer les vrais assets
WALLPAPER_SRC=""
if [[ -f "$SHARK_DIR/wallpapers/sharkos-wall.png" ]]; then
  WALLPAPER_SRC="$SHARK_DIR/wallpapers/sharkos-wall.png"
elif [[ -f "$SHARK_DIR/wallpapers/wallpaper.png" ]]; then
  WALLPAPER_SRC="$SHARK_DIR/wallpapers/wallpaper.png"
fi

LOGO_SRC=""
if [[ -f "$SHARK_DIR/wallpapers/sharkos-logo.png" ]]; then
  LOGO_SRC="$SHARK_DIR/wallpapers/sharkos-logo.png"
elif [[ -f "$SHARK_DIR/wallpapers/logo.png" ]]; then
  LOGO_SRC="$SHARK_DIR/wallpapers/logo.png"
fi

if [[ -n "$WALLPAPER_SRC" ]]; then
  echo "   ✅ Wallpaper trouvé : $(basename "$WALLPAPER_SRC")"
  MIME=$(file --mime-type -b "$WALLPAPER_SRC")
  if [[ "$MIME" != "image/png" ]]; then
    echo "   ❌ $WALLPAPER_SRC n'est pas un PNG valide (détecté : $MIME)"
    exit 1
  fi
else
  echo "   ⚠️  Wallpaper absent — il sera généré automatiquement"
  WARN=$((WARN + 1))
fi

if [[ -n "$LOGO_SRC" ]]; then
  echo "   ✅ Logo trouvé : $(basename "$LOGO_SRC")"
  MIME=$(file --mime-type -b "$LOGO_SRC")
  if [[ "$MIME" != "image/png" ]]; then
    echo "   ❌ $LOGO_SRC n'est pas un PNG valide (détecté : $MIME)"
    exit 1
  fi
else
  echo "   ⚠️  Logo absent — il sera généré automatiquement"
  WARN=$((WARN + 1))
fi

# Refuser tout SVG dans wallpapers/
if find "$SHARK_DIR/wallpapers/" -name "*.svg" 2>/dev/null | grep -q "."; then
  echo "   ❌ Des fichiers .svg sont présents dans wallpapers/ — SharkOS n'utilise que des PNG !"
  find "$SHARK_DIR/wallpapers/" -name "*.svg"
  exit 1
fi

# --- Création de la structure iso-build et copie des hooks ---
echo "[4/5] Création de la structure iso-build et copie des hooks chroot..."
mkdir -p "$BUILD_DIR/auto"
mkdir -p "$BUILD_DIR/config/hooks/live"
mkdir -p "$BUILD_DIR/config/includes.chroot/etc/skel"
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/share/sharkos"
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/sharkos"
mkdir -p "$BUILD_DIR/config/package-lists"

for HOOK in "$SHARK_DIR/chroot-hooks"/*.sh; do
  HOOK_NAME=$(basename "$HOOK")
  cp "$HOOK" "$BUILD_DIR/config/hooks/live/$HOOK_NAME"
  chmod +x "$BUILD_DIR/config/hooks/live/$HOOK_NAME"
  echo "   ✓ $HOOK_NAME"
done

# --- Copie des fichiers de config et assets PNG ---
echo "[5/5] Copie des fichiers de config et assets..."

# .zshrc
cp "$SHARK_DIR/config/.zshrc" \
   "$BUILD_DIR/config/includes.chroot/etc/skel/.zshrc"
echo "   ✓ .zshrc"

# plank.dconf
cp "$SHARK_DIR/config/plank.dconf" \
   "$BUILD_DIR/config/includes.chroot/usr/share/sharkos/plank.dconf"
echo "   ✓ plank.dconf"

# wallpaper.png (PNG obligatoire — génère si absent)
if [[ -n "$WALLPAPER_SRC" ]]; then
  cp "$WALLPAPER_SRC" \
     "$BUILD_DIR/config/includes.chroot/usr/share/sharkos/wallpaper.png"
  cp "$WALLPAPER_SRC" \
     "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/sharkos/sharkos.png"
  echo "   ✓ wallpaper.png"
else
  echo "   ⚙️  Génération du wallpaper PNG de remplacement..."
  convert \
    -size 1920x1080 xc:'#0a0a0f' \
    -font DejaVu-Sans-Bold \
    -pointsize 80 -fill '#1a8cff' -gravity center \
    -annotate +0-40 'SharkOS' \
    -pointsize 22 -fill '#4a9eff' \
    -annotate +0+60 'Rapide. Furtif. Létal.' \
    "$BUILD_DIR/config/includes.chroot/usr/share/sharkos/wallpaper.png" 2>/dev/null || true
  cp "$BUILD_DIR/config/includes.chroot/usr/share/sharkos/wallpaper.png" \
     "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/sharkos/sharkos.png" 2>/dev/null || true
  echo "   ✓ wallpaper.png généré"
fi

# logo.png (PNG — génère si absent)
if [[ -n "$LOGO_SRC" ]]; then
  cp "$LOGO_SRC" \
     "$BUILD_DIR/config/includes.chroot/usr/share/sharkos/logo.png"
  echo "   ✓ logo.png"
else
  echo "   ⚙️  Génération du logo PNG de remplacement..."
  convert \
    -size 512x512 xc:'#0a0a0f' \
    -font DejaVu-Sans-Bold \
    -pointsize 200 -fill '#1a8cff' -gravity center \
    -annotate +0+0 'S' \
    "$BUILD_DIR/config/includes.chroot/usr/share/sharkos/logo.png" 2>/dev/null || true
  echo "   ✓ logo.png généré"
fi

echo ""
echo "✅ Bootstrap terminé avec succès !"
echo "   Lance maintenant : sudo bash scripts/01-build-iso.sh"
echo ""
