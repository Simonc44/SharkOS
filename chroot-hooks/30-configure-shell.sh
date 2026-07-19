#!/usr/bin/env bash
# =============================================================================
# SharkOS — 30-configure-shell.sh v4.0 (Garuda-style)
# KDE Plasma (si disponible) ou XFCE amélioré
# Powerlevel10k, Kvantum, Latte-style dock, Picom blur
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 30] Configuration bureau SharkOS (Garuda-style)..."
echo ""

SKEL="/etc/skel"
mkdir -p "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$SKEL/.config/autostart"
mkdir -p "$SKEL/.config/gtk-3.0" "$SKEL/.config/gtk-4.0"
mkdir -p /etc/lightdm/lightdm-gtk-greeter.conf.d
mkdir -p /usr/share/sharkos /usr/share/backgrounds/sharkos

WALLPAPER_PATH="/usr/share/backgrounds/sharkos/sharkos.png"

# =============================================================================
# 0. COMPTE SHARK (garanti)
# =============================================================================
echo "[0/8] Compte shark..."
ZSH_PATH="$(command -v zsh 2>/dev/null || echo /bin/bash)"
if ! id "shark" &>/dev/null; then
  useradd -m -s "$ZSH_PATH" -G sudo,audio,video,plugdev,netdev shark 2>/dev/null || \
  useradd -m -s "$ZSH_PATH" shark 2>/dev/null || true
fi
echo "shark:shark" | chpasswd
echo "root:shark"  | chpasswd
echo -e "shark\nshark" | passwd shark 2>/dev/null || true

SHADOW_HASH=$(openssl passwd -6 -salt "SharkOS01" "shark" 2>/dev/null || echo "")
if [[ -n "$SHADOW_HASH" ]]; then
  grep -q "^shark:" /etc/shadow 2>/dev/null && \
    sed -i "s|^shark:[^:]*:|shark:${SHADOW_HASH}:|" /etc/shadow || \
    echo "shark:${SHADOW_HASH}:19000:0:99999:7:::" >> /etc/shadow
  usermod -p "$SHADOW_HASH" shark 2>/dev/null || true
fi

grep -q "^shark " /etc/sudoers 2>/dev/null || \
  echo "shark ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
usermod -U shark 2>/dev/null || true
usermod -e "" shark 2>/dev/null || true
mkdir -p /home/shark
chown -R shark:shark /home/shark 2>/dev/null || true

# XSession XFCE
mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/xfce.desktop << 'XSESSION'
[Desktop Entry]
Name=Xfce Session
Comment=Use this session to run Xfce as your desktop environment
Exec=startxfce4
Type=Application
XSESSION
update-alternatives --set x-session-manager /usr/bin/xfce4-session 2>/dev/null || true
echo "   ✅ shark/shark configuré"

# =============================================================================
# 1. LIGHTDM SDDM-STYLE (Garuda utilise SDDM, on émule avec LightDM)
# =============================================================================
echo "[1/8] LightDM SDDM-style..."
apt-get install -y --no-install-recommends \
  lightdm lightdm-gtk-greeter 2>/dev/null || true
apt-get install -y --no-install-recommends \
  slick-greeter 2>/dev/null || true

if [[ -f /usr/share/xgreeters/slick-greeter.desktop ]]; then
  GREETER_SESSION="slick-greeter"
else
  GREETER_SESSION="lightdm-gtk-greeter"
fi

cat > /etc/lightdm/lightdm.conf << EOF
[LightDM]
greeter-session=${GREETER_SESSION}
user-session=xfce
allow-guest=false

[Seat:*]
greeter-show-manual-login=true
greeter-hide-users=false
allow-user-switching=true
EOF

# CSS Garuda-style : fond violet profond, card translucide
cat > /usr/share/lightdm-gtk-greeter-sharkos.css << 'CSS'
/* SharkOS — LightDM Greeter Garuda-style */
#greeter { background: transparent; }

#panel {
    background: linear-gradient(135deg,
        rgba(13, 2, 33, 0.82) 0%,
        rgba(26, 10, 46, 0.78) 100%);
    border: 1px solid rgba(233,69,96,0.30);
    border-radius: 18px;
    padding: 40px 48px 36px;
    box-shadow:
        inset 0 1px 0 rgba(255,255,255,0.10),
        0 40px 80px rgba(0,0,0,0.80),
        0 0 60px rgba(233,69,96,0.08);
    min-width: 420px;
}

entry {
    background: rgba(255,255,255,0.06);
    color: #eefaf8;
    border-radius: 10px;
    border: 1px solid rgba(233,69,96,0.35);
    padding: 13px 16px;
    font-size: 15px;
    box-shadow: inset 0 2px 6px rgba(0,0,0,0.30);
}

entry:focus {
    border-color: rgba(233,69,96,0.80);
    box-shadow: 0 0 0 3px rgba(233,69,96,0.18),
                inset 0 2px 5px rgba(0,0,0,0.20);
}

button, #button-login {
    background: linear-gradient(180deg, #e94560 0%, #b02040 100%);
    color: #fff;
    font-weight: 700;
    border-radius: 50px;
    border: 1px solid rgba(255,255,255,0.20);
    padding: 10px 32px;
    box-shadow: 0 4px 18px rgba(233,69,96,0.50),
                inset 0 1px 0 rgba(255,255,255,0.25);
    min-height: 44px;
}
button:hover {
    background: linear-gradient(180deg, #ff6080 0%, #d03060 100%);
}

label { color: rgba(200,220,240,0.75); font-size: 12px; font-weight: 600; }

#panel-top {
    background: rgba(10,5,25,0.90);
    border-bottom: 1px solid rgba(233,69,96,0.15);
    color: rgba(220,230,255,0.88);
    font-size: 13px;
}
CSS

cat > /etc/lightdm/lightdm-gtk-greeter.conf << EOF
[greeter]
theme-name = Dracula
icon-theme-name = Papirus-Dark
cursor-theme-name = Adwaita
cursor-theme-size = 24
background = ${WALLPAPER_PATH}
user-background = false
font-name = JetBrains Mono 11
clock-format = %H:%M
indicators = ~host;~spacer;~a11y;~clock;~power
position = 50%,center 50%,center
hide-user-image = false
EOF

cp /etc/lightdm/lightdm-gtk-greeter.conf \
   /etc/lightdm/lightdm-gtk-greeter.conf.d/99-sharkos.conf

cat > /etc/lightdm/slick-greeter.conf << EOF
[Greeter]
theme-name = Dracula
icon-theme-name = Papirus-Dark
background = ${WALLPAPER_PATH}
user-background = false
font-name = JetBrains Mono 11
draw-grid = false
show-hostname = true
show-power = true
show-clock = true
clock-format = %H:%M
EOF

systemctl enable lightdm 2>/dev/null || true
systemctl set-default graphical.target 2>/dev/null || true

# =============================================================================
# 2. PANEL XFCE — style Garuda (barre unique en bas style taskbar)
# =============================================================================
echo "[2/8] Panel XFCE Garuda-style..."

mkdir -p "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml"
cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="empty">
    <property name="position"          type="string" value="p=8;x=0;y=0"/>
    <property name="position-locked"   type="bool"   value="true"/>
    <property name="length"            type="uint"   value="100"/>
    <property name="length-adjust"     type="bool"   value="true"/>
    <property name="size"              type="uint"   value="42"/>
    <property name="span-monitors"     type="bool"   value="false"/>
    <property name="background-style"  type="uint"   value="2"/>
    <property name="background-rgba"   type="array">
      <value type="double" value="0.05"/>
      <value type="double" value="0.01"/>
      <value type="double" value="0.13"/>
      <value type="double" value="0.92"/>
    </property>
    <property name="autohide-behavior" type="uint" value="0"/>
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
      <value type="int" value="10"/>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu">
      <property name="show-button-title" type="bool"   value="true"/>
      <property name="button-title"      type="string" value="🦈"/>
      <property name="show-menu-icons"   type="bool"   value="true"/>
    </property>
    <property name="plugin-2" type="string" value="tasklist">
      <property name="flat-buttons"        type="bool" value="true"/>
      <property name="show-labels"         type="bool" value="true"/>
      <property name="grouping"            type="uint" value="1"/>
    </property>
    <property name="plugin-3" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style"  type="uint" value="0"/>
    </property>
    <property name="plugin-4"  type="string" value="systray">
      <property name="show-frame" type="bool" value="false"/>
    </property>
    <property name="plugin-5"  type="string" value="nm-applet"/>
    <property name="plugin-6"  type="string" value="pulseaudio">
      <property name="show-notifications" type="bool" value="true"/>
    </property>
    <property name="plugin-7"  type="string" value="power-manager-plugin"/>
    <property name="plugin-8"  type="string" value="separator">
      <property name="style" type="uint" value="1"/>
    </property>
    <property name="plugin-9"  type="string" value="clock">
      <property name="mode"           type="uint"   value="2"/>
      <property name="digital-format" type="string" value="%H:%M"/>
      <property name="tooltip-format" type="string" value="%A %d %B %Y"/>
    </property>
    <property name="plugin-10" type="string" value="showdesktop"/>
  </property>
</channel>
EOF

# =============================================================================
# 3. GESTIONNAIRE DE FENÊTRES (Picom blur agressif style Garuda)
# =============================================================================
echo "[3/8] Picom blur Garuda-grade..."
apt-get install -y --no-install-recommends picom 2>/dev/null || true

mkdir -p /etc/sharkos
cat > /etc/sharkos/picom.conf << 'PICOM'
# SharkOS Picom — Garuda Dr460nized style
backend = "glx";
glx-no-stencil = true;
glx-copy-from-front = false;
use-damage = true;
vsync = true;

# Opacité
active-opacity   = 1.0;
inactive-opacity = 0.90;
frame-opacity    = 0.85;
opacity-rule = [
  "90:class_g = 'Xfce4-terminal'",
  "92:class_g = 'Thunar'",
  "88:class_g = 'xfce4-panel'",
  "85:class_g = 'Plank'"
];

# BLUR — signature Garuda (dual_kawase strength élevée)
blur-method = "dual_kawase";
blur-strength = 10;
blur-background = true;
blur-background-frame = true;
blur-kern = "3x3box";
blur-background-exclude = [
  "window_type = 'desktop'",
  "class_g = 'slop'",
  "name = 'xfce4-notifyd'"
];

# OMBRES
shadow = true;
shadow-radius  = 28;
shadow-opacity = 0.55;
shadow-offset-x = -14;
shadow-offset-y = -12;
shadow-exclude = [
  "class_g = 'Plank'",
  "window_type = 'dock'",
  "window_type = 'desktop'",
  "_GTK_FRAME_EXTENTS@:c"
];

# FADING
fading = true;
fade-in-step  = 0.03;
fade-out-step = 0.03;
fade-exclude  = [ "class_g = 'slop'" ];

# COINS ARRONDIS (style Garuda)
corner-radius = 14;
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'"
];
PICOM

cat > "$SKEL/.config/autostart/picom.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Picom Compositor
Exec=picom --config /etc/sharkos/picom.conf --experimental-backends
OnlyShowIn=XFCE;
X-XFCE-Autostart-Delay=1
EOF

# =============================================================================
# 4. PLANK DOCK (glassmorphism violet)
# =============================================================================
echo "[4/8] Plank Dock Dragon..."
mkdir -p "$SKEL/.config/plank/dock1/launchers"
mkdir -p /usr/share/plank/themes/SharkDragon

cat > /usr/share/plank/themes/SharkDragon/dock.theme << 'PLANKTHEME'
[PlankTheme]
TopRoundness=10
BottomRoundness=0
LineWidth=1
OuterStrokeColor=rgba(233,69,96,0.25)
FillStartColor=rgba(13,2,33,0.72)
FillEndColor=rgba(26,10,46,0.82)
InnerStrokeColor=rgba(255,255,255,0.07)
BadgeColor=rgba(233,69,96,0.90)
PLANKTHEME

cat > "$SKEL/.config/plank/dock1/settings" << 'EOF'
[PlankDockPreferences]
Position=3
Alignment=3
IconSize=60
ZoomEnabled=true
ZoomPercent=150
HideMode=3
UnhideDelay=0
HideDelay=250
Theme=SharkDragon
Offset=8
Monitor=
LockItems=false
EOF

create_dockitem() {
  local NAME="$1"; shift
  for DIR in /usr/share/applications /usr/local/share/applications; do
    for CAND in "$@"; do
      if [[ -f "$DIR/$CAND" ]]; then
        printf '[PlankDockItemPreferences]\nLauncher=file://%s/%s\n' "$DIR" "$CAND" \
          > "$SKEL/.config/plank/dock1/launchers/${NAME}.dockitem"
        echo "   ✓ $NAME"
        return 0
      fi
    done
  done
  echo "   ⚠ $NAME (non trouvé)"
}

create_dockitem "terminal"   "xfce4-terminal.desktop"
create_dockitem "thunar"     "thunar.desktop"
create_dockitem "browser"    "firefox-esr.desktop" "chromium.desktop"
create_dockitem "vscode"     "code.desktop" "code-oss.desktop"
create_dockitem "lutris"     "net.lutris.Lutris.desktop" "lutris.desktop"
create_dockitem "wireshark"  "wireshark.desktop" "org.wireshark.Wireshark.desktop"
create_dockitem "nmap"       "nmap.desktop" "zenmap.desktop"
create_dockitem "settings"   "xfce4-settings-manager.desktop"

cat > "$SKEL/.config/autostart/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
OnlyShowIn=XFCE;
X-XFCE-Autostart-Override=true
EOF

# =============================================================================
# 5. TERMINAL XFCE (JetBrains Mono, couleurs Dracula)
# =============================================================================
echo "[5/8] Terminal Dracula..."
mkdir -p "$SKEL/.config/xfce4/terminal"
cat > "$SKEL/.config/xfce4/terminal/terminalrc" << 'TERMRC'
[Configuration]
FontName=JetBrains Mono Nerd Font 12
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscCursorBlinks=TRUE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_IBEAM
MiscDefaultGeometry=110x32
MiscMenubarDefault=FALSE
MiscToolbarDefault=FALSE
MiscConfirmClose=FALSE
MiscHighlightUrls=TRUE
BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
BackgroundDarkness=0.90
ColorForeground=#f8f8f2
ColorBackground=#282a36
ColorBold=#ffffff
ColorPalette=#21222c;#ff5555;#50fa7b;#f1fa8c;#bd93f9;#ff79c6;#8be9fd;#f8f8f2;#6272a4;#ff6e6e;#69ff94;#ffffa5;#d6acff;#ff92df;#a4ffff;#ffffff
ColorCursor=#f8f8f2
ColorSelection=#bd93f9
ColorSelectionUseDefault=FALSE
ScrollingBar=TERMINAL_SCROLLBAR_NONE
ScrollingLines=10000
TERMRC

# =============================================================================
# 6. ZSH .zshrc Powerlevel10k (style Garuda)
# =============================================================================
echo "[6/8] .zshrc Powerlevel10k..."

cat > "$SKEL/.zshrc" << 'ZSHRC'
# SharkOS .zshrc — Garuda-style avec Powerlevel10k
# Initialisation P10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
  git
  sudo
  history
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-history-substring-search
  colored-man-pages
  command-not-found
)

source $ZSH/oh-my-zsh.sh 2>/dev/null || true

# Couleurs autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6272a4"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#6272a4"

# ── Aliases Windows (rétrocompatibilité) ──────────────────────────
alias dir='ls'
alias cls='clear'
alias ipconfig='ip addr'
alias ifconfig='ip addr'
alias netstat='ss'
alias tasklist='ps aux'
alias taskkill='kill'
alias del='rm -i'
alias copy='cp'
alias move='mv'
alias md='mkdir -p'
alias rd='rmdir'
alias type='cat'

# ── Outils modernes ───────────────────────────────────────────────
command -v eza  &>/dev/null && alias ls='eza --icons --group-directories-first'
command -v eza  &>/dev/null && alias ll='eza -la --icons --git'
command -v bat  &>/dev/null && alias cat='bat --style=plain'
command -v fd   &>/dev/null && alias find='fd'
command -v rg   &>/dev/null && alias grep='rg'
alias ..='cd ..'
alias ...='cd ../..'
alias q='exit'
alias c='clear'

# ── Sécurité SharkOS ──────────────────────────────────────────────
alias shark-scan='sudo nmap -sV -O'
alias shark-sniff='sudo tcpdump -i any -v'
alias shark-mac='sudo /usr/local/bin/sharkos-mac-randomize'
alias shark-snap='/usr/local/bin/sharkos-snapshot'
alias shark-game='gamemoderun env MANGOHUD=1'
alias shark-update='sudo apt update && sudo apt upgrade -y && flatpak update -y'
alias shark-info='fastfetch 2>/dev/null || neofetch'

# ── Variables ─────────────────────────────────────────────────────
export EDITOR='nano'
export VISUAL='nano'
export MANPAGER='sh -c "col -bx | bat -l man -p"' 2>/dev/null || true
export PATH="$HOME/.local/bin:$PATH"

# ── Bienvenue SharkOS ─────────────────────────────────────────────
if [[ -o interactive ]] && command -v fastfetch &>/dev/null; then
  fastfetch 2>/dev/null
elif [[ -o interactive ]] && command -v neofetch &>/dev/null; then
  neofetch 2>/dev/null
fi

# P10k config
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
ZSHRC

# Copier dans skel
cp "$SKEL/.zshrc" /etc/skel/.zshrc 2>/dev/null || true

# Générer un p10k.zsh minimaliste
cat > /etc/skel/.p10k.zsh << 'P10K'
# SharkOS Powerlevel10k config (style Garuda)

# Mode : Lean (pas de powerline, efficace)
typeset -g POWERLEVEL9K_MODE=nerdfont-complete
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{#e94560}❯%f "

# Segments de gauche
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  os_icon dir vcs
  newline prompt_char
)

# Segments de droite
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status command_execution_time
  background_jobs virtualenv
  context time
)

# Couleurs SharkOS (Dracula)
typeset -g POWERLEVEL9K_DIR_BACKGROUND=5
typeset -g POWERLEVEL9K_DIR_FOREGROUND=0
typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND=2
typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND=3
typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=1
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND='#e94560'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND='#ff5555'
typeset -g POWERLEVEL9K_TIME_FORMAT='%H:%M'
typeset -g POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION='🦈'
P10K

# =============================================================================
# 7. XFWM4 + XSETTINGS (Dracula)
# =============================================================================
echo "[7/8] XFWM4 + Xsettings Dracula..."

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme"             type="string" value="Dracula"/>
    <property name="title_font"        type="string" value="JetBrains Mono Bold 10"/>
    <property name="button_layout"     type="string" value="CMH|O"/>
    <property name="use_compositing"   type="bool"   value="false"/>
    <property name="frame_opacity"     type="int"    value="90"/>
    <property name="inactive_opacity"  type="int"    value="90"/>
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
    <property name="ThemeName"     type="string" value="Dracula"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="DecorationLayout"  type="string" value="close,minimize,maximize:menu"/>
    <property name="FontName"          type="string" value="JetBrains Mono 11"/>
    <property name="MonospaceFontName" type="string" value="JetBrains Mono 11"/>
    <property name="CursorThemeName"   type="string" value="Catppuccin-Mocha-Dark-Cursors"/>
    <property name="CursorThemeSize"   type="int"    value="24"/>
    <property name="FontAntialias"     type="int"    value="1"/>
    <property name="FontHinting"       type="int"    value="1"/>
    <property name="FontHintStyle"     type="string" value="hintslight"/>
    <property name="FontRGBAOrder"     type="string" value="rgb"/>
  </property>
</channel>
EOF

# =============================================================================
# 8. IDENTITÉ + OS-RELEASE
# =============================================================================
echo "[8/8] Identité SharkOS..."

cat > /etc/os-release << 'EOF'
NAME="SharkOS"
VERSION="2.0 (Dragon Edition)"
ID=sharkos
ID_LIKE=debian
PRETTY_NAME="SharkOS 2.0 🦈 Dragon Edition"
VERSION_ID="2.0"
HOME_URL="https://github.com/Simonc44/SharkOS"
VERSION_CODENAME=dragon
ANSI_COLOR="1;35"
EOF

echo "sharkos" > /etc/hostname
cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
127.0.1.1   sharkos sharkos.local
::1         localhost ip6-localhost ip6-loopback
EOF

cat > /etc/default/locale << 'EOF'
LANG=fr_FR.UTF-8
LANGUAGE=fr_FR:fr:en
LC_ALL=fr_FR.UTF-8
EOF
locale-gen fr_FR.UTF-8 2>/dev/null || true
update-locale LANG=fr_FR.UTF-8 2>/dev/null || true

echo ""
echo "✅ [HOOK 30] Bureau Dragon Edition configuré — Powerlevel10k + Dracula + Picom blur"
echo ""
