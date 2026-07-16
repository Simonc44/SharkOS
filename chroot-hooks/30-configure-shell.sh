#!/usr/bin/env bash
# =============================================================================
# SharkOS — 30-configure-shell.sh (CHROOT HOOK — v2 corrigé)
# FIXES :
#   - Noms .dockitem corrigés (wireshark, pas wireshark-gtk)
#   - Vérification existence .desktop avant création dockitem
#   - Noms alternatifs testés pour les apps (wireshark.desktop, org.wireshark...)
#   - Hostname + /etc/hosts complets
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 30] Configuration shell + bureau XFCE SharkOS..."
echo ""

SKEL="/etc/skel"

# =============================================================================
# 1. CONFIGURATION XFCE4 — Barre du haut (style macOS)
# =============================================================================
echo "[1/6] Barre XFCE style macOS..."

mkdir -p "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml"

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="empty">
    <property name="position" type="string" value="p=6;x=0;y=0"/>
    <property name="position-locked" type="bool" value="true"/>
    <property name="length" type="uint" value="100"/>
    <property name="size" type="uint" value="28"/>
    <property name="background-style" type="uint" value="2"/>
    <property name="background-rgba" type="array">
      <value type="double" value="0.08"/>
      <value type="double" value="0.08"/>
      <value type="double" value="0.12"/>
      <value type="double" value="0.90"/>
    </property>
    <property name="autohide-behavior" type="uint" value="0"/>
    <property name="plugin-ids" type="array">
      <value type="int" value="1"/>
      <value type="int" value="2"/>
      <value type="int" value="3"/>
      <value type="int" value="4"/>
      <value type="int" value="5"/>
      <value type="int" value="6"/>
      <value type="int" value="7"/>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu">
      <property name="show-button-title" type="bool" value="true"/>
      <property name="button-title" type="string" value="🦈 SharkOS"/>
      <property name="show-tooltip" type="bool" value="false"/>
    </property>
    <property name="plugin-2" type="string" value="separator">
      <property name="expand" type="bool" value="false"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-3" type="string" value="tasklist">
      <property name="flat-buttons" type="bool" value="true"/>
      <property name="include-all-workspaces" type="bool" value="false"/>
    </property>
    <property name="plugin-4" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-5" type="string" value="systray">
      <property name="size-max" type="uint" value="22"/>
    </property>
    <property name="plugin-6" type="string" value="pulseaudio">
      <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
    </property>
    <property name="plugin-7" type="string" value="clock">
      <property name="mode" type="uint" value="2"/>
      <property name="digital-format" type="string" value="%H:%M  %a %d %b"/>
    </property>
  </property>
</channel>
EOF

# =============================================================================
# 2. THÈME GTK WHITSUR-DARK
# =============================================================================
echo "[2/6] Thème GTK WhiteSur-Dark..."

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="WhiteSur-Dark"/>
    <property name="IconThemeName" type="string" value="WhiteSur"/>
    <property name="SoundThemeName" type="string" value="default"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="DecorationLayout" type="string" value="close,minimize,maximize:menu"/>
    <property name="FontName" type="string" value="Sans 10"/>
    <property name="MonospaceFontName" type="string" value="Monospace 10"/>
    <property name="CursorThemeName" type="string" value="WhiteSur-cursors"/>
    <property name="CursorThemeSize" type="int" value="24"/>
  </property>
</channel>
EOF

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="WhiteSur-Dark"/>
    <property name="title_font" type="string" value="Sans Bold 9"/>
    <property name="button_layout" type="string" value="CMH|O"/>
    <property name="show_dock_shadow" type="bool" value="false"/>
    <property name="show_frame_shadow" type="bool" value="true"/>
    <property name="frame_opacity" type="int" value="85"/>
  </property>
</channel>
EOF

# =============================================================================
# 3. PLANK DOCK (FIX noms .dockitem)
# =============================================================================
echo "[3/6] Plank Dock..."

mkdir -p "$SKEL/.config/plank/dock1/launchers"

cat > "$SKEL/.config/plank/dock1/settings" << 'EOF'
[PlankDockPreferences]
Position=3
Alignment=3
IconSize=48
ZoomEnabled=true
ZoomPercent=150
HideMode=3
UnhideDelay=0
HideDelay=300
Theme=Transparent
Offset=6
Monitor=
LockItems=false
EOF

# FIX : Chercher le bon nom de .desktop pour chaque app (plusieurs noms possibles)
create_dockitem() {
  local ITEM_NAME="$1"
  shift
  local CANDIDATES=("$@")
  local DESKTOP_DIRS=("/usr/share/applications" "/usr/local/share/applications")

  for DESKTOP_DIR in "${DESKTOP_DIRS[@]}"; do
    for CANDIDATE in "${CANDIDATES[@]}"; do
      local DESKTOP_FILE="$DESKTOP_DIR/$CANDIDATE"
      if [[ -f "$DESKTOP_FILE" ]]; then
        cat > "$SKEL/.config/plank/dock1/launchers/${ITEM_NAME}.dockitem" << DOCKITEM
[PlankDockItemPreferences]
Launcher=file://${DESKTOP_FILE}
DOCKITEM
        echo "   ✓ Plank : $ITEM_NAME → $DESKTOP_FILE"
        return 0
      fi
    done
  done
  echo "   ⚠️  Plank : $ITEM_NAME — aucun .desktop trouvé (sera ajouté si installé)"
  return 0
}

# FIX : noms corrects des .desktop
create_dockitem "thunar"        "thunar.desktop" "Thunar.desktop"
create_dockitem "terminal"      "xfce4-terminal.desktop" "xterm.desktop"
create_dockitem "firefox"       "firefox-esr.desktop" "firefox.desktop" "mozilla-firefox.desktop"
create_dockitem "mousepad"      "mousepad.desktop" "org.xfce.mousepad.desktop"
create_dockitem "wireshark"     "wireshark.desktop" "org.wireshark.Wireshark.desktop"
create_dockitem "clamtk"        "clamtk.desktop" "org.gtk.clamtk.desktop"
create_dockitem "gufw"          "gufw.desktop" "com.ubuntu.gufw.desktop"

# =============================================================================
# 4. LIGHTDM (Écran de connexion)
# =============================================================================
echo "[4/6] LightDM greeter..."
mkdir -p /etc/lightdm
mkdir -p /etc/lightdm/lightdm-gtk-greeter.conf.d

cat > /etc/lightdm/lightdm.conf << 'EOF'
[LightDM]
greeter-session=lightdm-gtk-greeter
user-session=xfce
allow-guest=false

[Seat:*]
autologin-user=shark
autologin-user-timeout=0
EOF

# FIX : Logo PNG (pas SVG) pour le greeter
LOGO_PATH="/usr/share/sharkos/logo.png"
WALLPAPER_PATH="/usr/share/backgrounds/sharkos/sharkos.png"

# Rendre les dossiers d'assets lisibles par l'utilisateur système lightdm
chmod -R a+rX /usr/share/sharkos 2>/dev/null || true
chmod -R a+rX /usr/share/backgrounds 2>/dev/null || true

cat > /etc/lightdm/lightdm-gtk-greeter.conf << EOF
[greeter]
theme-name=WhiteSur-Dark
icon-theme-name=WhiteSur
background=${WALLPAPER_PATH}
user-background=false
font-name=Sans 11
clock-format=%H:%M — %A %d %B
indicators=~host;~spacer;~clock;~spacer;~power
position=50%,center 50%,center
EOF

if [[ -f "$LOGO_PATH" ]]; then
  echo "logo=${LOGO_PATH}" >> /etc/lightdm/lightdm-gtk-greeter.conf
fi

# Doubler la configuration dans conf.d pour écraser les priorités par défaut de Debian/Ubuntu (comme 30_debian.conf)
cp /etc/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf.d/99-sharkos.conf

# =============================================================================
# 5. AUTOSTART (Plank + MAC randomizer)
# =============================================================================
echo "[5/6] Autostart..."
mkdir -p "$SKEL/.config/autostart"

cat > "$SKEL/.config/autostart/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Comment=SharkOS Dock
Exec=plank
OnlyShowIn=XFCE;
X-XFCE-Autostart-Override=true
EOF

# MAC randomizer au login (sans pkexec — le service systemd s'en charge au boot)
# Ce .desktop est informatif mais pas exécuté automatiquement (géré par systemd)
cat > "$SKEL/.config/autostart/sharkos-welcome.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=SharkOS Welcome
Comment=Message de bienvenue SharkOS
Exec=bash -c 'sleep 3 && xfce4-terminal -e "bash -c \"echo; echo 🦈 Bienvenue dans SharkOS\! ; echo; bash --login\""'
OnlyShowIn=XFCE;
X-XFCE-Autostart-Delay=5
EOF

# =============================================================================
# 6. IDENTITÉ DU SYSTÈME
# =============================================================================
echo "[6/6] Identité SharkOS..."

cat > /etc/os-release << 'EOF'
NAME="SharkOS"
VERSION="1.0 (Hammerhead)"
ID=sharkos
ID_LIKE=debian
PRETTY_NAME="SharkOS 1.0 🦈 — Rapide. Furtif. Létal."
VERSION_ID="1.0"
HOME_URL="https://github.com/SharkOS"
SUPPORT_URL="https://github.com/SharkOS/issues"
BUG_REPORT_URL="https://github.com/SharkOS/issues"
VERSION_CODENAME=hammerhead
EOF

echo "sharkos" > /etc/hostname

# FIX : /etc/hosts complet avec IPv6
cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
127.0.1.1   sharkos sharkos.local
::1         localhost ip6-localhost ip6-loopback
fe00::0     ip6-localnet
ff00::0     ip6-mcastprefix
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

# Locale française
cat > /etc/default/locale << 'EOF'
LANG=fr_FR.UTF-8
LANGUAGE=fr_FR:fr:en
LC_ALL=fr_FR.UTF-8
EOF

locale-gen fr_FR.UTF-8 2>/dev/null || true
update-locale LANG=fr_FR.UTF-8 2>/dev/null || true

echo ""
echo "✅ [HOOK 30] Configuration bureau SharkOS terminée."
echo ""
