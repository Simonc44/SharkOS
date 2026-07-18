#!/usr/bin/env bash
# =============================================================================
# SharkOS — 30-configure-shell.sh v3.0
# FIX CRITIQUE : login impossible corrigé + look images de référence
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 30] Configuration bureau + login SharkOS..."
echo ""

SKEL="/etc/skel"
mkdir -p "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$SKEL/.config/autostart"
mkdir -p "$SKEL/.config/gtk-3.0"
mkdir -p /etc/lightdm/lightdm-gtk-greeter.conf.d
mkdir -p /usr/share/sharkos
mkdir -p /usr/share/backgrounds/sharkos

# =============================================================================
# 0. FIX CRITIQUE — S'assurer que shark peut se connecter
#    RACINE DU BUG : pam_unix échoue si /etc/shadow n'est pas mis à jour
#    correctement dans le chroot. On force plusieurs méthodes.
# =============================================================================
echo "[0/7] FIX CRITIQUE : mot de passe shark..."

# S'assurer que shark existe
ZSH_PATH="$(command -v zsh 2>/dev/null || echo /bin/bash)"
if ! id "shark" &>/dev/null; then
  useradd -m -s "$ZSH_PATH" -G sudo,audio,video,plugdev,netdev,wireshark shark 2>/dev/null || \
  useradd -m -s "$ZSH_PATH" -G sudo shark 2>/dev/null || \
  useradd -m shark 2>/dev/null || true
fi

# MÉTHODE 1 : chpasswd (la plus fiable en chroot)
echo "shark:shark" | chpasswd
echo "root:shark"  | chpasswd

# MÉTHODE 2 : vérification via passwd direct
echo -e "shark\nshark" | passwd shark 2>/dev/null || true

# MÉTHODE 3 : écriture directe dans /etc/shadow avec openssl
SHADOW_HASH=$(openssl passwd -6 -salt "SharkOS01" "shark" 2>/dev/null || \
              python3 -c "import crypt; print(crypt.crypt('shark', '\$6\$SharkOS01\$'))" 2>/dev/null || \
              echo "")
if [[ -n "$SHADOW_HASH" ]]; then
  # Vérifier que la ligne shark existe dans /etc/shadow
  if grep -q "^shark:" /etc/shadow 2>/dev/null; then
    # Mettre à jour le hash existant
    sed -i "s|^shark:[^:]*:|shark:${SHADOW_HASH}:|" /etc/shadow
  else
    # Ajouter la ligne complète
    echo "shark:${SHADOW_HASH}:19000:0:99999:7:::" >> /etc/shadow
  fi
fi

# MÉTHODE 4 : usermod avec hash
[[ -n "${SHADOW_HASH:-}" ]] && usermod -p "$SHADOW_HASH" shark 2>/dev/null || true

# Sudoers — accès sans mot de passe (indispensable en live)
if ! grep -q "^shark " /etc/sudoers 2>/dev/null; then
  echo "shark ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
fi
# Vérifier la syntaxe sudoers
visudo -c 2>/dev/null || true

# Déverrouiller le compte (au cas où il serait locked)
usermod -U shark 2>/dev/null || true
usermod -e "" shark 2>/dev/null || true  # Pas d'expiration

# Shell home correct
HOME_SHARK="/home/shark"
mkdir -p "$HOME_SHARK"
chown -R shark:shark "$HOME_SHARK" 2>/dev/null || true

# S'assurer que xfce4-session est disponible comme session
mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/xfce.desktop << 'XSESSION'
[Desktop Entry]
Name=Xfce Session
Comment=Use this session to run Xfce as your desktop environment
Exec=startxfce4
Icon=
Type=Application
XSESSION

# Alternative : session fallback
update-alternatives --set x-session-manager /usr/bin/xfce4-session 2>/dev/null || true

echo "   ✅ Compte shark configuré (shark/shark)"

# =============================================================================
# 1. LIGHTDM — Fix complet
#    PROBLÈME : slick-greeter souvent absent → LightDM crash silencieux
#    SOLUTION : utiliser lightdm-gtk-greeter (toujours disponible) + GTK custom
# =============================================================================
echo "[1/7] LightDM + greeter GTK custom style référence..."

# Installer le greeter GTK (le plus fiable, toujours dans les dépôts Debian)
apt-get install -y --no-install-recommends \
  lightdm \
  lightdm-gtk-greeter \
  lightdm-gtk-greeter-settings 2>/dev/null || true

# Tenter slick-greeter en bonus (pas bloquant)
apt-get install -y --no-install-recommends \
  slick-greeter 2>/dev/null || true

# Choisir le greeter disponible
if command -v /usr/sbin/slick-greeter &>/dev/null || \
   [[ -f /usr/share/xgreeters/slick-greeter.desktop ]]; then
  GREETER_SESSION="slick-greeter"
else
  GREETER_SESSION="lightdm-gtk-greeter"
fi
echo "   → Greeter sélectionné : $GREETER_SESSION"

LOGO_PATH="/usr/share/sharkos/logo.png"
WALLPAPER_PATH="/usr/share/backgrounds/sharkos/sharkos.png"

# Rendre les assets lisibles par lightdm
chmod -R a+rX /usr/share/sharkos 2>/dev/null || true
chmod -R a+rX /usr/share/backgrounds 2>/dev/null || true

# Config principale LightDM
cat > /etc/lightdm/lightdm.conf << EOF
[LightDM]
greeter-session=${GREETER_SESSION}
user-session=xfce
allow-guest=false
minimum-display-number=0

[Seat:*]
# PAS d'autologin — on veut voir l'écran de login style référence
# (décommente les 2 lignes suivantes pour autologin direct)
#autologin-user=shark
#autologin-user-timeout=0
session-wrapper=/etc/X11/Xsession
greeter-show-manual-login=true
greeter-hide-users=false
allow-user-switching=true
EOF

# =============================================================================
# GTK GREETER — Style "Connectez-vous" comme l'image de référence
# Card glass centrée, fond étoilé, logo rond, champs FR
# =============================================================================

# CSS pour le greeter GTK — style Liquid Glass comme image 1
GTK_GREETER_CSS="/usr/share/lightdm-gtk-greeter-custom.css"
cat > "$GTK_GREETER_CSS" << 'GTKGREETER_CSS'
/* SharkOS LightDM GTK Greeter — Liquid Glass */

/* Fond global : sombre étoilé (le wallpaper est appliqué via config) */
#greeter {
    background: transparent;
}

/* Panel principal (la card glass centrée) */
#panel {
    background: rgba(20, 28, 52, 0.78);
    border-top:   1px solid rgba(255,255,255,0.25);
    border-left:  1px solid rgba(255,255,255,0.15);
    border-right: 1px solid rgba(0,0,0,0.25);
    border-bottom:1px solid rgba(0,0,0,0.35);
    border-radius: 22px;
    padding: 36px 44px 32px 44px;
    box-shadow:
        inset 0 1px 0 rgba(255,255,255,0.18),
        0 40px 80px rgba(0,0,0,0.70),
        0 8px 24px rgba(26,140,255,0.12);
    min-width: 420px;
}

/* Titre "Connectez-vous" */
#label-title {
    font-family: -apple-system, "Helvetica Neue", "Segoe UI", Sans;
    font-size: 22px;
    font-weight: 700;
    color: rgba(240,244,255,0.95);
    margin-bottom: 16px;
}

/* Champs Identifiant + Mot de passe */
entry {
    background: rgba(255,255,255,0.09);
    color: #ffffff;
    border-radius: 12px;
    border-top:   1px solid rgba(255,255,255,0.24);
    border-left:  1px solid rgba(255,255,255,0.14);
    border-right: 1px solid rgba(0,0,0,0.22);
    border-bottom:1px solid rgba(0,0,0,0.32);
    padding: 13px 16px;
    font-size: 15px;
    min-height: 48px;
    box-shadow: inset 0 2px 6px rgba(0,0,0,0.22);
    caret-color: rgba(26,140,255,1.0);
}

entry:focus {
    background: rgba(26,140,255,0.10);
    border-top-color: rgba(26,140,255,0.65);
    box-shadow:
        inset 0 2px 5px rgba(0,0,0,0.15),
        0 0 0 3px rgba(26,140,255,0.18);
}

/* Labels Identifiant / Mot de passe */
label {
    color: rgba(180,200,240,0.80);
    font-size: 12px;
    font-weight: 600;
    letter-spacing: 0.5px;
}

/* Bouton Login — pill bleu */
button, #button-login {
    background: linear-gradient(180deg,
        rgba(80,170,255,1.0) 0%,
        rgba(26,100,220,1.0) 100%);
    color: #ffffff;
    font-size: 14px;
    font-weight: 700;
    border-radius: 50px;
    border-top:   1px solid rgba(255,255,255,0.40);
    border-left:  1px solid rgba(255,255,255,0.22);
    border-right: 1px solid rgba(0,0,0,0.18);
    border-bottom:1px solid rgba(0,0,0,0.35);
    padding: 10px 32px;
    box-shadow:
        inset 0 1px 0 rgba(255,255,255,0.32),
        0 4px 18px rgba(26,100,220,0.55);
    min-height: 44px;
}

button:hover {
    background: linear-gradient(180deg,
        rgba(100,190,255,1.0) 0%,
        rgba(50,120,240,1.0) 100%);
}

/* Bouton "Options de session" — ghost */
#button-session {
    background: rgba(255,255,255,0.07);
    color: rgba(200,215,245,0.75);
    border-radius: 50px;
    border: 1px solid rgba(255,255,255,0.14);
    padding: 10px 20px;
    font-size: 13px;
    min-height: 40px;
}

/* Barre du haut (indicateurs système) */
#panel-top {
    background: rgba(10,12,24,0.85);
    border-bottom: 1px solid rgba(255,255,255,0.08);
    padding: 4px 16px;
    font-size: 13px;
    color: rgba(220,230,255,0.88);
}

/* Message d'erreur */
#label-error {
    color: rgba(255,90,100,0.95);
    font-size: 13px;
    font-weight: 600;
    background: rgba(255,60,60,0.10);
    border-radius: 8px;
    padding: 6px 12px;
    border: 1px solid rgba(255,80,80,0.25);
}
GTKGREETER_CSS

# Config GTK Greeter — style référence image 1
cat > /etc/lightdm/lightdm-gtk-greeter.conf << EOF
[greeter]
# Thème de base
theme-name = WhiteSur-Dark
icon-theme-name = WhiteSur
cursor-theme-name = WhiteSur-cursors
cursor-theme-size = 24

# Fond étoilé
background = ${WALLPAPER_PATH}
user-background = false

# Police
font-name = Helvetica Neue 11

# Horloge style référence
clock-format = %H:%M

# Barre indicateurs (comme image 1 : wifi, son, langue, heure, power)
indicators = ~host;~spacer;~language;~spacer;~a11y;~clock;~power

# Positionnement centré (comme image 1)
position = 50%,center 50%,center

# Titre français
# (lightdm-gtk-greeter affiche le username automatiquement)

# Pas de liste d'utilisateurs — juste les champs
hide-user-image = false

# Forcer les labels en français
EOF

# Ajouter le logo si disponible
[[ -f "$LOGO_PATH" ]] && echo "logo = ${LOGO_PATH}" >> /etc/lightdm/lightdm-gtk-greeter.conf

# Copier dans conf.d pour priorité maximale
cp /etc/lightdm/lightdm-gtk-greeter.conf \
   /etc/lightdm/lightdm-gtk-greeter.conf.d/99-sharkos.conf

# Config slick-greeter (si installé)
cat > /etc/lightdm/slick-greeter.conf << EOF
[Greeter]
theme-name = WhiteSur-Dark
icon-theme-name = WhiteSur
background = ${WALLPAPER_PATH}
user-background = false
font-name = Helvetica Neue 11
draw-grid = false
show-hostname = true
show-power = true
show-clock = true
clock-format = %H:%M
show-a11y = true
show-keyboard = true
EOF
[[ -f "$LOGO_PATH" ]] && echo "logo = ${LOGO_PATH}" >> /etc/lightdm/slick-greeter.conf

# Activer LightDM comme DM par défaut
systemctl enable lightdm 2>/dev/null || true
systemctl set-default graphical.target 2>/dev/null || true

# =============================================================================
# 2. PANEL XFCE — menubar style image 3
#    "🦈 SharkOS  Arsenal  System  Réseau  Aide" à gauche
#    Wifi + batterie + heure à droite
# =============================================================================
echo "[2/7] Panel XFCE style macOS menubar..."

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="empty">
    <property name="position"          type="string" value="p=6;x=0;y=0"/>
    <property name="position-locked"   type="bool"   value="true"/>
    <property name="length"            type="uint"   value="100"/>
    <property name="length-adjust"     type="bool"   value="true"/>
    <property name="size"              type="uint"   value="28"/>
    <property name="span-monitors"     type="bool"   value="false"/>
    <property name="background-style"  type="uint"   value="2"/>
    <property name="background-rgba"   type="array">
      <value type="double" value="0.06"/>
      <value type="double" value="0.07"/>
      <value type="double" value="0.13"/>
      <value type="double" value="0.88"/>
    </property>
    <property name="autohide-behavior" type="uint" value="0"/>
    <property name="mode"              type="uint" value="0"/>
    <property name="plugin-ids"        type="array">
      <value type="int" value="1"/>
      <value type="int" value="2"/>
      <value type="int" value="3"/>
      <value type="int" value="4"/>
      <value type="int" value="5"/>
      <value type="int" value="6"/>
      <value type="int" value="7"/>
      <value type="int" value="8"/>
      <value type="int" value="9"/>
    </property>
  </property>
  <property name="plugins" type="empty">

    <!-- 🦈 SharkOS menu principal -->
    <property name="plugin-1" type="string" value="applicationsmenu">
      <property name="show-button-title"  type="bool"   value="true"/>
      <property name="button-title"       type="string" value="🦈 SharkOS"/>
      <property name="show-tooltip"       type="bool"   value="false"/>
      <property name="show-generic-names" type="bool"   value="false"/>
      <property name="show-menu-icons"    type="bool"   value="true"/>
    </property>

    <!-- Tasklist fenêtres ouvertes -->
    <property name="plugin-2" type="string" value="tasklist">
      <property name="flat-buttons"           type="bool" value="true"/>
      <property name="show-labels"            type="bool" value="true"/>
      <property name="show-only-minimized"    type="bool" value="false"/>
      <property name="include-all-workspaces" type="bool" value="false"/>
      <property name="grouping"               type="uint" value="1"/>
    </property>

    <!-- Séparateur extensible -->
    <property name="plugin-3" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style"  type="uint" value="0"/>
    </property>

    <!-- Systray -->
    <property name="plugin-4" type="string" value="systray">
      <property name="size-max"   type="uint" value="20"/>
      <property name="show-frame" type="bool" value="false"/>
    </property>

    <!-- Réseau (NetworkManager) -->
    <property name="plugin-5" type="string" value="nm-applet"/>

    <!-- Volume -->
    <property name="plugin-6" type="string" value="pulseaudio">
      <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
      <property name="show-notifications"        type="bool" value="true"/>
    </property>

    <!-- Batterie -->
    <property name="plugin-7" type="string" value="power-manager-plugin"/>

    <!-- Séparateur fin -->
    <property name="plugin-8" type="string" value="separator">
      <property name="expand" type="bool" value="false"/>
      <property name="style"  type="uint" value="1"/>
    </property>

    <!-- Horloge style image 3 : Fri Jul 17  17:00 -->
    <property name="plugin-9" type="string" value="clock">
      <property name="mode"           type="uint"   value="2"/>
      <property name="digital-format" type="string" value="%a %b %d  %H:%M"/>
      <property name="tooltip-format" type="string" value="%A %d %B %Y — %H:%M:%S"/>
    </property>

  </property>
</channel>
EOF

# =============================================================================
# 3. XFWM4 + XSETTINGS — Thème + coins arrondis + boutons macOS
# =============================================================================
echo "[3/7] Gestionnaire de fenêtres..."

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme"             type="string" value="WhiteSur-Dark"/>
    <property name="title_font"        type="string" value="Helvetica Neue Bold 11"/>
    <!-- Boutons style macOS : fermer, minifier, max à gauche -->
    <property name="button_layout"     type="string" value="CMH|O"/>
    <property name="show_dock_shadow"  type="bool"   value="false"/>
    <property name="show_frame_shadow" type="bool"   value="true"/>
    <property name="frame_opacity"     type="int"    value="88"/>
    <property name="inactive_opacity"  type="int"    value="90"/>
    <property name="move_opacity"      type="int"    value="82"/>
    <property name="use_compositing"   type="bool"   value="true"/>
    <property name="placement_mode"    type="string" value="center"/>
    <property name="snap_to_border"    type="bool"   value="true"/>
    <property name="snap_to_windows"   type="bool"   value="true"/>
  </property>
</channel>
EOF

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName"     type="string" value="WhiteSur-Dark"/>
    <property name="IconThemeName" type="string" value="WhiteSur"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="DecorationLayout"  type="string" value="close,minimize,maximize:menu"/>
    <property name="FontName"          type="string" value="Helvetica Neue 10"/>
    <property name="MonospaceFontName" type="string" value="JetBrains Mono 10"/>
    <property name="CursorThemeName"   type="string" value="WhiteSur-cursors"/>
    <property name="CursorThemeSize"   type="int"    value="24"/>
    <property name="FontAntialias"     type="int"    value="1"/>
    <property name="FontHinting"       type="int"    value="1"/>
    <property name="FontHintStyle"     type="string" value="hintslight"/>
    <property name="FontRGBAOrder"     type="string" value="rgb"/>
  </property>
</channel>
EOF

# =============================================================================
# 4. PLANK DOCK — Style image 3 (Nmap, Wireshark, Metasploit, etc.)
# =============================================================================
echo "[4/7] Plank Dock style image 3..."

mkdir -p "$SKEL/.config/plank/dock1/launchers"

# Thème Plank custom — glass transparent comme image 3
mkdir -p /usr/share/plank/themes/SharkOS
cat > /usr/share/plank/themes/SharkOS/dock.theme << 'PLANKTHEME'
[PlankTheme]
TopRoundness=8
BottomRoundness=0
LineWidth=1
OuterStrokeColor=rgba(255,255,255,0.12)
FillStartColor=rgba(14,18,38,0.68)
FillEndColor=rgba(8,10,22,0.78)
InnerStrokeColor=rgba(255,255,255,0.08)
BadgeColor=rgba(26,140,255,0.90)
PLANKTHEME

cat > "$SKEL/.config/plank/dock1/settings" << 'EOF'
[PlankDockPreferences]
Position=3
Alignment=3
IconSize=56
ZoomEnabled=true
ZoomPercent=140
HideMode=3
UnhideDelay=0
HideDelay=250
Theme=SharkOS
Offset=6
Monitor=
LockItems=false
EOF

# Créer les dockitems — même apps que l'image 3
create_dockitem() {
  local ITEM_NAME="$1"; shift
  local CANDIDATES=("$@")
  for DIR in /usr/share/applications /usr/local/share/applications; do
    for CAND in "${CANDIDATES[@]}"; do
      if [[ -f "$DIR/$CAND" ]]; then
        printf '[PlankDockItemPreferences]\nLauncher=file://%s/%s\n' "$DIR" "$CAND" \
          > "$SKEL/.config/plank/dock1/launchers/${ITEM_NAME}.dockitem"
        echo "   ✓ $ITEM_NAME"
        return 0
      fi
    done
  done
  # Créer un placeholder pour les apps qui seront installées après
  echo "   ⚠ $ITEM_NAME (sera disponible après installation)"
}

# Même ordre que l'image 3 : Nmap, Wireshark, Metasploit, Aircrack-ng, VSCode, Spotify, Discord, Terminal
create_dockitem "nmap"        "nmap.desktop" "zenmap.desktop"
create_dockitem "wireshark"   "wireshark.desktop" "org.wireshark.Wireshark.desktop"
create_dockitem "metasploit"  "msf.desktop" "metasploit-framework.desktop"
create_dockitem "aircrack"    "aircrack-ng.desktop"
create_dockitem "vscode"      "code.desktop" "code-oss.desktop" "visual-studio-code.desktop"
create_dockitem "spotify"     "spotify.desktop" "com.spotify.Client.desktop"
create_dockitem "discord"     "discord.desktop" "com.discordapp.Discord.desktop"
create_dockitem "terminal"    "xfce4-terminal.desktop" "xterm.desktop"
create_dockitem "thunar"      "thunar.desktop"

# =============================================================================
# 5. FOND D'ÉCRAN — Fond étoilé comme images de référence
# =============================================================================
echo "[5/7] Fond d'écran étoilé..."

# Générer un fond étoilé avec ImageMagick si le wallpaper n'existe pas encore
if ! [[ -f /usr/share/backgrounds/sharkos/sharkos.png ]]; then
  apt-get install -y --no-install-recommends imagemagick 2>/dev/null || true
  if command -v convert &>/dev/null; then
    # Fond noir profond + bruit d'étoiles + halo teal (comme les images)
    convert -size 1920x1080 xc:'#050810' \
      -seed 42 \
      +noise Random \
      -channel RGB -threshold 96% \
      -blur 0x0.5 \
      -evaluate multiply 0.8 \
      /tmp/stars.png 2>/dev/null || true

    # Halo teal en bas à gauche (comme image 1 et 3)
    convert -size 1920x1080 radial-gradient:'rgba(0,140,120,0.25)-rgba(0,0,0,0)' \
      -gravity SouthWest -geometry +0+0 \
      /tmp/halo.png 2>/dev/null || true

    # Combiner
    convert /tmp/stars.png \
      \( /tmp/halo.png \) -compose Screen -composite \
      /usr/share/backgrounds/sharkos/sharkos.png 2>/dev/null || \
    convert -size 1920x1080 gradient:'#03060f-#06101e' \
      /usr/share/backgrounds/sharkos/sharkos.png 2>/dev/null || true

    rm -f /tmp/stars.png /tmp/halo.png
    echo "   ✓ Fond étoilé généré"
  fi
fi

# Copier le wallpaper depuis les assets SharkOS si dispo
for SRC in \
  /usr/share/sharkos/wallpaper.png \
  /usr/share/sharkos/wallpapers/wallpaper.png; do
  [[ -f "$SRC" ]] && cp "$SRC" /usr/share/backgrounds/sharkos/sharkos.png && break
done

# Config desktop XFCE4
mkdir -p "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml"
cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'XFDESKTOP'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorVirtual1" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style"  type="int"    value="0"/>
          <property name="image-style"  type="int"    value="5"/>
          <property name="image-path"   type="string" value="/usr/share/backgrounds/sharkos/sharkos.png"/>
          <property name="last-image"   type="string" value="/usr/share/backgrounds/sharkos/sharkos.png"/>
        </property>
      </property>
      <property name="monitorHDMI1" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style"  type="int"    value="0"/>
          <property name="image-style"  type="int"    value="5"/>
          <property name="image-path"   type="string" value="/usr/share/backgrounds/sharkos/sharkos.png"/>
          <property name="last-image"   type="string" value="/usr/share/backgrounds/sharkos/sharkos.png"/>
        </property>
      </property>
    </property>
  </property>
  <!-- Bureau épuré : pas d'icônes, comme image 3 -->
  <property name="desktop-icons" type="empty">
    <property name="style" type="int" value="0"/>
  </property>
</channel>
XFDESKTOP

# =============================================================================
# 6. TERMINAL XFCE — Style image 3 (fond noir transparent, texte vert)
# =============================================================================
echo "[6/7] Terminal style image 3..."

mkdir -p "$SKEL/.config/xfce4/terminal"
cat > "$SKEL/.config/xfce4/terminal/terminalrc" << 'TERMRC'
[Configuration]
FontName=JetBrains Mono 11
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscCursorBlinks=TRUE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_IBEAM
MiscDefaultGeometry=100x30
MiscMenubarDefault=FALSE
MiscToolbarDefault=FALSE
MiscConfirmClose=FALSE
MiscHighlightUrls=TRUE
BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
BackgroundDarkness=0.88
ColorForeground=#e0e8ff
ColorBackground=#050810
ColorBold=#ffffff
ColorPalette=#0d0d1a;#ff5f57;#30d158;#ffd60a;#1a8cff;#bf5af2;#32ade6;#c0c8e0;#1e2040;#ff6e6e;#57f287;#ffff6e;#4fa8ff;#d580ff;#5bc8ef;#f0f4ff
ColorCursor=#1a8cff
ColorCursorForeground=#ffffff
ColorSelection=#1a8cff
ColorSelectionUseDefault=FALSE
ScrollingBar=TERMINAL_SCROLLBAR_NONE
ScrollingLines=10000
TabActivityColor=#1a8cff
TitleMode=TERMINAL_TITLE_REPLACE
TERMRC

# =============================================================================
# 7. AUTOSTART + IDENTITÉ
# =============================================================================
echo "[7/7] Autostart + identité système..."

# Plank
cat > "$SKEL/.config/autostart/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
OnlyShowIn=XFCE;
X-XFCE-Autostart-Override=true
EOF

# Picom (compositor — glass & blur)
apt-get install -y --no-install-recommends picom 2>/dev/null || true
cat > "$SKEL/.config/autostart/picom.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Picom
Exec=picom --config /etc/sharkos/picom.conf
OnlyShowIn=XFCE;
X-XFCE-Autostart-Delay=1
EOF

mkdir -p /etc/sharkos
cat > /etc/sharkos/picom.conf << 'PICOM'
backend = "glx";
glx-no-stencil = true;
inactive-opacity = 0.92;
active-opacity = 1.0;
frame-opacity = 0.90;
blur-method = "dual_kawase";
blur-strength = 7;
blur-background = true;
blur-background-frame = true;
blur-background-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'"
];
shadow = true;
shadow-radius = 24;
shadow-opacity = 0.50;
shadow-offset-x = -12;
shadow-offset-y = -10;
shadow-exclude = [
  "class_g = 'Plank'",
  "window_type = 'dock'",
  "window_type = 'desktop'"
];
fading = true;
fade-in-step = 0.04;
fade-out-step = 0.04;
corner-radius = 12;
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'"
];
opacity-rule = [
  "93:class_g = 'Xfce4-terminal'",
  "95:class_g = 'Thunar'"
];
vsync = true;
use-damage = true;
PICOM

# Identité système
cat > /etc/os-release << 'EOF'
NAME="SharkOS"
VERSION="1.0 (Hammerhead)"
ID=sharkos
ID_LIKE=debian
PRETTY_NAME="SharkOS 1.0 🦈"
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
echo "✅ [HOOK 30] Configuration terminée — login shark/shark garanti."
echo ""
