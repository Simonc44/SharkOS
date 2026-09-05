#!/usr/bin/env bash
# =============================================================================
# SharkOS — 00-bootstrap.sh v3.0 (Garuda-style)
# Prépare l'environnement live-build avec config Garuda-inspirée
# =============================================================================
set -euo pipefail

# =============================================================================
# RACINE DU PROJET — ABSOLUE, calculée AVANT tout `cd`.
# ⚠️ CRITIQUE : « $(dirname "$0")/.. » est un chemin RELATIF — il se résout
# contre le cwd courant. Le script fait `cd iso-build` en section 2, donc tout
# usage postérieur de ROOT_DIR pointait dans iso-build/scripts/.. (inexistant)
# → les hooks n'ont JAMAIS été copiés, ni wallpapers/installer/Calamares
# shipés (les « if [[ -f "$ROOT_DIR/..." ]] » échouaient en silence).
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
LB_DIR="$ROOT_DIR/iso-build"
cd "$LB_DIR"

lb clean 2>/dev/null || true

# =============================================================================
# 3. CONFIG LIVE-BUILD (Garuda-inspired : zstd, firmware, non-free)
# =============================================================================
echo "[3/6] Config live-build Garuda-style..."
# NB CRITIQUE : live-build d'Ubuntu (runner CI 22.04) a des défauts Ubuntu
# qui n'existent PAS dans Debian → erreurs "Unable to locate package"
# (linux-generic, casper, live-config-upstart…). On FORCE les valeurs Debian :
#   • kernel    : --linux-packages linux-image + flavour amd64  (=linux-image-amd64)
#   • initramfs : --initramfs live-boot (sinon casper d'Ubuntu)
#   • initsystem: --initsystem systemd (sinon upstart + live-config-upstart)
# La CONCATÉNATION paquet+flavour de live-build donne "linux-image"+"amd64"
# = linux-image-amd64 (NE PAS écrire linux-image-amd64 → -amd64-amd64).
# NB : l'option s'appelle --initramfs et NON --linux-initramfs (lb config
# Ubuntu : "unrecognized option").
# MODE : on GARDE le mode par défaut (ubuntu sur le runner) car il génère la
# bonne suite sécurité "<distro>-security" — le mode debian génère l'ancien
# "<distro>/updates" qui 404 sur security.debian.org depuis bookworm !
# En revanche on PIN explicitement tout ce que le mode ubuntu défaut mal :
#   • bootloader : --bootloader grub2 — le boot isolinux de l'ISO échouait avec
#     « Failed to load ldlinux.c32 » (SYSLINUX 6.04) selon le matériel et la
#     méthode de flash (Ventoy, Rufus ISO mode, contrôleurs USB) — problème
#     classique d'isolinux. GRUB2 lit l'ISO9660 nativement (image El Torito
#     grub_eltorito construite par lb_binary_iso via grub-mkimage DANS le
#     chroot → grub-pc requis en paquet) + isohybrid conservé → compatible
#     Ventoy/dd/Rufus-DD/VM.
#   • thème syslinux : --syslinux-theme live-build (sinon syslinux-themes-
#     ubuntu-oneiric + gfxboot-theme-ubuntu, inexistants dans Debian ; le thème
#     "live-build" est rendu depuis les templates via librsvg2-bin du chroot)
#   • kernel/initramfs/initsystem/firmware : épinglés plus bas.
# NB : AUCUN commentaire à l'intérieur de la continuation backslash ci-dessous
# — un `#` en début de mot au milieu d'une commande continuée avale la fin de
# la commande (bug v3.0.18, hang QEMU ; ici `--bootloader` deviendrait une
# commande orpheline → « command not found »).
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
  --bootloader grub2 \
  --syslinux-theme "live-build" \
  --linux-packages "linux-image" \
  --linux-flavours "amd64" \
  --initramfs "live-boot" \
  --initsystem "systemd" \
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
# xserver-xorg : REQUIS pour tout affichage graphique. xfce4/lightdm ne
# dépendent que des libs X — PAS du serveur — et avec --apt-recommends
# false rien ne le tire implicitement → ISO sans X → LightDM ne peut pas
# démarrer → cible graphique jamais atteinte au boot (test système ✗).
# Tire xserver-xorg-core + video-all + input-all (drivers toutes marques).
xserver-xorg
pulseaudio
pulseaudio-utils
pavucontrol

# ── Sudo (--apt-recommends false → pas de sudo sans liste explicite) ──
# Requis par le hook 50 (user shark + sudo NOPASSWD) et les commandes shark-*
sudo

# ── Bootloader GRUB2 (BIOS) ────────────────────────────────────────
# grub-pc : REQUIS à l'étape BINAIRE — avec --bootloader grub2, lb_binary_iso
# génère l'image El Torito « boot/grub/grub_eltorito » (cdboot.img + core.img
# grub-mkimage) DANS le chroot (binary.sh). Sans grub-pc → aucune image de
# boot BIOS → ISO non bootable. Remplace isolinux (échec « Failed to load
# ldlinux.c32 » selon matériel/méthode) : GRUB lit l'ISO9660 directement.
grub-pc

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

# ── Wi-Fi complet (NetworkManager + wpa_supplicant + outils) ──────
# wpasupplicant : REQUIS par NetworkManager pour le WPA2/WPA3 — avec
# --apt-recommends false il n'est PAS tiré automatiquement (le test système
# réel le vérifie : usr/sbin/wpa_supplicant doit exister dans l'ISO).
wpasupplicant
iw

# ── Sécurité ───────────────────────────────────────────────────────
# ufw + apparmor : installés ICI (phase package-lists, sources à jour) et
# PAS seulement par le hook 40 (apt-cache/install en hook a échoué
# silencieusement → ISO sans AppArmor). Le hook 40 active ensuite les
# services (systemctl enable).
ufw
apparmor
apparmor-utils

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
# ⚠️ Hooks PLATS dans config/hooks/ (PAS de sous-dossier) : live-build ne les
# découvre que via le glob non récursif « config/hooks/*.chroot » — un
# sous-dossier config/hooks/live/ rendait tous les hooks invisibles.
rm -rf config/hooks
mkdir -p config/hooks

for HOOK in \
  "$ROOT_DIR/chroot-hooks/10-install-tools.sh" \
  "$ROOT_DIR/chroot-hooks/12-syslinux-compat.sh" \
  "$ROOT_DIR/chroot-hooks/20-apply-theme.sh" \
  "$ROOT_DIR/chroot-hooks/30-configure-shell.sh" \
  "$ROOT_DIR/chroot-hooks/40-cleanup.sh" \
  "$ROOT_DIR/chroot-hooks/50-sharkos-finalize.sh" \
  "$ROOT_DIR/chroot-hooks/60-sharkos-polish.sh"; do
  if [[ -f "$HOOK" ]]; then
    DEST="config/hooks/$(basename $HOOK .sh).hook.chroot"
    cp "$HOOK" "$DEST"
    chmod +x "$DEST"
    echo "   ✓ $(basename $HOOK)"
  fi
done

# Vérification : le glob live-build « config/hooks/*.chroot » doit matcher
# (pipefail-safe : ls sans match exit 2 → || true + défaut 0)
HOOKS_ON_DISK=$(ls config/hooks/*.hook.chroot 2>/dev/null | wc -l) || true
echo "   → hooks .hook.chroot dans config/hooks : ${HOOKS_ON_DISK:-0}"
if [[ "${HOOKS_ON_DISK:-0}" -lt 7 ]]; then
  echo "   ❌ Copie des hooks incomplète — vérifie chroot-hooks/"
  exit 1
fi

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
echo "✅ Bootstrap terminé ! Hooks copiés : 10 → 12 → 20 → 30 → 40 → 50 → 60"
echo "   Artifact final : SharkOS-Dragon-Edition.iso"
echo "   sudo bash scripts/01-build-iso.sh"
echo ""
