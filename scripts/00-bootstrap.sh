#!/usr/bin/env bash
# =============================================================================
# SharkOS — 00-bootstrap.sh v3.0 (Garuda-style)
# Prépare l'environnement live-build avec config Garuda-inspirée
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 SharkOS Bootstrap — Dragon Edition (Garuda-style)"
echo "======================================================"
echo ""

# =============================================================================
# 1. DÉPENDANCES HOST
# =============================================================================
echo "[1/6] Dépendances build..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  live-build \
  squashfs-tools \
  xorriso \
  isolinux \
  syslinux-utils \
  git curl wget \
  python3 python3-pip \
  rsync \
  zstd \
  imagemagick

# =============================================================================
# 2. RÉPERTOIRE LIVE-BUILD
# =============================================================================
echo "[2/6] Répertoire live-build..."
LB_DIR="$(dirname "$0")/../iso-build"
cd "$LB_DIR"

lb clean 2>/dev/null || true

# =============================================================================
# 3. CONFIG LIVE-BUILD (Garuda-inspired : zstd, firmware, non-free)
# =============================================================================
echo "[3/6] Config live-build Garuda-style..."
lb config \
  --architectures amd64 \
  --distribution bookworm \
  --archive-areas "main contrib non-free non-free-firmware" \
  --apt-recommends false \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components quiet splash locales=fr_FR.UTF-8 keyboard-layouts=fr" \
  --compression zstd \
  --debootstrap-options "--include=ca-certificates" \
  --firmware-binary true \
  --firmware-chroot true \
  --image-name "SharkOS-Dragon" \
  --iso-application "SharkOS Dragon Edition" \
  --iso-publisher "SharkOS Project" \
  --iso-volume "SHARKOS_DRAGON" \
  --memtest none \
  --win32-loader false \
  2>&1 | tail -5

# =============================================================================
# 4. PAQUETS DESKTOP (KDE Plasma ou XFCE selon dispo)
# =============================================================================
echo "[4/6] Liste de paquets..."
mkdir -p config/package-lists

cat > config/package-lists/sharkos-desktop.list.chroot << 'PKGLIST'
# ── Desktop XFCE (base fiable Debian) ─────────────────────────────
xfce4
xfce4-goodies
xfce4-terminal
thunar
thunar-archive-plugin
thunar-volman
gvfs
gvfs-backends
network-manager
network-manager-gnome
plank
lightdm
lightdm-gtk-greeter
lightdm-gtk-greeter-settings
pulseaudio
pulseaudio-utils
pavucontrol

# ── Polices ────────────────────────────────────────────────────────
fonts-noto
fonts-noto-color-emoji
fonts-liberation
ttf-mscorefonts-installer

# ── Apps de base ──────────────────────────────────────────────────
firefox-esr
thunderbird
gimp
vlc
libreoffice
geany
mousepad
arcade-manager
file-roller

# ── Terminal & Shell ──────────────────────────────────────────────
zsh
bash
git

# ── Bluetooth ─────────────────────────────────────────────────────
bluez
blueman

# ── Firmware & drivers ────────────────────────────────────────────
firmware-linux
firmware-linux-nonfree
firmware-misc-nonfree
firmware-iwlwifi
firmware-realtek
firmware-atheros
amd64-microcode
intel-microcode

# ── Calamares (installateur graphique — comme Garuda) ─────────────
# calamares
PKGLIST

# =============================================================================
# 5. HOOKS CHROOT
# =============================================================================
echo "[5/6] Hooks chroot..."
ROOT_DIR="$(dirname "$0")/.."
mkdir -p config/hooks/live

for HOOK in \
  "$ROOT_DIR/chroot-hooks/10-install-tools.sh" \
  "$ROOT_DIR/chroot-hooks/20-apply-theme.sh" \
  "$ROOT_DIR/chroot-hooks/30-configure-shell.sh" \
  "$ROOT_DIR/chroot-hooks/40-cleanup.sh" \
  "$ROOT_DIR/chroot-hooks/50-sharkos-finalize.sh" \
  "$ROOT_DIR/chroot-hooks/60-sharkos-polish.sh"; do
  if [[ -f "$HOOK" ]]; then
    DEST="config/hooks/live/$(basename $HOOK .sh).hook.chroot"
    cp "$HOOK" "$DEST"
    chmod +x "$DEST"
    echo "   ✓ $(basename $HOOK)"
  fi
done

# =============================================================================
# 6. ASSETS (wallpaper)
# =============================================================================
echo "[6/6] Assets..."
mkdir -p config/includes.chroot/usr/share/sharkos

if [[ -f "$ROOT_DIR/wallpapers/sharkos-wall.svg" ]]; then
  # Convertir SVG → PNG
  command -v rsvg-convert &>/dev/null && \
    rsvg-convert -W 1920 -H 1080 \
      "$ROOT_DIR/wallpapers/sharkos-wall.svg" \
      -o config/includes.chroot/usr/share/sharkos/wallpaper.png 2>/dev/null || \
  command -v convert &>/dev/null && \
    convert -background '#0d0221' \
      "$ROOT_DIR/wallpapers/sharkos-wall.svg" \
      -resize 1920x1080 \
      config/includes.chroot/usr/share/sharkos/wallpaper.png 2>/dev/null || \
  echo "   ⚠ SVG non convertible — le hook génèrera un fond de secours"
elif [[ -f "$ROOT_DIR/wallpapers/sharkos-wall.png" ]]; then
  cp "$ROOT_DIR/wallpapers/sharkos-wall.png" \
     config/includes.chroot/usr/share/sharkos/wallpaper.png
fi

echo ""
echo "✅ Bootstrap terminé ! Hooks copiés : 10 → 20 → 30 → 40 → 50 → 60"
echo "   sudo bash scripts/01-build-iso.sh"
echo ""
