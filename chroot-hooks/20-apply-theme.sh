#!/usr/bin/env bash
# =============================================================================
# SharkOS — 20-apply-theme.sh — Liquid Glass Desktop
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 20] Application du thème Liquid Glass SharkOS..."
echo ""

THEMES_SYSTEM="/usr/share/themes"
ICONS_SYSTEM="/usr/share/icons"
SKEL="/etc/skel"
SHARKOS_ASSETS="/usr/share/sharkos"

mkdir -p "$THEMES_SYSTEM" "$ICONS_SYSTEM"
mkdir -p "$SKEL/.themes" "$SKEL/.icons"
mkdir -p "$SKEL/.local/share/icons" "$SKEL/.local/share/themes"

# =============================================================================
# 1. WHITESUR GTK THEME (base)
# =============================================================================
echo "[1/5] WhiteSur GTK Theme (base)..."
if [[ ! -d "/tmp/WhiteSur-gtk-theme" ]]; then
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git \
    /tmp/WhiteSur-gtk-theme
fi

cd /tmp/WhiteSur-gtk-theme
bash install.sh \
  --dest "$THEMES_SYSTEM" \
  --theme default \
  --color dark \
  --opacity normal \
  --no-superuser 2>/dev/null || \
bash install.sh --dest "$THEMES_SYSTEM" 2>/dev/null || true
cd /

# =============================================================================
# 2. LIQUID GLASS — Override CSS sur WhiteSur-Dark
#    GTK3 supporte les overrides via ~/.config/gtk-3.0/gtk.css
#    On le place dans /etc/skel pour tous les utilisateurs
# =============================================================================
echo "[2/5] Injection CSS Liquid Glass..."

mkdir -p "$SKEL/.config/gtk-3.0"

cat > "$SKEL/.config/gtk-3.0/gtk.css" << 'GLASSCSS'
/* ============================================================
   SharkOS — Liquid Glass Override GTK3
   Inspiré de visionOS / macOS Sequoia Liquid Glass
   ============================================================ */

/* ── Variables de couleurs ───────────────────────────────── */
@define-color glass_bg             rgba(18, 22, 40, 0.72);
@define-color glass_border_top     rgba(255, 255, 255, 0.22);
@define-color glass_border         rgba(255, 255, 255, 0.09);
@define-color glass_highlight      rgba(255, 255, 255, 0.12);
@define-color shark_blue           rgba(26, 140, 255, 1.0);
@define-color shark_blue_glow      rgba(26, 140, 255, 0.25);
@define-color shark_blue_dim       rgba(26, 140, 255, 0.12);
@define-color text_primary         rgba(240, 244, 255, 1.0);
@define-color text_secondary       rgba(180, 190, 220, 0.75);

/* ── Fenêtres ─────────────────────────────────────────────── */
window,
.background {
  background-color: rgba(10, 12, 24, 0.96);
  color: @text_primary;
}

/* ── Barres de titre (decoration) ───────────────────────────
   xfwm4 gère ça côté wm-theme, mais on renforce ici */
headerbar,
.titlebar {
  background: linear-gradient(
    180deg,
    rgba(30, 36, 60, 0.92) 0%,
    rgba(18, 22, 40, 0.88) 100%
  );
  border-bottom: 1px solid @glass_border_top;
  box-shadow:
    inset 0 1px 0 @glass_highlight,
    0 2px 12px rgba(0,0,0,0.40);
  color: @text_primary;
  padding: 6px 12px;
}

/* ── Menus (applications menu + clic droit) ─────────────── */
menu,
.menu,
menubar > menuitem > menu {
  background: @glass_bg;
  border: 1px solid @glass_border_top;
  border-radius: 14px;
  padding: 6px;
  box-shadow:
    inset 0 1px 0 @glass_highlight,
    0 20px 60px rgba(0, 0, 0, 0.70),
    0 4px 16px rgba(26, 140, 255, 0.10);
  color: @text_primary;
}

menuitem {
  border-radius: 10px;
  padding: 7px 14px;
  color: @text_primary;
  transition: background 120ms ease;
}

menuitem:hover,
menuitem:selected {
  background: linear-gradient(
    135deg,
    rgba(26, 140, 255, 0.22) 0%,
    rgba(26, 140, 255, 0.10) 100%
  );
  border-radius: 10px;
  color: #ffffff;
}

menuitem:disabled {
  color: @text_secondary;
  opacity: 0.5;
}

/* Séparateur dans les menus */
separator,
menuitem.separator {
  background: @glass_border_top;
  min-height: 1px;
  margin: 4px 8px;
  opacity: 0.6;
}

/* ── Boutons ─────────────────────────────────────────────── */
button {
  background: linear-gradient(
    180deg,
    rgba(255, 255, 255, 0.10) 0%,
    rgba(255, 255, 255, 0.04) 100%
  );
  border-radius: 10px;
  border-top: 1px solid rgba(255, 255, 255, 0.20);
  border-left: 1px solid rgba(255, 255, 255, 0.12);
  border-right: 1px solid rgba(0, 0, 0, 0.15);
  border-bottom: 1px solid rgba(0, 0, 0, 0.25);
  color: @text_primary;
  padding: 7px 16px;
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.12),
    0 2px 6px rgba(0,0,0,0.25);
  transition: all 120ms ease;
}

button:hover {
  background: linear-gradient(
    180deg,
    rgba(255, 255, 255, 0.16) 0%,
    rgba(255, 255, 255, 0.08) 100%
  );
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.18),
    0 3px 10px rgba(0,0,0,0.30);
}

button:active {
  background: rgba(0, 0, 0, 0.25);
  box-shadow: inset 0 2px 4px rgba(0,0,0,0.30);
}

/* Bouton suggéré (ex: OK, Enregistrer) */
button.suggested-action {
  background: linear-gradient(
    180deg,
    rgba(80, 170, 255, 0.95) 0%,
    rgba(26, 100, 220, 0.95) 100%
  );
  border-top-color: rgba(140, 200, 255, 0.50);
  color: #ffffff;
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.35),
    0 3px 14px rgba(26, 100, 220, 0.55);
}

button.suggested-action:hover {
  background: linear-gradient(
    180deg,
    rgba(100, 185, 255, 1.0) 0%,
    rgba(50, 120, 240, 1.0) 100%
  );
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.45),
    0 4px 20px rgba(26, 100, 220, 0.65);
}

/* Bouton destructeur (Supprimer, etc.) */
button.destructive-action {
  background: linear-gradient(
    180deg,
    rgba(255, 90, 90, 0.90) 0%,
    rgba(200, 40, 40, 0.90) 100%
  );
  border-top-color: rgba(255, 160, 160, 0.40);
  color: #ffffff;
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.25),
    0 3px 12px rgba(200, 40, 40, 0.50);
}

/* ── Champs de saisie ────────────────────────────────────── */
entry {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 10px;
  border-top: 1px solid rgba(255, 255, 255, 0.18);
  border-left: 1px solid rgba(255, 255, 255, 0.10);
  border-right: 1px solid rgba(0, 0, 0, 0.18);
  border-bottom: 1px solid rgba(0, 0, 0, 0.28);
  color: @text_primary;
  padding: 8px 12px;
  box-shadow: inset 0 2px 5px rgba(0,0,0,0.18);
  caret-color: @shark_blue;
  transition: all 150ms ease;
}

entry:focus {
  background: rgba(26, 140, 255, 0.07);
  border-top-color: rgba(26, 140, 255, 0.55);
  box-shadow:
    inset 0 2px 5px rgba(0,0,0,0.12),
    0 0 0 3px @shark_blue_dim,
    0 0 16px rgba(26,140,255,0.12);
}

entry selection {
  background: @shark_blue;
  color: #ffffff;
}

/* ── Barres de défilement ─────────────────────────────────── */
scrollbar trough {
  background: rgba(255, 255, 255, 0.04);
  border-radius: 100px;
  min-width: 6px;
  min-height: 6px;
}

scrollbar slider {
  background: rgba(255, 255, 255, 0.22);
  border-radius: 100px;
  min-width: 6px;
  min-height: 40px;
  transition: background 150ms ease;
}

scrollbar slider:hover {
  background: rgba(26, 140, 255, 0.55);
}

scrollbar slider:active {
  background: @shark_blue;
}

/* ── Panneaux / sidebars ─────────────────────────────────── */
.sidebar,
.view.sidebar {
  background: rgba(12, 15, 28, 0.85);
  border-right: 1px solid @glass_border_top;
}

/* ── Onglets (notebooks) ──────────────────────────────────── */
notebook > header {
  background: @glass_bg;
  border-bottom: 1px solid @glass_border_top;
}

notebook > header tab {
  background: transparent;
  border-radius: 8px 8px 0 0;
  padding: 7px 18px;
  color: @text_secondary;
  transition: all 150ms ease;
}

notebook > header tab:checked {
  background: linear-gradient(
    180deg,
    rgba(255,255,255,0.10) 0%,
    rgba(255,255,255,0.04) 100%
  );
  border-top: 1px solid @glass_border_top;
  color: @text_primary;
}

/* ── Dialogues / popups ──────────────────────────────────── */
dialog > .dialog-vbox,
.messagedialog {
  background: rgba(14, 18, 34, 0.94);
  border: 1px solid @glass_border_top;
  border-radius: 18px;
  box-shadow:
    inset 0 1px 0 @glass_highlight,
    0 32px 80px rgba(0,0,0,0.75),
    0 4px 20px rgba(26,140,255,0.10);
}

/* ── Tooltips ────────────────────────────────────────────── */
tooltip {
  background: rgba(20, 24, 44, 0.90);
  border: 1px solid @glass_border_top;
  border-radius: 10px;
  color: @text_primary;
  padding: 6px 12px;
  box-shadow:
    inset 0 1px 0 @glass_highlight,
    0 8px 24px rgba(0,0,0,0.50);
}

/* ── Checkboxes & Radios ─────────────────────────────────── */
checkbutton check,
radiobutton radio {
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.20);
  border-radius: 5px;
  transition: all 150ms ease;
}

checkbutton check:checked,
radiobutton radio:checked {
  background: @shark_blue;
  border-color: rgba(26, 140, 255, 0.80);
  box-shadow: 0 0 8px @shark_blue_glow;
}

/* ── Switches (toggles) ──────────────────────────────────── */
switch {
  background: rgba(255, 255, 255, 0.10);
  border-radius: 100px;
  border: 1px solid rgba(255, 255, 255, 0.15);
  transition: all 200ms ease;
}

switch:checked {
  background: @shark_blue;
  border-color: rgba(26, 140, 255, 0.60);
  box-shadow: 0 0 12px @shark_blue_glow;
}

switch slider {
  background: #ffffff;
  border-radius: 100px;
  box-shadow: 0 2px 6px rgba(0,0,0,0.35);
}

/* ── Barres de progression ───────────────────────────────── */
progressbar trough {
  background: rgba(255, 255, 255, 0.07);
  border-radius: 100px;
  min-height: 6px;
}

progressbar progress {
  background: linear-gradient(90deg, @shark_blue 0%, rgba(80, 220, 255, 1.0) 100%);
  border-radius: 100px;
  min-height: 6px;
  box-shadow: 0 0 10px @shark_blue_glow;
}

/* ── Sélection de texte ──────────────────────────────────── */
selection {
  background: @shark_blue;
  color: #ffffff;
}

/* ── Listes / treeview ───────────────────────────────────── */
treeview,
.view {
  background: rgba(10, 13, 26, 0.75);
  color: @text_primary;
  border-radius: 12px;
}

treeview:selected,
.view:selected {
  background: @shark_blue_dim;
  color: #ffffff;
  border-radius: 8px;
}

row:hover {
  background: rgba(255, 255, 255, 0.04);
}

/* ── Popover (menus contextuels modernes) ────────────────── */
popover {
  background: @glass_bg;
  border: 1px solid @glass_border_top;
  border-radius: 14px;
  padding: 6px;
  box-shadow:
    inset 0 1px 0 @glass_highlight,
    0 20px 60px rgba(0,0,0,0.65),
    0 4px 16px @shark_blue_dim;
}

/* ── Notifications (xfce4-notifyd) ──────────────────────── */
.notification {
  background: @glass_bg;
  border: 1px solid @glass_border_top;
  border-radius: 16px;
  box-shadow:
    inset 0 1px 0 @glass_highlight,
    0 12px 40px rgba(0,0,0,0.65);
  color: @text_primary;
  padding: 14px;
}

GLASSCSS

# Copier aussi pour GTK2 (applications legacy)
mkdir -p "$SKEL/.config/gtk-2.0"
cat > "$SKEL/.gtkrc-2.0" << 'GTK2RC'
gtk-theme-name="WhiteSur-Dark"
gtk-icon-theme-name="WhiteSur"
gtk-font-name="Sans 10"
gtk-cursor-theme-name="WhiteSur-cursors"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_SMALL_TOOLBAR
gtk-button-images=0
gtk-menu-images=1
GTK2RC

# =============================================================================
# 3. WHITESUR ICON THEME
# =============================================================================
echo "[3/5] WhiteSur Icons..."
if [[ ! -d "/tmp/WhiteSur-icon-theme" ]]; then
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git \
    /tmp/WhiteSur-icon-theme
fi

cd /tmp/WhiteSur-icon-theme
bash install.sh --dest "$ICONS_SYSTEM" --bold 2>/dev/null || \
bash install.sh --dest "$ICONS_SYSTEM" 2>/dev/null || true

for ICON_DIR in "$ICONS_SYSTEM"/WhiteSur*; do
  [[ -d "$ICON_DIR" ]] && gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
done
cd /

# =============================================================================
# 4. PROPAGATION Snap / Flatpak
# =============================================================================
echo "[4/5] Propagation Snap / Flatpak..."

for THEME_DIR in "$THEMES_SYSTEM"/WhiteSur*; do
  THEME_NAME=$(basename "$THEME_DIR")
  [[ -d "$THEME_DIR" ]] && \
    ln -sf "$THEME_DIR" "$SKEL/.themes/$THEME_NAME" 2>/dev/null || true && \
    ln -sf "$THEME_DIR" "$SKEL/.local/share/themes/$THEME_NAME" 2>/dev/null || true
done

for ICON_DIR in "$ICONS_SYSTEM"/WhiteSur*; do
  ICON_NAME=$(basename "$ICON_DIR")
  [[ -d "$ICON_DIR" ]] && \
    ln -sf "$ICON_DIR" "$SKEL/.icons/$ICON_NAME" 2>/dev/null || true && \
    ln -sf "$ICON_DIR" "$SKEL/.local/share/icons/$ICON_NAME" 2>/dev/null || true
done

flatpak override --filesystem="$THEMES_SYSTEM":ro 2>/dev/null || true
flatpak override --filesystem="$ICONS_SYSTEM":ro 2>/dev/null || true
flatpak override --env=GTK_THEME=WhiteSur-Dark 2>/dev/null || true
flatpak override --env=ICON_THEME=WhiteSur 2>/dev/null || true

grep -qxF 'GTK_THEME=WhiteSur-Dark' /etc/environment 2>/dev/null || \
  echo 'GTK_THEME=WhiteSur-Dark' >> /etc/environment

# =============================================================================
# 5. FOND D'ÉCRAN
# =============================================================================
echo "[5/5] Fond d'écran Liquid Glass SharkOS..."

mkdir -p /usr/share/sharkos /usr/share/backgrounds/sharkos

WALLPAPER_DEST="/usr/share/sharkos/wallpaper.png"
WALLPAPER_SRC="$SHARKOS_ASSETS/wallpaper.png"

if [[ -f "$WALLPAPER_SRC" ]]; then
  cp "$WALLPAPER_SRC" "$WALLPAPER_DEST"
  echo "   ✓ Fond d'écran copié."
else
  # Génère un fond Liquid Glass profond via ImageMagick
  apt-get install -y --no-install-recommends imagemagick 2>/dev/null || true
  if command -v convert &>/dev/null; then
    convert \
      -size 1920x1080 \
      # Dégradé profond bleu nuit → noir
      gradient:'#040812-#0a1428' \
      # Halo bleu central (lumière Liquid Glass)
      \( -size 1920x1080 xc:none \
         -fill 'radial-gradient:rgba(26,140,255,0.15)-rgba(0,0,0,0)' \
         -draw "circle 960,540 960,240" \) \
      -composite \
      "$WALLPAPER_DEST" 2>/dev/null || \
    convert \
      -size 1920x1080 \
      gradient:'#040812-#050a1e' \
      "$WALLPAPER_DEST" 2>/dev/null || true
    echo "   ✓ Fond généré."
  fi
fi

cp "$WALLPAPER_DEST" /usr/share/backgrounds/sharkos/sharkos.png 2>/dev/null || true

# Config XFCE desktop
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
  <!-- Icônes bureau : désactivées pour un look épuré -->
  <property name="desktop-icons" type="empty">
    <property name="style" type="int" value="0"/>
  </property>
</channel>
XFDESKTOP

# Installer xfce4-notifyd pour les notifications stylées
apt-get install -y --no-install-recommends xfce4-notifyd 2>/dev/null || true

# Theme pour les notifications (glass)
mkdir -p /usr/share/xfce4-notifyd/themes/SharkOS-Glass
cat > /usr/share/xfce4-notifyd/themes/SharkOS-Glass/gtk.css << 'NOTIFYCSS'
#XfceNotifyWindow {
  background: rgba(14, 18, 36, 0.88);
  border: 1px solid rgba(255, 255, 255, 0.18);
  border-radius: 16px;
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.15),
    0 20px 60px rgba(0, 0, 0, 0.70),
    0 4px 16px rgba(26, 140, 255, 0.12);
  padding: 16px;
  color: rgba(240, 244, 255, 0.95);
  font-family: "SF Pro Display", "Helvetica Neue", Helvetica, Sans;
  font-size: 13px;
}

#XfceNotifyWindow .summary {
  font-weight: bold;
  font-size: 14px;
  color: rgba(255, 255, 255, 0.98);
}

#XfceNotifyWindow .body {
  color: rgba(180, 190, 220, 0.80);
}

#XfceNotifyWindow .close-button {
  background: rgba(255, 255, 255, 0.08);
  border-radius: 50%;
  border: 1px solid rgba(255,255,255,0.12);
  color: rgba(200, 210, 240, 0.70);
  min-width: 22px;
  min-height: 22px;
}

#XfceNotifyWindow .close-button:hover {
  background: rgba(255, 90, 90, 0.75);
  color: #ffffff;
}
NOTIFYCSS

echo ""
echo "✅ [HOOK 20] Liquid Glass appliqué."
echo ""
