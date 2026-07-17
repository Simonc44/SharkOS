#!/usr/bin/env bash
# =============================================================================
# SharkOS — 30-configure-shell.sh — Liquid Glass Desktop
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 30] Configuration bureau Liquid Glass SharkOS..."
echo ""

SKEL="/etc/skel"
mkdir -p "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml"

# =============================================================================
# 1. PANEL XFCE — Barre menubar Liquid Glass
# =============================================================================
echo "[1/6] Panel XFCE Liquid Glass..."

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="empty">
    <!-- Haut, pleine largeur, 30px — compact macOS -->
    <property name="position"        type="string" value="p=6;x=0;y=0"/>
    <property name="position-locked" type="bool"   value="true"/>
    <property name="length"          type="uint"   value="100"/>
    <property name="length-adjust"   type="bool"   value="true"/>
    <property name="size"            type="uint"   value="30"/>
    <property name="span-monitors"   type="bool"   value="false"/>
    <!-- Liquid Glass : sombre + quasi-transparent -->
    <property name="background-style" type="uint"  value="2"/>
    <property name="background-rgba"  type="array">
      <value type="double" value="0.06"/>   <!-- R -->
      <value type="double" value="0.07"/>   <!-- G -->
      <value type="double" value="0.14"/>   <!-- B -->
      <value type="double" value="0.82"/>   <!-- A -->
    </property>
    <property name="autohide-behavior" type="uint" value="0"/>
    <property name="mode"              type="uint" value="0"/>
    <property name="plugin-ids" type="array">
      <value type="int" value="1"/>
      <value type="int" value="2"/>
      <value type="int" value="3"/>
      <value type="int" value="4"/>
      <value type="int" value="5"/>
      <value type="int" value="6"/>
      <value type="int" value="7"/>
      <value type="int" value="8"/>
    </property>
  </property>

  <property name="plugins" type="empty">

    <!-- 🦈 Bouton SharkOS (menu applications) -->
    <property name="plugin-1" type="string" value="applicationsmenu">
      <property name="show-button-title" type="bool"   value="true"/>
      <property name="button-title"      type="string" value="🦈"/>
      <property name="show-tooltip"      type="bool"   value="false"/>
      <property name="show-generic-names" type="bool"  value="false"/>
      <property name="show-menu-icons"   type="bool"   value="true"/>
    </property>

    <!-- Séparateur fin -->
    <property name="plugin-2" type="string" value="separator">
      <property name="expand" type="bool" value="false"/>
      <property name="style"  type="uint" value="1"/>
    </property>

    <!-- Tâches ouvertes (flat, sans label pour compacité) -->
    <property name="plugin-3" type="string" value="tasklist">
      <property name="show-labels"            type="bool" value="true"/>
      <property name="show-only-minimized"    type="bool" value="false"/>
      <property name="include-all-workspaces" type="bool" value="false"/>
      <property name="flat-buttons"           type="bool" value="true"/>
      <property name="grouping"               type="uint" value="1"/>
      <property name="middle-click"           type="uint" value="0"/>
    </property>

    <!-- Séparateur extensible → pousse tout à droite -->
    <property name="plugin-4" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style"  type="uint" value="0"/>
    </property>

    <!-- Systray (icônes de notification) -->
    <property name="plugin-5" type="string" value="systray">
      <property name="size-max"   type="uint" value="20"/>
      <property name="show-frame" type="bool" value="false"/>
    </property>

    <!-- Volume PulseAudio -->
    <property name="plugin-6" type="string" value="pulseaudio">
      <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
      <property name="show-notifications"        type="bool" value="true"/>
    </property>

    <!-- Séparateur fin -->
    <property name="plugin-7" type="string" value="separator">
      <property name="expand" type="bool" value="false"/>
      <property name="style"  type="uint" value="1"/>
    </property>

    <!-- Horloge style macOS -->
    <property name="plugin-8" type="string" value="clock">
      <property name="mode"           type="uint"   value="2"/>
      <property name="digital-format" type="string" value="  %H:%M  ·  %a %d %b  "/>
      <property name="tooltip-format" type="string" value="%A %d %B %Y — %H:%M:%S"/>
    </property>

  </property>
</channel>
EOF

# =============================================================================
# 2. XFWM4 — Gestionnaire de fenêtres Liquid Glass
#    WhiteSur-Dark + coins arrondis + ombres douces
# =============================================================================
echo "[2/6] Gestionnaire de fenêtres xfwm4..."

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <!-- Thème WM (barres de titre) -->
    <property name="theme"             type="string" value="WhiteSur-Dark"/>
    <property name="title_font"        type="string" value="Helvetica Neue Bold 10"/>

    <!-- Boutons : macOS order (fermer, minifier, maximiser à gauche) -->
    <property name="button_layout"     type="string" value="CMH|O"/>

    <!-- Ombres Liquid Glass : diffuses et profondes -->
    <property name="show_dock_shadow"  type="bool"   value="false"/>
    <property name="show_frame_shadow" type="bool"   value="true"/>
    <property name="frame_opacity"     type="int"    value="88"/>

    <!-- Opacité des fenêtres inactives (effet depth) -->
    <property name="inactive_opacity"  type="int"    value="92"/>
    <property name="move_opacity"      type="int"    value="85"/>

    <!-- Animations -->
    <property name="use_compositing"   type="bool"   value="true"/>
    <property name="cycle_preview"     type="bool"   value="true"/>

    <!-- Placement -->
    <property name="placement_mode"    type="string" value="center"/>

    <!-- Double clic titre → max -->
    <property name="titlebar_dbl_click_action" type="string" value="maximize"/>

    <!-- Snap des fenêtres aux bords -->
    <property name="snap_to_border"    type="bool"   value="true"/>
    <property name="snap_to_windows"   type="bool"   value="true"/>
    <property name="snap_width"        type="int"    value="10"/>
  </property>
</channel>
EOF

# =============================================================================
# 3. XSETTINGS — Thème GTK + Fonts + Curseurs
# =============================================================================
echo "[3/6] XSettings (GTK theme, fonts, curseurs)..."

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName"      type="string" value="WhiteSur-Dark"/>
    <property name="IconThemeName"  type="string" value="WhiteSur"/>
    <property name="SoundThemeName" type="string" value="default"/>
  </property>
  <property name="Gtk" type="empty">
    <!-- Boutons de fenêtre côté gauche (macOS) -->
    <property name="DecorationLayout"    type="string" value="close,minimize,maximize:menu"/>
    <!-- Police système — SF Pro feel avec Inter -->
    <property name="FontName"            type="string" value="Inter 10"/>
    <property name="MonospaceFontName"   type="string" value="JetBrains Mono 10"/>
    <!-- Curseurs WhiteSur -->
    <property name="CursorThemeName"     type="string" value="WhiteSur-cursors"/>
    <property name="CursorThemeSize"     type="int"    value="24"/>
    <!-- Lissage des polices -->
    <property name="FontAntialias"       type="int"    value="1"/>
    <property name="FontHinting"         type="int"    value="1"/>
    <property name="FontHintStyle"       type="string" value="hintslight"/>
    <property name="FontRGBAOrder"       type="string" value="rgb"/>
    <!-- Animations réduites -->
    <property name="EnableAnimations"    type="bool"   value="true"/>
  </property>
</channel>
EOF

# Installer Inter + JetBrains Mono pour le look Apple/dev
apt-get install -y --no-install-recommends \
  fonts-inter 2>/dev/null || true
apt-get install -y --no-install-recommends \
  fonts-jetbrains-mono 2>/dev/null || true

# =============================================================================
# 4. PLANK DOCK — Liquid Glass
# =============================================================================
echo "[4/6] Plank Dock Liquid Glass..."

mkdir -p "$SKEL/.config/plank/dock1/launchers"

# Thème Plank custom Liquid Glass
mkdir -p /usr/share/plank/themes/SharkOS
cat > /usr/share/plank/themes/SharkOS/dock.theme << 'PLANKTHEME'
[PlankTheme]
TopRoundness=6
BottomRoundness=0
LineWidth=1
OuterStrokeColor=rgba(255,255,255,0.14)
FillStartColor=rgba(14,18,36,0.72)
FillEndColor=rgba(8,10,22,0.82)
InnerStrokeColor=rgba(255,255,255,0.10)
BadgeColor=rgba(26,140,255,0.85)
PLANKTHEME

cat > "$SKEL/.config/plank/dock1/settings" << 'EOF'
[PlankDockPreferences]
# Position bas, centré
Position=3
Alignment=3
# Icônes 52px — plus visible que macOS standard
IconSize=52
# Zoom 145% au survol
ZoomEnabled=true
ZoomPercent=145
# Intellihide : se cache quand une fenêtre passe devant
HideMode=3
UnhideDelay=0
HideDelay=250
# Thème custom SharkOS Liquid Glass
Theme=SharkOS
# Petit offset depuis le bas
Offset=4
Monitor=
LockItems=false
EOF

# Création des .dockitem avec fallback multi-noms
create_dockitem() {
  local ITEM_NAME="$1"; shift
  local CANDIDATES=("$@")
  local DIRS=("/usr/share/applications" "/usr/local/share/applications")
  for DIR in "${DIRS[@]}"; do
    for CAND in "${CANDIDATES[@]}"; do
      if [[ -f "$DIR/$CAND" ]]; then
        printf '[PlankDockItemPreferences]\nLauncher=file://%s\n' "$DIR/$CAND" \
          > "$SKEL/.config/plank/dock1/launchers/${ITEM_NAME}.dockitem"
        echo "   ✓ Plank : $ITEM_NAME → $DIR/$CAND"
        return 0
      fi
    done
  done
  echo "   ⚠ Plank : $ITEM_NAME — pas de .desktop trouvé"
}

create_dockitem "thunar"    "thunar.desktop" "Thunar.desktop"
create_dockitem "terminal"  "xfce4-terminal.desktop"
create_dockitem "firefox"   "firefox-esr.desktop" "firefox.desktop"
create_dockitem "mousepad"  "mousepad.desktop" "org.xfce.mousepad.desktop"
create_dockitem "wireshark" "wireshark.desktop" "org.wireshark.Wireshark.desktop"
create_dockitem "clamtk"    "clamtk.desktop"
create_dockitem "gufw"      "gufw.desktop"

# =============================================================================
# 5. LIGHTDM — Écran de connexion Liquid Glass
# =============================================================================
echo "[5/6] LightDM Liquid Glass..."

mkdir -p /etc/lightdm /etc/lightdm/lightdm-gtk-greeter.conf.d

cat > /etc/lightdm/lightdm.conf << 'EOF'
[LightDM]
greeter-session=lightdm-slick-greeter
user-session=xfce
allow-guest=false

[Seat:*]
autologin-user=shark
autologin-user-timeout=0
EOF

LOGO_PATH="/usr/share/sharkos/logo.png"
WALLPAPER_PATH="/usr/share/backgrounds/sharkos/sharkos.png"
chmod -R a+rX /usr/share/sharkos 2>/dev/null || true
chmod -R a+rX /usr/share/backgrounds 2>/dev/null || true

# Slick-greeter (principal)
cat > /etc/lightdm/slick-greeter.conf << EOF
[Greeter]
theme-name=WhiteSur-Dark
icon-theme-name=WhiteSur
background=${WALLPAPER_PATH}
user-background=false
font-name=Inter 11
draw-grid=false
show-hostname=true
show-power=true
show-clock=true
clock-format=%H:%M
EOF
[[ -f "$LOGO_PATH" ]] && echo "logo=${LOGO_PATH}" >> /etc/lightdm/slick-greeter.conf

# GTK greeter fallback
cat > /etc/lightdm/lightdm-gtk-greeter.conf << EOF
[greeter]
theme-name=WhiteSur-Dark
icon-theme-name=WhiteSur
background=${WALLPAPER_PATH}
user-background=false
font-name=Inter 11
clock-format=%H:%M — %A %d %B
indicators=~host;~spacer;~clock;~spacer;~power
position=50%,center 50%,center
EOF
[[ -f "$LOGO_PATH" ]] && echo "logo=${LOGO_PATH}" >> /etc/lightdm/lightdm-gtk-greeter.conf
cp /etc/lightdm/lightdm-gtk-greeter.conf \
   /etc/lightdm/lightdm-gtk-greeter.conf.d/99-sharkos.conf

# =============================================================================
# 6. AUTOSTART + IDENTITÉ
# =============================================================================
echo "[6/6] Autostart + identité..."

mkdir -p "$SKEL/.config/autostart"

# Plank
cat > "$SKEL/.config/autostart/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Comment=SharkOS Dock
Exec=plank
OnlyShowIn=XFCE;
X-XFCE-Autostart-Override=true
EOF

# Picom (compositeur — glass & ombres)
cat > "$SKEL/.config/autostart/picom.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Picom Compositor
Comment=Liquid Glass compositor
Exec=picom --config /etc/sharkos/picom.conf
OnlyShowIn=XFCE;
X-XFCE-Autostart-Delay=1
EOF

# Configuration Picom Liquid Glass
mkdir -p /etc/sharkos
cat > /etc/sharkos/picom.conf << 'PICOM'
# =============================================
# SharkOS — Picom Liquid Glass
# =============================================

# Backend : glx pour le vrai compositing GPU
backend = "glx";
glx-no-stencil = true;
glx-copy-from-front = false;

# Transparence des fenêtres inactives
inactive-opacity = 0.92;
active-opacity = 1.0;
frame-opacity = 0.90;
inactive-opacity-override = false;

# Flou de fond (blur derrière les fenêtres = Liquid Glass)
blur-method = "dual_kawase";
blur-strength = 8;
blur-background = true;
blur-background-frame = true;
blur-background-fixed = false;
blur-background-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'",
  "_GTK_FRAME_EXTENTS@:c"
];

# Ombres Liquid Glass : diffuses et décalées
shadow = true;
shadow-radius = 28;
shadow-opacity = 0.55;
shadow-offset-x = -14;
shadow-offset-y = -10;
shadow-color = "#000000";
shadow-exclude = [
  "name = 'Notification'",
  "class_g = 'Plank'",
  "class_g = 'Cairo-dock'",
  "_GTK_FRAME_EXTENTS@:c",
  "window_type = 'dock'"
];

# Fondu d'apparition/disparition
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
fade-delta = 5;

# Coins arrondis (Picom fork avec support rounded-corners)
corner-radius = 14;
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'"
];

# Opacités par type
opacity-rule = [
  "95:class_g = 'Xfce4-terminal'",
  "92:class_g = 'Thunar'",
  "95:class_g = 'Firefox'",
  "90:class_g = 'mousepad'",
  "88:class_g = 'Wireshark'"
];

# Performance
vsync = true;
use-damage = true;
PICOM

# Installer picom
apt-get install -y --no-install-recommends picom 2>/dev/null || true

# Terminal XFCE4 — couleurs Liquid Glass
mkdir -p "$SKEL/.config/xfce4/terminal"
cat > "$SKEL/.config/xfce4/terminal/terminalrc" << 'TERMRC'
[Configuration]
FontName=JetBrains Mono 11
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscBellUrgent=FALSE
MiscBordersDefault=TRUE
MiscCursorBlinks=TRUE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_IBEAM
MiscDefaultGeometry=100x28
MiscInheritGeometry=FALSE
MiscMenubarDefault=FALSE
MiscMouseAutohide=FALSE
MiscMouseWheelZoom=TRUE
MiscToolbarDefault=FALSE
MiscConfirmClose=FALSE
MiscCycleTabs=TRUE
MiscTabCloseButtons=TRUE
MiscTabCloseMiddleClick=TRUE
MiscTabPosition=GTK_POS_TOP
MiscHighlightUrls=TRUE
MiscMiddleClickOpensUri=FALSE
MiscCopyOnSelect=FALSE
MiscShowUnsafePasteDialog=TRUE
MiscRightClickAction=TERMINAL_RIGHT_CLICK_ACTION_CONTEXT_MENU
BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
BackgroundDarkness=0.88
ColorForeground=#e0e8ff
ColorBackground=#070b1a
ColorBold=#ffffff
ColorPalette=#0d0d1a;#ff5f57;#30d158;#ffd60a;#1a8cff;#bf5af2;#32ade6;#c0c8e0;#2a2d4a;#ff6e6e;#57f287;#ffff6e;#4fa8ff;#d580ff;#5bc8ef;#f0f4ff
ColorCursor=#1a8cff
ColorCursorForeground=#ffffff
ColorSelection=#1a8cff
ColorSelectionUseDefault=FALSE
ScrollingBar=TERMINAL_SCROLLBAR_NONE
ScrollingLines=10000
TabActivityColor=#1a8cff
TERMRC

# Identité système
cat > /etc/os-release << 'EOF'
NAME="SharkOS"
VERSION="1.0 (Hammerhead)"
ID=sharkos
ID_LIKE=debian
PRETTY_NAME="SharkOS 1.0 🦈 — Rapide. Furtif. Létal."
VERSION_ID="1.0"
HOME_URL="https://github.com/Simonc44/SharkOS"
VERSION_CODENAME=hammerhead
EOF

echo "sharkos" > /etc/hostname

cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
127.0.1.1   sharkos sharkos.local
::1         localhost ip6-localhost ip6-loopback
fe00::0     ip6-localnet
ff00::0     ip6-mcastprefix
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

cat > /etc/default/locale << 'EOF'
LANG=fr_FR.UTF-8
LANGUAGE=fr_FR:fr:en
LC_ALL=fr_FR.UTF-8
EOF
locale-gen fr_FR.UTF-8 2>/dev/null || true
update-locale LANG=fr_FR.UTF-8 2>/dev/null || true

echo ""
echo "✅ [HOOK 30] Bureau Liquid Glass configuré."
echo ""
