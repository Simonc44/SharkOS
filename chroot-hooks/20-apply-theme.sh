#!/usr/bin/env bash
# =============================================================================
# SharkOS — 20-apply-theme.sh (CHROOT HOOK)
# Installe WhiteSur GTK + WhiteSur Icons (depuis GitHub officiel)
# Applique les thèmes pour GTK, Snap, Flatpak (~/.themes, ~/.icons)
# Fond d'écran SharkOS (PNG uniquement)
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 20] Application du thème WhiteSur (macOS Style)..."
echo ""

THEMES_SYSTEM="/usr/share/themes"
ICONS_SYSTEM="/usr/share/icons"
SKEL="/etc/skel"
SHARKOS_ASSETS="/usr/share/sharkos"

mkdir -p "$THEMES_SYSTEM" "$ICONS_SYSTEM"
mkdir -p "$SKEL/.themes" "$SKEL/.icons"
mkdir -p "$SKEL/.local/share/icons"
mkdir -p "$SKEL/.local/share/themes"

# =============================================================================
# 1. WHITESUR GTK THEME (depuis GitHub vinceliuice)
# =============================================================================
echo "[1/4] Clonage WhiteSur GTK Theme..."
if [[ ! -d "/tmp/WhiteSur-gtk-theme" ]]; then
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git \
    /tmp/WhiteSur-gtk-theme
fi

cd /tmp/WhiteSur-gtk-theme

# Installer les variantes Dark + Light dans les thèmes système
bash install.sh \
  --dest "$THEMES_SYSTEM" \
  --theme default \
  --color dark light \
  --opacity normal \
  --nautilus-style stable \
  --no-superuser 2>/dev/null || \
bash install.sh \
  --dest "$THEMES_SYSTEM" \
  --color dark \
  --no-superuser 2>/dev/null || \
bash install.sh --dest "$THEMES_SYSTEM" 2>/dev/null || true

cd /

# =============================================================================
# 2. WHITESUR ICON THEME (depuis GitHub officiel)
# =============================================================================
echo "[2/4] Clonage WhiteSur Icon Theme..."
if [[ ! -d "/tmp/WhiteSur-icon-theme" ]]; then
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git \
    /tmp/WhiteSur-icon-theme
fi

cd /tmp/WhiteSur-icon-theme

# Installer les icônes (dark + alternatives)
bash install.sh \
  --dest "$ICONS_SYSTEM" \
  --theme default \
  --bold 2>/dev/null || \
bash install.sh --dest "$ICONS_SYSTEM" 2>/dev/null || true

# Mettre à jour le cache des icônes
for ICON_DIR in "$ICONS_SYSTEM"/WhiteSur*; do
  [[ -d "$ICON_DIR" ]] && gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
done

cd /

# =============================================================================
# 3. PROPAGATION VERS SNAP / FLATPAK (~/.themes et ~/.icons dans skel)
# =============================================================================
echo "[3/4] Propagation thèmes → Snap / Flatpak..."

# Créer des liens symboliques dans skel pour que chaque utilisateur hérite
# des thèmes dans son home (nécessaire pour Snap et Flatpak)
for THEME_DIR in "$THEMES_SYSTEM"/WhiteSur*; do
  THEME_NAME=$(basename "$THEME_DIR")
  if [[ -d "$THEME_DIR" ]]; then
    # Lien dans skel (sera copié dans ~/ de chaque nouvel utilisateur)
    ln -sf "$THEME_DIR" "$SKEL/.themes/$THEME_NAME" 2>/dev/null || true
    ln -sf "$THEME_DIR" "$SKEL/.local/share/themes/$THEME_NAME" 2>/dev/null || true
  fi
done

for ICON_DIR in "$ICONS_SYSTEM"/WhiteSur*; do
  ICON_NAME=$(basename "$ICON_DIR")
  if [[ -d "$ICON_DIR" ]]; then
    ln -sf "$ICON_DIR" "$SKEL/.icons/$ICON_NAME" 2>/dev/null || true
    ln -sf "$ICON_DIR" "$SKEL/.local/share/icons/$ICON_NAME" 2>/dev/null || true
  fi
done

# Accès Flatpak aux thèmes GTK système
flatpak override --filesystem="$THEMES_SYSTEM":ro 2>/dev/null || true
flatpak override --filesystem="$ICONS_SYSTEM":ro 2>/dev/null || true
flatpak override --env=GTK_THEME=WhiteSur-Dark 2>/dev/null || true
flatpak override --env=ICON_THEME=WhiteSur 2>/dev/null || true

# Variable Snap (via /etc/environment)
grep -qxF 'GTK_THEME=WhiteSur-Dark' /etc/environment 2>/dev/null || \
  echo 'GTK_THEME=WhiteSur-Dark' >> /etc/environment

# =============================================================================
# 4. FOND D'ÉCRAN SHARKOS (PNG uniquement)
# =============================================================================
echo "[4/4] Configuration du fond d'écran SharkOS (PNG)..."

WALLPAPER_DEST="/usr/share/sharkos/wallpaper.png"
WALLPAPER_SRC="$SHARKOS_ASSETS/wallpaper.png"

mkdir -p /usr/share/sharkos

# Vérifier si le fond d'écran PNG a été copié par le bootstrap
if [[ -f "$WALLPAPER_SRC" ]]; then
  cp "$WALLPAPER_SRC" "$WALLPAPER_DEST"
  echo "   ✓ Fond d'écran PNG copié."
else
  # Fallback : générer un fond d'écran PNG avec ImageMagick (noir avec logo texte)
  apt-get install -y --no-install-recommends imagemagick 2>/dev/null || true
  if command -v convert &>/dev/null; then
    convert \
      -size 1920x1080 \
      xc:'#0a0a0f' \
      -font DejaVu-Sans-Bold \
      -pointsize 96 \
      -fill '#1a8cff' \
      -gravity center \
      -annotate +0-60 '🦈' \
      -pointsize 42 \
      -fill '#ffffff' \
      -annotate +0+40 'SharkOS' \
      -pointsize 18 \
      -fill '#4a9eff' \
      -annotate +0+100 'Rapide. Furtif. Létal.' \
      "$WALLPAPER_DEST" 2>/dev/null || true
    echo "   ✓ Fond d'écran PNG généré par ImageMagick."
  else
    echo "   ⚠ Fond d'écran non disponible — place wallpaper.png dans wallpapers/"
  fi
fi

# Répertoire wallpapers système
mkdir -p /usr/share/backgrounds/sharkos
[[ -f "$WALLPAPER_DEST" ]] && cp "$WALLPAPER_DEST" /usr/share/backgrounds/sharkos/sharkos.png

# Config XFCE pour utiliser ce fond d'écran (via xfconf / skel)
mkdir -p "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml"
cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'XFDESKTOP'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorVirtual1" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="image-path" type="string" value="/usr/share/backgrounds/sharkos/sharkos.png"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/sharkos/sharkos.png"/>
        </property>
      </property>
    </property>
  </property>
</channel>
XFDESKTOP

echo ""
echo "✅ [HOOK 20] Thème WhiteSur + fond d'écran appliqués."
echo ""
