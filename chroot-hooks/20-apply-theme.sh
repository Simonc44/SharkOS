#!/usr/bin/env bash
# =============================================================================
# SharkOS — 20-apply-theme.sh v4.0 (HyperOS-style)
# Thème : CLAIR HyperOS (WhiteSur-Light + Papirus-Light) — Dracula dispo en
# fallback / bascule (le choix clair/vibrant reproduit l'esthétique MIUI).
#  - Kvantum engine (thèmes Qt transparents)
#  - Plank glassmorphism clair
#  - GTK WhiteSur-Light (fallback Dracula)
#  - Curseurs Catppuccin-Latte
#  - Icônes Papirus-Light (fallback Dark)
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 20] Thème clair HyperOS (WhiteSur-Light + Papirus-Light)..."
echo ""

THEMES_SYSTEM="/usr/share/themes"
ICONS_SYSTEM="/usr/share/icons"
SKEL="/etc/skel"

mkdir -p "$THEMES_SYSTEM" "$ICONS_SYSTEM"
mkdir -p "$SKEL/.themes" "$SKEL/.icons"
mkdir -p "$SKEL/.local/share/icons" "$SKEL/.local/share/themes"
mkdir -p /usr/share/sharkos /usr/share/backgrounds/sharkos

# =============================================================================
# 1. THÈME GTK DRACULA (Garuda utilise des thèmes sombres violet/bleu)
# =============================================================================
echo "[1/6] GTK Dracula theme..."
if [[ ! -d "/tmp/Dracula-GTK" ]]; then
  git clone --depth=1 https://github.com/dracula/gtk.git /tmp/Dracula-GTK 2>/dev/null || true
fi
if [[ -d "/tmp/Dracula-GTK" ]]; then
  cp -r /tmp/Dracula-GTK "$THEMES_SYSTEM/Dracula" 2>/dev/null || true
  ln -sf "$THEMES_SYSTEM/Dracula" "$SKEL/.themes/Dracula" 2>/dev/null || true
fi

# WhiteSur-Light — thème clair HyperOS (par défaut, look MIUI lumineux)
if [[ ! -d "/tmp/WhiteSur-gtk-theme" ]]; then
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git \
    /tmp/WhiteSur-gtk-theme 2>/dev/null || true
fi
if [[ -d "/tmp/WhiteSur-gtk-theme" ]]; then
  cd /tmp/WhiteSur-gtk-theme
  bash install.sh --dest "$THEMES_SYSTEM" --color light --theme all 2>/dev/null || true
  # Sombres aussi dispo (bascule shark-theme light/dark)
  bash install.sh --dest "$THEMES_SYSTEM" --color dark --theme all 2>/dev/null || true
  cd /
fi

# Définir le thème clair par défaut (style HyperOS)
THEME_NAME="WhiteSur-Light"
if [[ ! -d "$THEMES_SYSTEM/$THEME_NAME" ]]; then
  THEME_NAME="Dracula"  # fallback sombre si l'install a échoué
fi
ln -sf "$THEMES_SYSTEM/$THEME_NAME" "$SKEL/.themes/$(basename "$THEME_NAME")" 2>/dev/null || true
echo "   ✓ Thème GTK : $THEME_NAME"

# =============================================================================
# 2. ICÔNES PAPIRUS (Light par défaut — look clair HyperOS)
# =============================================================================
echo "[2/6] Papirus icons (Light par défaut)..."
apt-get install -y --no-install-recommends \
  papirus-icon-theme 2>/dev/null || {

  # Fallback : install depuis GitHub
  if [[ ! -d "/tmp/papirus-icon-theme" ]]; then
    git clone --depth=1 https://github.com/PapirusDevelopmentTeam/papirus-icon-theme.git \
      /tmp/papirus-icon-theme 2>/dev/null || true
  fi
  if [[ -d "/tmp/papirus-icon-theme" ]]; then
    env DESTDIR="$ICONS_SYSTEM" bash /tmp/papirus-icon-theme/install.sh 2>/dev/null || true
  fi
}

# WhiteSur icons (fallback)
if [[ ! -d "/tmp/WhiteSur-icon-theme" ]]; then
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git \
    /tmp/WhiteSur-icon-theme 2>/dev/null || true
fi
if [[ -d "/tmp/WhiteSur-icon-theme" ]]; then
  cd /tmp/WhiteSur-icon-theme
  bash install.sh --dest "$ICONS_SYSTEM" 2>/dev/null || true
  cd /
fi

# Cache icônes
for ICON_DIR in "$ICONS_SYSTEM"/Papirus* "$ICONS_SYSTEM"/WhiteSur*; do
  [[ -d "$ICON_DIR" ]] && gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
done

# Par défaut : Papirus-Light (clair, type HyperOS) — Dark dispo via shark-theme
ln -sf "$ICONS_SYSTEM/Papirus-Light" "$SKEL/.icons/Papirus" 2>/dev/null || true

# =============================================================================
# 3. CURSEURS CATPPUCCIN-MOCHA (style Garuda)
# =============================================================================
echo "[3/6] Curseurs Catppuccin-Mocha..."
mkdir -p /tmp/catppuccin-cursors
curl -sL \
  "https://github.com/catppuccin/cursors/releases/download/v0.3.1/catppuccin-mocha-dark-cursors.zip" \
  -o /tmp/catppuccin-cursors.zip 2>/dev/null && \
  unzip -q /tmp/catppuccin-cursors.zip -d "$ICONS_SYSTEM/" 2>/dev/null || \
echo "   ⚠ Curseurs Catppuccin non téléchargés — utilise les curseurs Adwaita"

# =============================================================================
# 4. KVANTUM ENGINE (thèmes Qt transparents — signature Garuda)
# =============================================================================
echo "[4/6] Kvantum engine..."
# NB : qt5-style-kvantum est le seul paquet Debian (les thèmes sont inclus) ;
# "qt5-style-kvantum-themes" et "kvantum" n'existent pas dans les dépôts.
apt-get install -y --no-install-recommends \
  qt5-style-kvantum 2>/dev/null || \
echo "   ⚠ Kvantum non installé (paquet absent des dépôts)"

mkdir -p /etc/skel/.config/Kvantum

# Thème Kvantum SharkOS (glassmorphism bleu marine)
cat > /etc/skel/.config/Kvantum/kvantum.kvconfig << 'KVCONF'
[General]
theme=KvGnomeDark
KVCONF

# Thème personnalisé SharkOS
mkdir -p /usr/share/Kvantum/SharkDragon
cat > /usr/share/Kvantum/SharkDragon/SharkDragon.kvconfig << 'KVTHEME'
[%General]
author=SharkOS
description=SharkOS Dragon Theme (Garuda-inspired)

[GeneralColors]
window.color=#1a1b2e
base.color=#16213e
alt.base.color=#0f3460
button.color=#e94560
light.color=#2a2b4a
mid.light.color=#1a1b3a
dark.color=#0a0b1a
mid.color=#141528
highlight.color=#e94560
inactive.highlight.color=#3d3d6b
text.color=#eefaf8
window.text.color=#c8d8e8
button.text.color=#ffffff
disabled.text.color=#6c7a89
toolTip.base.color=#1a1b2e
toolTip.text.color=#eefaf8
link.color=#1a8cff
visited.link.color=#bf5af2
KVTHEME

# =============================================================================
# 5. PROPAGATION FLATPAK
# =============================================================================
echo "[5/6] Propagation thèmes Flatpak..."
flatpak override --filesystem="$THEMES_SYSTEM":ro 2>/dev/null || true
flatpak override --filesystem="$ICONS_SYSTEM":ro 2>/dev/null || true
flatpak override --env=GTK_THEME=WhiteSur-Light 2>/dev/null || true
flatpak override --env=ICON_THEME=Papirus-Light 2>/dev/null || true

grep -qxF 'GTK_THEME=WhiteSur-Light' /etc/environment 2>/dev/null || \
  echo 'GTK_THEME=WhiteSur-Light' >> /etc/environment

# =============================================================================
# 6. FOND D'ÉCRAN SHARKOS (style Garuda : gradient sombre violet/bleu)
# =============================================================================
echo "[6/6] Fond d'écran Dragon Shark..."

WALLPAPER_DEST="/usr/share/backgrounds/sharkos/sharkos.png"
mkdir -p "$(dirname $WALLPAPER_DEST)"

if [[ -f "/usr/share/sharkos/wallpaper.png" ]]; then
  cp /usr/share/sharkos/wallpaper.png "$WALLPAPER_DEST"
elif command -v convert &>/dev/null; then
  # Fond style HyperOS 6.0 — variante CLAIRE lumineuse (pastel bleu→violet)
  # signature MIUI : fond clair vibrant, doux, profond.
  convert -size 1920x1080 \
    gradient:'#e0eaff-#e9d5ff' \
    /tmp/bg_base.png 2>/dev/null && \
  convert -size 1920x1080 xc:none \
    -fill 'rgba(37,99,235,0.18)' -draw "circle 1300,300 1300,700" \
    /tmp/bg_glow.png 2>/dev/null && \
  convert -size 1920x1080 xc:none \
    -fill 'rgba(34,211,238,0.25)' -draw "circle 300,900 300,1300" \
    /tmp/bg_glow2.png 2>/dev/null && \
  convert -size 1920x1080 xc:none \
    -fill 'rgba(236,72,153,0.20)' -draw "circle 1600,950 1600,1350" \
    /tmp/bg_glow3.png 2>/dev/null && \
  convert /tmp/bg_base.png /tmp/bg_glow.png /tmp/bg_glow2.png /tmp/bg_glow3.png \
    -compose Screen -composite \
    -fill 'rgba(30,41,59,0.55)' -gravity center \
    -font DejaVu-Sans-Bold -pointsize 90 -annotate +0-60 '🦈' \
    "$WALLPAPER_DEST" 2>/dev/null || \
  convert -size 1920x1080 \
    gradient:'#e0eaff-#e9d5ff' \
    "$WALLPAPER_DEST" 2>/dev/null || true

  rm -f /tmp/bg_base.png /tmp/bg_glow.png /tmp/bg_glow2.png /tmp/bg_glow3.png
  echo "   ✓ Fond clair HyperOS généré (pastel bleu→violet + halos)"
fi

echo ""
echo "✅ [HOOK 20] Thème Dracula/Dragon + Papirus-Dark + Kvantum installés."
echo ""
