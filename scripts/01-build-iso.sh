#!/usr/bin/env bash
# =============================================================================
# SharkOS — 01-build-iso.sh (VERSION FINALE v3)
# FIX : miroirs Debian explicites (deb.debian.org), plus ubuntu.com
#       qui ne contient pas bookworm → erreur "Failed getting release file"
# =============================================================================
set -euo pipefail

SHARK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$SHARK_DIR/iso-build"
ISO_NAME="SharkOS.iso"
START_TIME=$(date +%s)

# Miroirs Debian officiels (bookworm est une release Debian, PAS Ubuntu)
DEBIAN_MIRROR="http://deb.debian.org/debian"
DEBIAN_SECURITY="http://security.debian.org/debian-security"

echo ""
echo "🦈 ============================================"
echo "   SharkOS — Construction de l'ISO v3.0"
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
  echo "   Un fond d'écran de remplacement sera généré automatiquement."
  echo ""
fi

# --- Vérification PNG logo ---
if [[ ! -f "$SHARK_DIR/wallpapers/logo.png" ]]; then
  echo "⚠️  ATTENTION : Aucun fichier wallpapers/logo.png trouvé."
  echo ""
fi

cd "$BUILD_DIR"

# =============================================================================
# FICHIER AUTO/CONFIG — Miroirs Debian explicites
# =============================================================================
cat > auto/config << AUTOCONFIG
#!/bin/sh
set -e
lb config noauto \\
  --system live \\
  --distribution bookworm \\
  --debian-installer none \\
  --archive-areas "main contrib non-free non-free-firmware" \\
  --apt-options "--yes --no-install-recommends" \\
  --mirror-bootstrap "${DEBIAN_MIRROR}" \\
  --mirror-chroot "${DEBIAN_MIRROR}" \\
  --mirror-chroot-security "${DEBIAN_SECURITY}" \\
  --mirror-binary "${DEBIAN_MIRROR}" \\
  --mirror-binary-security "${DEBIAN_SECURITY}" \\
  --bootappend-live "boot=live components quiet splash hostname=sharkos username=shark" \\
  --iso-application "SharkOS" \\
  --iso-preparer "SharkOS Build System v3.0" \\
  --iso-publisher "SharkOS Project" \\
  --iso-volume "SHARKOS" \\
  --binary-images iso-hybrid \\
  --memtest none \\
  --firmware-binary false \\
  --firmware-chroot false \\
  --chroot-squashfs-compression-type xz \\
  "\${@}"
AUTOCONFIG
chmod +x auto/config

cat > auto/clean << 'AUTOCLEAN'
#!/bin/sh
set -e
lb clean --purge
AUTOCLEAN
chmod +x auto/clean

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
slick-greeter

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
fuse3

# === Flatpak ===
flatpak
xdg-desktop-portal-gtk

# === Compatibilité Windows (Wine) ===
# Note : Les paquets Wine et Lutris nécessitent l'architecture i386 (multi-arch).
# Ils sont installés proprement dans chroot-hooks/10-install-tools.sh
# après dpkg --add-architecture i386, pour éviter l'erreur de build.
# wine wine32 wine64 winetricks cabextract zenity lutris

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
python3
python3-gi
gir1.2-gtk-3.0
gamemode
gamemode-dev
PACKAGES

# =============================================================================
# COPIE DES ASSETS PNG (wallpaper + logo)
# =============================================================================
echo "[PRÉ-BUILD] Copie des assets PNG..."
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/share/sharkos"
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/sharkos"

# =============================================================================
# TÉLÉCHARGEMENT PROTON-GE (CÔTÉ HÔTE)
# =============================================================================
echo "[PRÉ-BUILD] Téléchargement et préparation de Proton-GE..."
GE_HOST_DIR="$BUILD_DIR/config/includes.chroot/etc/skel/.steam/root/compatibilitytools.d"
mkdir -p "$GE_HOST_DIR"

GE_URL=""
if command -v curl &>/dev/null && command -v grep &>/dev/null; then
  # Timeout rapide de 8s pour l'API GitHub
  GE_URL=$(curl --connect-timeout 8 --max-time 15 -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep "browser_download_url.*GE-Proton.*\.tar\.gz" | head -n 1 | cut -d : -f 2,3 | tr -d ' "') || true
fi

# Fallback statique si API rate limit ou pas de connexion
if [[ -z "${GE_URL:-}" ]]; then
  echo "   ⚠️  Impossible de contacter l'API GitHub — Utilisation du fallback..."
  GE_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-10/GE-Proton9-10.tar.gz"
fi

echo "   ✓ Téléchargement de Proton-GE : $GE_URL"
if wget --connect-timeout=8 --timeout=15 -q "$GE_URL" -O /tmp/proton-ge.tar.gz; then
  echo "   ✓ Extraction de Proton-GE..."
  tar -xzf /tmp/proton-ge.tar.gz -C "$GE_HOST_DIR/"
  rm -f /tmp/proton-ge.tar.gz
  echo "   ✓ Proton-GE préparé avec succès"
else
  echo "   ⚠️  Téléchargement Proton-GE échoué (réseau non disponible lors du build) — pourra être installé plus tard"
fi

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
  cp "$WALLPAPER_SRC" \
     "$BUILD_DIR/config/includes.chroot/usr/share/sharkos/wallpaper.png"
  cp "$WALLPAPER_SRC" \
     "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/sharkos/sharkos.png"
  echo "   ✓ wallpaper.png copié"
fi

if [[ -n "$LOGO_SRC" ]]; then
  cp "$LOGO_SRC" \
     "$BUILD_DIR/config/includes.chroot/usr/share/sharkos/logo.png"
  echo "   ✓ logo.png copié"
fi

# =============================================================================
# PERSONNALISATION DU BOOTLOADER (isolinux / syslinux)
# =============================================================================
echo "[PRÉ-BUILD] Personnalisation du bootloader (logo + textes)..."
mkdir -p "$BUILD_DIR/config/bootloaders"
if [[ -d "/usr/share/live/build/bootloaders" ]]; then
  cp -r /usr/share/live/build/bootloaders/* "$BUILD_DIR/config/bootloaders/"
  echo "   ✓ Bootloaders par défaut copiés pour personnalisation"
fi

# Suppression de splash.svg pour forcer l'usage de splash.png
find "$BUILD_DIR/config/bootloaders" -name "splash.svg" -delete 2>/dev/null || true

# Génération du splash.png (640x480) avec le logo de l'utilisateur
if [[ -n "$LOGO_SRC" ]]; then
  echo "   ✓ Génération du splash.png de boot..."
  mkdir -p "$BUILD_DIR/config/bootloaders/isolinux"
  mkdir -p "$BUILD_DIR/config/bootloaders/syslinux"
  convert -size 640x480 xc:'#0a0a0f' \
    \( "$LOGO_SRC" -resize 140x140 \) -geometry +40+80 -composite \
    -font DejaVu-Sans-Bold -pointsize 32 -fill '#1a8cff' -draw "text 40,260 'SharkOS 🦈'" \
    -font DejaVu-Sans -pointsize 14 -fill '#4a9eff' -draw "text 40,290 'Rapide. Furtif. Létal.'" \
    "$BUILD_DIR/config/bootloaders/isolinux/splash.png" 2>/dev/null || true
  cp "$BUILD_DIR/config/bootloaders/isolinux/splash.png" "$BUILD_DIR/config/bootloaders/syslinux/splash.png" 2>/dev/null || true
fi

# Remplacement de "Debian" par "SharkOS" dans les menus de boot
if [[ -d "$BUILD_DIR/config/bootloaders" ]]; then
  find "$BUILD_DIR/config/bootloaders" -type f -exec sed -i 's/Debian GNU\/Linux/SharkOS/g' {} + 2>/dev/null || true
  find "$BUILD_DIR/config/bootloaders" -type f -exec sed -i 's/Debian/SharkOS/g' {} + 2>/dev/null || true
  echo "   ✓ Textes du bootloader mis à jour (Debian → SharkOS)"
fi

# Copie du .zshrc dans skel
mkdir -p "$BUILD_DIR/config/includes.chroot/etc/skel"
cp "$SHARK_DIR/config/.zshrc" \
   "$BUILD_DIR/config/includes.chroot/etc/skel/.zshrc"

# Copie des hooks chroot
mkdir -p "$BUILD_DIR/config/hooks/live"
for HOOK in "$SHARK_DIR/chroot-hooks"/*.sh; do
  HOOK_NAME=$(basename "$HOOK")
  cp "$HOOK" "$BUILD_DIR/config/hooks/live/${HOOK_NAME}"
  chmod +x "$BUILD_DIR/config/hooks/live/${HOOK_NAME}"
  echo "   ✓ Hook copié : $HOOK_NAME"
done

# Copie de l'assistant d'installation graphique (Style Apple)
echo "[PRÉ-BUILD] Copie de l'assistant d'installation graphique..."
mkdir -p "$BUILD_DIR/config/includes.chroot/usr/local/bin"
cp "$SHARK_DIR/config/sharkos-setup-wizard" \
   "$BUILD_DIR/config/includes.chroot/usr/local/bin/sharkos-setup-wizard"
chmod +x "$BUILD_DIR/config/includes.chroot/usr/local/bin/sharkos-setup-wizard"

cp "$SHARK_DIR/config/sharkos-autostart-setup" \
   "$BUILD_DIR/config/includes.chroot/usr/local/bin/sharkos-autostart-setup"
chmod +x "$BUILD_DIR/config/includes.chroot/usr/local/bin/sharkos-autostart-setup"

mkdir -p "$BUILD_DIR/config/includes.chroot/etc/skel/.config/autostart"
cp "$SHARK_DIR/config/sharkos-setup-wizard.desktop" \
   "$BUILD_DIR/config/includes.chroot/etc/skel/.config/autostart/sharkos-setup-wizard.desktop"

# =============================================================================
# LANCEMENT DE LA BUILD
# =============================================================================
echo ""
echo "[BUILD] Configuration live-build (miroir : $DEBIAN_MIRROR)..."
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
  echo "   → Pour tester en VM :"
  echo "     qemu-system-x86_64 -m 2G -cdrom $SHARK_DIR/$ISO_NAME -boot d"
  echo "============================================ 🦈"
else
  echo ""
  echo "[ERREUR] Aucune ISO trouvée. Consulte le log :"
  echo "  tail -50 $SHARK_DIR/sharkos-build.log"
  exit 1
fi
