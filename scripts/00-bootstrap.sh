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
  --bootappend-live "boot=live components quiet splash locales=fr_FR.UTF-8 keyboard-layouts=fr \
                     mitigations=on audit=1 log_buf_len=1M ipv6.disable=0 page_poison=1 slab_nomerge" \
  --compression zstd \
  --mirror-bootstrap http://deb.debian.org/debian \
  --mirror-chroot   http://deb.debian.org/debian \
  --mirror-binary   http://deb.debian.org/debian \
  --mirror-chroot-security   http://security.debian.org/debian-security \
  --mirror-binary-security   http://security.debian.org/debian-security \
  --keyring-packages debian-archive-keyring \
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
# NB : pas de ttf-mscorefonts-installer — son postinst télécharge depuis
# SourceForge et bloque la build noninteractive. fonts-liberation fournit
# l'équivalence métrique Arial/Times/Courier.
fonts-noto
fonts-noto-color-emoji
fonts-liberation

# ── Apps de base ──────────────────────────────────────────────────
# NB : arcade-manager n'existe PAS dans les dépôts Debian (projet GitHub
# RetroPie/Recalbox) — l'inclure faisait échouer toute la build.
# NB taille ISO : LibreOffice (~800 Mo) / Thunderbird (~270 Mo) / la stack
# Wine+Gaming (~1,8 Go) sont EXCLUS de l'ISO pour rester < 2 Go — installés
# à la demande avec `shark-extras` (voir chroot-hooks/50-sharkos-finalize.sh).
firefox-esr
gimp
vlc
geany
mousepad
file-roller

# ── Terminal & Shell ──────────────────────────────────────────────
zsh
bash
git
ca-certificates

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
# calamares   # NB : volontairement absent (< 2 Go) — le fallback est le
#              # setup-wizard + sharkos-installer (kit complet ci-dessous).

# ── Setup wizard (assistant graphique d'installation, Python/GTK) ──
python3-gi
gir1.2-gtk-3.0
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
elif [[ -f "$ROOT_DIR/wallpapers/wallpaper.png" ]]; then
  cp "$ROOT_DIR/wallpapers/wallpaper.png" \
     config/includes.chroot/usr/share/sharkos/wallpaper.png
fi

# Logo (noms v1 wallpaper/logo.png — v2 sharkos-wall/sharkos-logo.png, comme
# simulate-build.sh) : utilisé par le setup-wizard + branding Calamares.
if [[ -f "$ROOT_DIR/wallpapers/sharkos-logo.png" ]]; then
  cp "$ROOT_DIR/wallpapers/sharkos-logo.png" \
     config/includes.chroot/usr/share/sharkos/sharkos-logo.png
elif [[ -f "$ROOT_DIR/wallpapers/logo.png" ]]; then
  cp "$ROOT_DIR/wallpapers/logo.png" \
     config/includes.chroot/usr/share/sharkos/sharkos-logo.png
fi

# =============================================================================
# 6b. INCLUDE CHROOT — kit d'installation réel dans l'ISO
#     (sinon l'ISO ne contiendrait qu'un stub non fonctionnel écrit par hook 60)
# =============================================================================
echo "[6b/6] Kit installation + Calamares dans l'ISO..."

# Vrai sharkos-installer (pas le stub) + cycle + vérificateur ISO
mkdir -p config/includes.chroot/usr/local/bin
if [[ -f "$ROOT_DIR/scripts/sharkos-installer" ]]; then
  install -m 0755 "$ROOT_DIR/scripts/sharkos-installer" \
    config/includes.chroot/usr/local/bin/sharkos-installer
  echo "   ✓ sharkos-installer (réel, $(wc -l < "$ROOT_DIR/scripts/sharkos-installer") lignes)"
fi
if [[ -f "$ROOT_DIR/scripts/sharkos-install-cycle.sh" ]]; then
  install -m 0755 "$ROOT_DIR/scripts/sharkos-install-cycle.sh" \
    config/includes.chroot/usr/local/bin/sharkos-install-cycle.sh
  echo "   ✓ sharkos-install-cycle.sh"
fi
if [[ -f "$ROOT_DIR/scripts/03-verify-iso.sh" ]]; then
  install -m 0755 "$ROOT_DIR/scripts/03-verify-iso.sh" \
    config/includes.chroot/usr/local/bin/sharkos-verify-iso
  echo "   ✓ sharkos-verify-iso (03-verify-iso.sh)"
fi

# Bundle Calamares complet (settings + modules + branding)
if [[ -d "$ROOT_DIR/config/calamares" ]]; then
  mkdir -p config/includes.chroot/etc/calamares/sharkos
  cp -r "$ROOT_DIR/config/calamares/." \
        config/includes.chroot/etc/calamares/sharkos/
  echo "   ✓ Calamares bundle (settings.conf, modules, branding)"
fi

# Vrai setup-wizard graphique + lanceur d'autostart (assistant d'installation)
# NB : avant ce fix, le wizard n'était JAMAIS copié dans l'ISO — seul un
# commentaire du hook 60 y faisait référence → l'assistant n'apparaissait pas
# au boot. On shippe maintenant la source + le lanceur + l'autostart XFCE.
mkdir -p config/includes.chroot/usr/local/bin \
         config/includes.chroot/etc/xdg/autostart \
         config/includes.chroot/usr/share/applications
if [[ -f "$ROOT_DIR/config/sharkos-setup-wizard" ]]; then
  install -m 0755 "$ROOT_DIR/config/sharkos-setup-wizard" \
    config/includes.chroot/usr/local/bin/sharkos-setup-wizard
  echo "   ✓ sharkos-setup-wizard (réel, $(wc -l < "$ROOT_DIR/config/sharkos-setup-wizard") lignes)"
fi
if [[ -f "$ROOT_DIR/config/sharkos-autostart-setup" ]]; then
  install -m 0755 "$ROOT_DIR/config/sharkos-autostart-setup" \
    config/includes.chroot/usr/local/bin/sharkos-autostart-setup
  echo "   ✓ sharkos-autostart-setup (lanceur)"
fi
if [[ -f "$ROOT_DIR/config/sharkos-setup-wizard.desktop" ]]; then
  cp "$ROOT_DIR/config/sharkos-setup-wizard.desktop" \
     config/includes.chroot/etc/xdg/autostart/sharkos-setup-wizard.desktop
  echo "   ✓ autostart XFCE wizard"
fi
if [[ -f "$ROOT_DIR/config/install-sharkos.desktop" ]]; then
  cp "$ROOT_DIR/config/install-sharkos.desktop" \
     config/includes.chroot/usr/share/applications/install-sharkos.desktop
  echo "   ✓ launcher install-sharkos"
fi

echo ""
echo "✅ Bootstrap terminé ! Hooks copiés : 10 → 20 → 30 → 40 → 50 → 60"
echo "   Artifact final : SharkOS-Dragon-Edition.iso"
echo "   sudo bash scripts/01-build-iso.sh"
echo ""
