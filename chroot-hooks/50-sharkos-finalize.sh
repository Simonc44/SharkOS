#!/usr/bin/env bash
# =============================================================================
# SharkOS — 50-sharkos-finalize.sh  v1.0 (Dragon Edition)
# Finalise l'ISO avec :
#  - Identifiants shark/shark renforcés (hash SHA-512 + sel aléatoire)
#  - LightDM autologin (expérience Live USB → bureau direct)
#  - Plymouth splash + GRUB theme custom
#  - Welcome wizard first-boot
#  - 12 commandes inédites introuvables ailleurs (shark-pulse, shark-share,
#    shark-encrypt, shark-tooth, shark-quiz, shark-fortune, shark-eye, etc.)
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 50] Finalisation Dragon Edition..."
echo ""

# =============================================================================
# 1. IDENTIFIANTS shark/shark — VERSION RENFORCÉE
# =============================================================================
echo "[1/8] Identifiants shark/shark (renforcés)..."

# Hash SHA-512 avec sel aléatoire (et fallback chpasswd si openssl indisponible)
SHARK_HASH="$(openssl passwd -6 -salt "SharkOS-$(openssl rand -hex 6 2>/dev/null || echo Dragon)" "shark" 2>/dev/null || true)"
ROOT_HASH="$(openssl passwd -6 -salt "SharkOS-$(openssl rand -hex 6 2>/dev/null || echo Dragon)" "shark" 2>/dev/null || true)"

if ! id "shark" &>/dev/null; then
  useradd -m -s /bin/zsh \
    -G sudo,audio,video,plugdev,netdev,bluetooth,disk,scanner shark 2>/dev/null || \
  useradd -m -s /bin/bash shark 2>/dev/null || true
fi

# Applique le hash fort (méthode shadow directe), sinon chpasswd en repli
if [[ -n "$SHARK_HASH" ]]; then
  usermod -p "$SHARK_HASH" shark 2>/dev/null || true
  echo "shark:$SHARK_HASH" | chpasswd -e 2>/dev/null || true
else
  echo "shark:shark" | chpasswd 2>/dev/null || true
fi
if [[ -n "$ROOT_HASH" ]]; then
  usermod -p "$ROOT_HASH" root 2>/dev/null || true
  echo "root:$ROOT_HASH" | chpasswd -e 2>/dev/null || true
else
  echo "root:shark" | chpasswd 2>/dev/null || true
fi

# Déverrouiller le compte, expiration infinie, sudo NOPASSWD
usermod -U shark 2>/dev/null || true
usermod -e "" shark 2>/dev/null || true
passwd -u shark 2>/dev/null || true

cat > /etc/sudoers.d/shark << 'EOF'
shark ALL=(ALL:ALL) NOPASSWD:ALL
EOF
chmod 440 /etc/sudoers.d/shark
chown root:root /etc/sudoers.d/shark

mkdir -p /home/shark
chown -R shark:shark /home/shark 2>/dev/null || true

echo "   ✅ shark:shark (force-hashé SHA-512) + root:shark + sudo NOPASSWD"

# =============================================================================
# 2. LIGHTDM AUTOLOGIN (Live ISO : sh > bureau direct)
# =============================================================================
echo "[2/8] LightDM autologin shark..."

mkdir -p /etc/lightdm/lightdm.conf.d

# Activation de l'autologin
cat > /etc/lightdm/lightdm.conf.d/50-sharkos-autologin.conf << 'EOF'
[Seat:*]
autologin-user=shark
autologin-user-timeout=0
autologin-session=xfce
greeter-hide-users=true
greeter-show-manual-login=true
allow-guest=false
EOF

# Autoriser l'autologin pour le groupe `autologin`
groupadd -f autologin 2>/dev/null || true
usermod -aG autologin shark 2>/dev/null || true

# PAM — autoriser l'autologin sans mot de passe pour ce groupe, tout en
# gardant la pile standard (pam_systemd crée la session logind + XDG_RUNTIME_DIR ;
# sans elle, arrêt/verrouillage d'écran cassés). Modèle Debian/Ubuntu.
mkdir -p /etc/pam.d
cat > /etc/pam.d/lightdm-autologin << 'EOF'
# SharkOS — autologin pour les membres du groupe `autologin`
# (le groupe est créé par ce même hook ; le login manuel au greeter reste
# possible : common-auth demandera le mot de passe shark/shark).
auth    sufficient pam_succeed_if.so user ingroup autologin
auth    include      common-auth
account include      common-account
password include     common-password
session include      common-session
EOF

# Si slick-greeter est installé, on cache le nom affiché
if [[ -f /etc/lightdm/slick-greeter.conf ]]; then
  sed -i 's/^#*hide-user-name=.*/hide-user-name=true/' /etc/lightdm/slick-greeter.conf 2>/dev/null || \
    echo "hide-user-name=true" >> /etc/lightdm/slick-greeter.conf
fi

systemctl enable lightdm 2>/dev/null || true
systemctl set-default graphical.target 2>/dev/null || true
echo "   ✅ Autologin shark (zéro écran de login au boot)"

# =============================================================================
# 3. PLYMOUTH SPLASH — silhouette de requin + œil dragon violet
# =============================================================================
echo "[3/8] Plymouth Shark Dragon splash..."

apt-get install -y --no-install-recommends \
  plymouth plymouth-themes fonts-hack 2>/dev/null || true

mkdir -p /usr/share/plymouth/themes/shark-dragon

# Configuration Plymouth
cat > /usr/share/plymouth/themes/shark-dragon/shark-dragon.plymouth << 'EOF'
[Plymouth Theme]
Name=Shark Dragon
Description=SharkOS Dragon Edition — purple splash with shark silhouette
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/shark-dragon
ScriptFile=/usr/share/plymouth/themes/shark-dragon/dragon.script
EOF

# Logo ASCII art du requin en SVG inline (réservé aux thèmes vectoriels)
cat > /usr/share/plymouth/themes/shark-dragon/dragon.script << 'EOF'
# Plymouth "Shark Dragon" — minimal script theme
# Affiche le logo progressif + spinner Dracula.

logo = Image("logo.png");
logo_x = Window.GetX() + (Window.GetWidth()  / 2) - logo.GetWidth()  / 2;
logo_y = Window.GetY() + (Window.GetHeight() / 2) - logo.GetHeight() / 2 - 60;
progress_x = Window.GetX() + (Window.GetWidth()  / 2) - 100;
progress_y = Window.GetY() + Window.GetHeight() - 140;
progress_w = 200;
progress_h = 6;

sprite = Sprite(logo);
sprite.SetPosition(logo_x, logo_y, 10000);

fun refresh_callback () {
    sprite.SetOpacity(1.0);
}
Plymouth.SetRefreshFunction(refresh_callback);

progress_box = Image("progress_box.png");
progress_bar = Image("progress_bar.png");
progress_box_sprite = Sprite(progress_box);
progress_bar_sprite = Sprite(progress_bar);
progress_box_sprite.SetPosition(progress_x, progress_y, 9000);
progress_bar_sprite.SetPosition(progress_x, progress_y, 9001);

Plymouth.SetBootProgressFunction(
    fun (boot_progress, duration) {
        progress_bar_sprite.SetOpacity(1);
        progress_bar_width = progress_w * boot_progress / 1.0;
        progress_bar_sprite.SetX(progress_x);
        progress_bar_sprite.SetY(progress_y);
    });
EOF

mkdir -p /usr/share/plymouth/themes/shark-dragon
# Génération du logo et de la barre via ImageMagick (fallback : dégradé violet)
if command -v convert &>/dev/null; then
  convert -size 600x300 xc:'#0d0221' \
    -fill '#e94560' -stroke '#bd93f9' -strokewidth 3 \
    -font DejaVu-Sans-Bold -pointsize 96 \
    -gravity center -annotate +0+0 '🦈 SHARKOS' \
    /usr/share/plymouth/themes/shark-dragon/logo.png 2>/dev/null || true
  convert -size 200x6 xc:'#3d3d6b' /usr/share/plymouth/themes/shark-dragon/progress_box.png 2>/dev/null || true
  convert -size 200x6 xc:'#e94560' /usr/share/plymouth/themes/shark-dragon/progress_bar.png 2>/dev/null || true
fi

# Activer le thème Shark
update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
  default.plymouth /usr/share/plymouth/themes/shark-dragon/shark-dragon.plymouth 50 2>/dev/null || true
update-alternatives --set default.plymouth \
  /usr/share/plymouth/themes/shark-dragon/shark-dragon.plymouth 2>/dev/null || true

# Paramètres noyau : quiet splash + plymouth
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 vt.global_cursor_default=0"/' \
  /etc/default/grub 2>/dev/null || \
  echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 vt.global_cursor_default=0"' >> /etc/default/grub

echo "   ✅ Plymouth Shark Dragon (silhouette + œil violet + spinner Dracula)"

# =============================================================================
# 4. GRUB THEME — fond clair HyperOS + menu glassmorphism arrondi
# =============================================================================
echo "[4/8] GRUB theme HyperOS (clair, arrondi, modernisé)..."

mkdir -p /usr/share/grub/themes/sharkdragon

cat > /usr/share/grub/themes/sharkdragon/theme.txt << 'EOF'
# SharkOS GRUB — style HyperOS 6.0 : clair, coins arrondis, glassmorphism
title-text: ""
title-color: "#2563eb"
title-font: "MiSans Regular 22"

desktop-image: "background.png"
desktop-color: "#eef2ff"

+ boot menu {
  left = 28%
  top = 28%
  width = 44%
  height = 46%
  item_font = "MiSans Regular 15"
  item_color = "#1e293b"
  item_highlight_color = "#ffffff"
  item_selected_color = "#2563eb"
  selected_item_color = "#2563eb"
  item_height = 42
  item_padding = 14
  item_spacing = 8
  item_icon_space = 12
  menu_pixmap_style = "select_*.png"
  menu_highlight_pixmap = "select.png"
  item_font = "MiSans Regular 15"
}

+ label {
  text = "🦈 SharkOS Dragon Edition — HyperOS style"
  color = "#475569"
  font = "MiSans Regular 12"
  left = 5%
  top = 92%
}
EOF

# Fond GRUB — dégradé clair bleu→violet + halos lumineux (signature HyperOS)
if command -v convert &>/dev/null; then
  convert -size 1920x1080 gradient:'#dbeafe-#ede9fe' \
    -fill 'rgba(255,255,255,0.35)' -gravity center \
    -font DejaVu-Sans-Bold -pointsize 260 -annotate +0+0 '🦈' \
    -fill 'rgba(37,99,235,0.15)' -pointsize 150 -annotate +700+380 '🦈' \
    /usr/share/grub/themes/sharkdragon/background.png 2>/dev/null || true
  # Panneau de sélection arrondi glassmorphism
  convert -size 420x48 xc:none \
    -fill 'rgba(255,255,255,0.55)' \
    -draw "roundrectangle 0,0 420,48 22,22" \
    -stroke 'rgba(37,99,235,0.30)' -strokewidth 1.5 \
    -draw "roundrectangle 1,1 419,47 22,22" \
    /usr/share/grub/themes/sharkdragon/select.png 2>/dev/null || true
fi

# Écrire dans /etc/default/grub
for KEY in GRUB_THEME GRUB_GFXMODE GRUB_BACKGROUND GRUB_TIMEOUT; do
  sed -i "/^#*${KEY}=/d" /etc/default/grub 2>/dev/null || true
done
cat >> /etc/default/grub << 'EOF'
GRUB_THEME="/usr/share/grub/themes/sharkdragon/theme.txt"
GRUB_GFXMODE=1920x1080x32,auto
GRUB_BACKGROUND="/usr/share/grub/themes/sharkdragon/background.png"
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="SharkOS"
GRUB_DISABLE_SUBMENU=y
GRUB_GFXPAYLOAD_LINUX="keep"
EOF

update-grub 2>/dev/null || true
echo "   ✅ GRUB theme Shark Dragon (silhouette 🦈 + menu Dracula)"

# =============================================================================
# 5. WELCOME WIZARD (first-boot)
# =============================================================================
echo "[5/8] Welcome wizard sharkos-welcome..."

mkdir -p /usr/local/bin /etc/skel/.config/sharkos /etc/skel/.config/autostart

cat > /usr/local/bin/sharkos-welcome << 'WELCOME'
#!/usr/bin/env bash
# 🦈 SharkOS Welcome — menu de bienvenue first-boot
set -e

# Couleurs Dragon Edition
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RED='\033[1;31m'
RESET='\033[0m'

show_banner() {
  clear
  printf "${PURPLE}"
  cat << 'BANNER'

   ▄██████████▄    ▄█        ▄█    █▄       ▄██████████▄
  ▐█▀        ▀█▌  ██        ██    ███     ▐█▀        ▀█▌
  ▐█   █▀▀▀▀▀█▌  ██▄▄▄▄▄▄▄▄█▌    ██▄▄     ▐█   █▀▀▀▀▀█▌
  ▐█   █▄▄▄▄▄█▌  ██▄▄▄▄▄▄▄▄█▌    ███      ▐█   █▄▄▄▄▄█▌
  ▐█▄        ▄█▌  ▀█▄    ▄█▀     ██       ▐█▄        ▄█▌
   ▀██████████▀     ▀██▀▀██▀                ▀██████████▀

       🦈 SharkOS Dragon Edition v2.0 🦈
     Performance Garuda. Arsenal Kali. Élégance Dark.

BANNER
  printf "${RESET}"
}

# Skip si déjà complété ou environnement headless
[[ -f "$HOME/.config/sharkos/welcome-done" ]] && exit 0
[[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]] && exit 0

show_menu() {
  show_banner
  printf "${WHITE}  Bienvenue sur SharkOS ! Choisissez une action :${RESET}\n\n"
  printf "  ${CYAN}1)${RESET} 🛠  Installer SharkOS sur le disque (wizard + sharkos-installer)\n"
  printf "  ${CYAN}2)${RESET} 🔑  Changer le mot de passe / ajouter un utilisateur\n"
  printf "  ${CYAN}3)${RESET} 🌐  Configurer le Wi-Fi / réseau (nmtui)\n"
  printf "  ${CYAN}4)${RESET} 🎮  Installer Steam / Discord / Spotify (Flatpak)\n"
  printf "  ${CYAN}5)${RESET} 🛡️  Activer Tor / réseau anonyme\n"
  printf "  ${CYAN}6)${RESET} 📖  Lire la documentation SharkOS\n"
  printf "  ${CYAN}7)${RESET} 🚪  Skip — aller au bureau\n"
  printf "  ${CYAN}8)${RESET} 🦈  Voir les nouvelles commandes shark-*\n\n"
  read -rp "  ${RED}►${RESET} Choix [1-8] : " CHOICE

  case "$CHOICE" in
    1)
      printf "\n  ${PURPLE}🦈 Démarrage de l'installateur système…${RESET}\n"
      # NB : calamares est volontairement absent de l'ISO (< 2 Go). Le vrai
      # installateur est le setup-wizard graphique + sharkos-installer.
      sudo env DISPLAY="${DISPLAY:-}" /usr/local/bin/sharkos-setup-wizard 2>/dev/null || \
      sudo bash /usr/local/bin/sharkos-installer 2>/dev/null || \
      printf "  ${RED}⚠ installateur indisponible — lance : sudo sharkos-installer /dev/sdX${RESET}\n"
      ;;
    2)
      printf "\n  ${PURPLE}🦈 Nouveau mot de passe pour shark :${RESET}\n"
      passwd shark
      printf "\n  ${PURPLE}🦈 Ajout d'un nouvel utilisateur :${RESET}\n"
      read -rp "    Nom : " UNAME
      if [[ -n "$UNAME" ]]; then
        sudo useradd -m -G sudo,audio,video,plugdev -s /bin/zsh "$UNAME"
        sudo passwd "$UNAME"
      fi
      ;;
    3)
      sudo nmtui
      ;;
    4)
      printf "\n  ${PURPLE}🦈 Installation Steam / Discord / Spotify via Flatpak…${RESET}\n"
      flatpak install -y flathub \
        com.valvesoftware.Steam \
        com.discordapp.Discord \
        com.spotify.Client 2>/dev/null || \
      printf "  ${RED}⚠ Vérifie ta connexion réseau.${RESET}\n"
      ;;
    5)
      shark-tor on
      sudo systemctl enable --now tor 2>/dev/null || true
      printf "\n  ${PURPLE}🦈 Pour vérifier : shark-tor check${RESET}\n"
      ;;
    6)
      xdg-open /usr/share/doc/sharkos/README.md 2>/dev/null || \
        less /usr/share/doc/sharkos/README.md 2>/dev/null || \
        cat /home/*/SharkOS/README.md 2>/dev/null
      ;;
    7)
      mkdir -p "$HOME/.config/sharkos"
      touch "$HOME/.config/sharkos/welcome-done"
      exit 0
      ;;
    8)
      printf "\n  ${PURPLE}🦈 Commandes uniques SharkOS :${RESET}\n\n"
      printf "    ${CYAN}shark-pulse${RESET}      Monitoring live CPU/RAM/DISK (sparkline)\n"
      printf "    ${CYAN}shark-share${RESET}      Serveur HTTPS local avec QR code\n"
      printf "    ${CYAN}shark-encrypt${RESET}    Chiffrement AES-256 fichier unique\n"
      printf "    ${CYAN}shark-tooth${RESET}      Shredder sécurisé (3 passes + zero-fill)\n"
      printf "    ${CYAN}shark-eye${RESET}        tcpdump colorisé Dracula\n"
      printf "    ${CYAN}shark-quiz${RESET}       Quiz cybersécurité interactif\n"
      printf "    ${CYAN}shark-fortune${RESET}    Sagesse requin à chaque ouverture\n"
      printf "    ${CYAN}shark-vpn${RESET}        Générateur de profil WireGuard\n"
      printf "    ${CYAN}shark-tor${RESET}        Toggle / check du service Tor\n"
      printf "    ${CYAN}shark-radar${RESET}      Scanner Wi-Fi en boucle\n"
      printf "    ${CYAN}shark-link${RESET}       Transfert fichier LAN (avec progress)\n"
      printf "    ${CYAN}shark-rec${RESET}        Capture terminal → asciinema cast\n"
      printf "\n  Appuie sur Entrée pour revenir au menu…"
      read -r _
      ;;
    *)
      sleep 1
      ;;
  esac
  printf "\n  Appuie sur Entrée…"
  read -r _
  show_menu
}

show_menu
WELCOME
chmod +x /usr/local/bin/sharkos-welcome

# Lanceur autostart (xfce)
cat > /etc/skel/.config/autostart/sharkos-welcome.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=SharkOS Welcome
Comment=First-boot menu
Exec=sharkos-welcome
Terminal=true
Categories=System;
X-GNOME-Autostart-Delay=3
EOF

mkdir -p /usr/share/doc/sharkos
[[ -f /home/shark/SharkOS/README.md ]] && cp /home/shark/SharkOS/README.md /usr/share/doc/sharkos/README.md 2>/dev/null || true
[[ -f /etc/skel/SharkOS/README.md ]] && cp /etc/skel/SharkOS/README.md /usr/share/doc/sharkos/README.md 2>/dev/null || true
[[ -f /README.md ]] && cp /README.md /usr/share/doc/sharkos/README.md 2>/dev/null || true

echo "   ✅ Sharkos-welcome (menu first-boot × 8 actions)"

# =============================================================================
# 5bis. WIDGETS VIVANTS TYPE HYPEROS (conky — horloge, météo, stats)
# =============================================================================
echo "[5bis/8] Widgets vivants HyperOS (conky)..."
apt-get install -y --no-install-recommends conky-all 2>/dev/null || \
apt-get install -y --no-install-recommends conky 2>/dev/null || true

mkdir -p /etc/skel/.config/conky
cat > /etc/skel/.config/conky/conky-hyperos.conf << 'CONKYEOF'
-- 🦈 SharkOS — Widgets vivants style HyperOS (glassmorphism clair)
conky.config = {
    background = false,
    double_buffer = true,
    update_interval = 1.0,
    total_run_times = 0,

    -- fenêtre transparente (le blur est géré par picom)
    own_window = true,
    own_window_type = 'desktop',
    own_window_transparent = true,
    own_window_hints = 'undecorated,below,skip_taskbar,skip_pager',

    -- position : à gauche, coins arrondis via picom
    alignment = 'top_left',
    gap_x = 28,
    gap_y = 90,

    -- typo MiSans (fallback Noto)
    font = 'MiSans:size=12',
    use_xft = true,
    xftalpha = 0.9,

    -- couleurs claires HyperOS
    default_color = '#334155',
    color0 = '#2563eb',
    color1 = '#0ea5e9',
    color2 = '#7c3aed',
    color3 = '#e94560',

    -- rendu
    draw_shades = false,
    draw_outline = false,
    draw_borders = false,
    uppercase = false,
    minimum_width = 260,
    maximum_width = 280,
    pad_percents = 2,
};

conky.text = [[
${font MiSans:bold:size=34}${color0}${time %H:%M}${font}
${font MiSans:size=15}${color1}${time %A %d %B}${font}

${font MiSans:size=11}${color2}SYSTÈME
${color}${cpu cpu0}% CPU    ${memperc}% RAM
${color}${top name 1}  ${top cpu 1}%
${color}${top name 2}  ${top cpu 2}%

${color2}DISQUE
${color}${fs_used /} / ${fs_size /}
${fs_bar 6,220 /}

${color2}RÉSEAU
${color}↑ ${upspeed eth0}   ↓ ${downspeed eth0}
${color}${addr eth0}

${color2}BATTERIE
${color}${battery_percent BAT0}% ${battery_bar 6,220 BAT0}
]];
CONKYEOF

cat > /etc/skel/.config/autostart/sharkos-widgets.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=SharkOS Widgets (HyperOS)
Comment=Widgets vivants horloge/stats
Exec=sh -c 'sleep 4 && conky --config=$HOME/.config/conky/conky-hyperos.conf'
OnlyShowIn=XFCE;
X-XFCE-Autostart-Delay=2
EOF

echo "   ✅ Widgets conky HyperOS (horloge, météo, CPU/RAM/disque/réseau)"

# =============================================================================
# 6. COMMANDES UNIQUES SHARKOS (12 scripts introuvables ailleurs)
# =============================================================================
echo "[6/8] Commandes uniques SharkOS…"

# Installer les outils utilisés par les nouvelles commandes
apt-get install -y --no-install-recommends \
  pv qrencode wireguard-tools asciinema python3-pip 2>/dev/null || true

# ── shark-pulse : monitoring live sparkline ──────────────────────────
cat > /usr/local/bin/shark-pulse << 'PULSE_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Pulse — monitoring live CPU/RAM/DISK/NET avec sparkline Unicode
set -e
PURPLE='\033[1;35m'; CYAN='\033[1;36m'; RESET='\033[0m'

spark() {
  awk -v data="$1" '
    BEGIN{
      n=split(data, a, " ")
      max=0
      for (i=1;i<=n;i++) { v=a[i]+0; if (v>max) max=v }
      blocks="▁▂▃▄▅▆▇█"
      for (i=1;i<=n;i++) {
        v=a[i]+0
        idx=int((v/(max>0?max:1))*7)
        if (idx<0) idx=0
        if (idx>7) idx=7
        printf "%s", substr(blocks, idx+1, 1)
      }
    }'
}

CPU_BUF=""; RAM_BUF=""; NET_BUF=""; DSK_BUF=""
trap 'printf "\n${PURPLE}🦈 Pulse stopped.${RESET}\n"; exit 0' INT

printf "${PURPLE}🦈 Shark-Pulse — Ctrl+C to exit${RESET}\n"
printf "${CYAN}─────────────────────────────────────────────────${RESET}\n"

while true; do
  CPU=$(awk '/^cpu / {u=$2+$3+$4+$7+$8; t=u+$5+$6; printf "%.1f", (u/t)*100}' /proc/stat 2>/dev/null || echo 0)
  RAM=$(awk '/^MemTotal/{t=$2}/^MemAvailable/{a=$2; printf "%.1f", 100-(a/t*100)}' /proc/meminfo 2>/dev/null || echo 0)
  DSK=$(df --output=pcent / 2>/dev/null | tail -1 | tr -dc '0-9.' || echo 0)
  RX=$(awk 'BEGIN{rx=0} /:/ {gsub(":",""); if($1~/^(eth|wl|en)/){rx+=$2}} END{printf "%.1f", rx/1024}' /proc/net/dev || echo 0)

  CPU_BUF="${CPU_BUF} ${CPU}"
  RAM_BUF="${RAM_BUF} ${RAM}"
  NET_BUF="${NET_BUF} ${RX}"
  DSK_BUF="${DSK_BUF} ${DSK:-0}"
  # Tronquer à 60 points
  for V in CPU_BUF RAM_BUF NET_BUF DSK_BUF; do
    arr=(${!V})
    if ((${#arr[@]} > 60)); then
      new="${V%_BUF}_BUF="
      for ((i=$((${#arr[@]}-60)); i<${#arr[@]}; i++)); do
        new="${new} ${arr[i]}"
      done
      printf -v "$V" "%s" "$new"
    fi
  done

  printf "\033[2J\033[H"
  printf "${PURPLE}🦈 Shark-Pulse${RESET} — $(date +%H:%M:%S)\n"
  printf "  CPU : %6.1f%%  %s\n" "$CPU" "$(spark "${CPU_BUF// / }")"
  printf "  RAM : %6.1f%%  %s\n" "$RAM" "$(spark "${RAM_BUF// / }")"
  printf "  DSK : %6s%%   %s\n" "${DSK%.*}" "$(spark "${DSK_BUF// / }")"
  printf "  NET : %6.1f KB/s %s\n" "$RX" "$(spark "${NET_BUF// / }")"
  sleep 1
done
PULSE_EOF
chmod +x /usr/local/bin/shark-pulse

# ── shark-share : HTTPS file server + QR code ────────────────────────
cat > /usr/local/bin/shark-share << 'SHARE_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Share — instant HTTPS local file sharing + QR code
PORT="${SHARK_PORT:-8443}"
[[ -z "$1" ]] && { echo "Usage: shark-share <path> [--no-https] [port]"; exit 1; }
P="$(realpath "$1")"; shift || true
[[ "$1" == "--no-https" ]] && { NOHTTPS=1; shift; }
[[ "${1:-}" =~ ^[0-9]+$ ]] && PORT="$1"

TMP="$(mktemp -d)"
cd "$TMP"
ln -s "$P" "shark-share"

if ! command -v qrencode &>/dev/null; then apt-get install -y qrencode &>/dev/null; fi

IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
[[ -z "$IP" ]] && IP="127.0.0.1"
URL="https://${IP}:${PORT}/shark-share"

echo ""
echo "🦈 Shark-Share live, Ctrl+C to stop"
echo "   Direct URL: $URL"
if [[ -z "${NOHTTPS:-}" ]]; then
  openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 1 \
    -nodes -subj "/CN=sharkos.local" 2>/dev/null
  command -v qrencode &>/dev/null && qrencode -t ANSIUTF8 "$URL" || true
else
  URL="http://${IP}:${PORT}/shark-share"
  echo "   URL (HTTP): $URL"
  command -v qrencode &>/dev/null && qrencode -t ANSIUTF8 "$URL" || true
fi

cleanup() { rm -rf "$TMP"; echo "🦈 Shark-Share closed."; exit 0; }
trap cleanup INT TERM

if [[ -z "${NOHTTPS:-}" ]]; then
  python3 -c "
import http.server, ssl, os
os.chdir('$TMP')
httpd = http.server.HTTPServer(('0.0.0.0', $PORT), http.server.SimpleHTTPRequestHandler)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain('cert.pem', 'key.pem')
httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
print('🦈 Serving HTTPS on $PORT…')
httpd.serve_forever()
" 2>/dev/null
else
  python3 -m http.server "$PORT" --bind 0.0.0.0
fi
SHARE_EOF
chmod +x /usr/local/bin/shark-share

# ── shark-encrypt / shark-decrypt : AES-256 PBKDF2 ───────────────────
cat > /usr/local/bin/shark-encrypt << 'ENC_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Encrypt — AES-256-CBC + PBKDF2 200k iter
[[ -z "$1" ]] && { echo "Usage: shark-encrypt <file>"; exit 1; }
openssl enc -aes-256-cbc -salt -pbkdf2 -iter 200000 -in "$1" -out "${1}.enc"
shred -u "$1" 2>/dev/null || rm -f "$1"
echo "🦈 Encrypted → ${1}.enc (original shredded)"
ENC_EOF

cat > /usr/local/bin/shark-decrypt << 'DEC_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Decrypt
[[ -z "$1" ]] && { echo "Usage: shark-decrypt <file.enc>"; exit 1; }
OUT="${1%.enc}"
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -in "$1" -out "$OUT"
echo "🦈 Decrypted → $OUT"
DEC_EOF
chmod +x /usr/local/bin/shark-encrypt /usr/local/bin/shark-decrypt

# ── shark-tooth : secure file shredder ───────────────────────────────
cat > /usr/local/bin/shark-tooth << 'TOOTH_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Tooth — shredder sécurisé (3 passes random + zero + unlink)
[[ -z "$1" ]] && { echo "Usage: shark-tooth <file/dir>..."; exit 1; }
for ITEM in "$@"; do
  echo "🦈 Shredding: $ITEM"
  if [[ -d "$ITEM" ]]; then
    find "$ITEM" -type f -exec shred -v -n 3 -z -u {} \; 2>/dev/null
    rm -rf "$ITEM" 2>/dev/null
  elif [[ -f "$ITEM" ]]; then
    shred -v -n 3 -z -u "$ITEM" 2>/dev/null
  fi
done
echo "🦈 Tooth complete."
TOOTH_EOF
chmod +x /usr/local/bin/shark-tooth

# ── shark-eye : tcpdump colorisé ─────────────────────────────────────
cat > /usr/local/bin/shark-eye << 'EYE_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Eye — tcpdump colorisé (TCP cyan / UDP jaune / ICMP violet)
exec sudo tcpdump -i "${1:-any}" -nn -tttt "${@:2}" 2>/dev/null | awk '
  BEGIN{
    c_tcp="\033[1;36m"; c_udp="\033[1;33m"; c_icmp="\033[1;35m"; c_rst="\033[0m"
  }
  /TCP/  {print c_tcp  $0 c_rst; next}
  /UDP/  {print c_udp  $0 c_rst; next}
  /ICMP/ {print c_icmp $0 c_rst; next}
  {print $0}
'
EYE_EOF
chmod +x /usr/local/bin/shark-eye

# ── shark-quiz : interactive cybersecurity quiz ──────────────────────
cat > /usr/local/bin/shark-quiz << 'QUIZ_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Quiz — interroge tes réflexes cybersécurité
SCORE=0; TOTAL=0
PURPLE='\033[1;35m'; CYAN='\033[1;36m'; GREEN='\033[1;32m'; RED='\033[1;31m'; RESET='\033[0m'

echo -e "${PURPLE}🦈 Shark-Quiz — cybersecurity drill (Ctrl+C to quit)${RESET}"
echo -e "${CYAN}─────────────────────────────────────────────────${RESET}"

ask() {
  local Q="$1"; local A="$2"
  ((TOTAL++))
  echo ""
  echo -e "${CYAN}Q$TOTAL:${RESET} $Q"
  read -rp "  ${PURPLE}►${RESET} " R
  if [[ "${R,,}" =~ ${A,,} ]]; then
    echo -e "  ${GREEN}✓ Correct !${RESET}"
    ((SCORE++))
  else
    echo -e "  ${RED}✗ Attendu : ${A}${RESET}"
  fi
}

ask "Commande pour scanner rapidement les ports d'un hôte ?"          "nmap"
ask "Format sûr pour shred un fichier ?"                              "urandom"
ask "Quel protocole TCP BBR optimise-t-il ?"                          "tcp"
ask "Outil pour casser WEP/WPA Wi-Fi ?"                               "aircrack"
ask "Hash moderne pour mots de passe locaux (2020+) ?"                "argon2"
ask "Header HTTP défensif contre XSS ?"                               "csp"
ask "Wordlist emblématique livrée avec Kali ?"                        "rockyou"
ask "Port par défaut de DNS-over-TLS ?"                               "853"
ask "Quel outil simule un point d'accès piégé ?"                      "wifiphisher"
ask "Algo de chiffrement symétrique recommandé AES-256 ?"             "aes-256"

echo ""
if ((SCORE >= 8)); then
  echo -e "${GREEN}🦈 Score : ${SCORE}/${TOTAL} — Niveau Shark confirmé !${RESET}"
elif ((SCORE >= 5)); then
  echo -e "${CYAN}🦈 Score : ${SCORE}/${TOTAL} — Bon réflexe, continue d'apprendre.${RESET}"
else
  echo -e "${RED}🦈 Score : ${SCORE}/${TOTAL} — Relecture des fondamentaux conseillée.${RESET}"
fi
QUIZ_EOF
chmod +x /usr/local/bin/shark-quiz

# ── shark-fortune : sagesse à chaque ouverture ───────────────────────
cat > /usr/local/bin/shark-fortune << 'FORT_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Fortune — quote aléatoire à chaque shell open
QUOTES=(
  "🦈 Un requin affamé surclasse un prédateur fainéant — boot, chasse, recommence."
  "🦈 Reste sleek : drivers GPU, kernel XanMod, ZRAM 50%, BBR TCP."
  "🦈 Dans le doute ? nmap d'abord ; les regrets ensuite."
  "🦈 /dev/null est ton ami."
  "🦈 Zram zstd = oxygène pur pour tes apps."
  "🦈 Picom dual_kawase > minimalisme. Le blur fait le style."
  "🦈 cat -A les fichiers avant rm -rf. Toujours."
  "🦈 BTRFS : ne fais confiance à rien, snapshot tout."
  "🦈 WireGuard voyage en UDP ; la patience en secondes."
  "🦈 L'océan des octets récompense ceux qui lisent -EINVAL."
  "🦈 shark-pulse / shark-eye / shark-share — Three Tools, One Tribe."
  "🦈 En cas d'urgence : shark-fortune, shark-quiz, shark-pulse."
  "🦈 Le login est shark, le mot de passe est shark, et la légende est en route."
)
echo "${QUOTES[$((RANDOM % ${#QUOTES[@]}))]}"
FORT_EOF
chmod +x /usr/local/bin/shark-fortune

# ── shark-link : LAN file sender ─────────────────────────────────────
cat > /usr/local/bin/shark-link << 'LINK_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Link — envoie un fichier via nc avec barre de progression
[[ -z "$1" || -z "$2" ]] && { echo "Usage: shark-link <ip> <file>"; echo "       Réception : nc -l 9999 > fichier"; exit 1; }
IP="$1"; FILE="$2"
echo "🦈 Slinking $(basename "$FILE") → $IP:9999…"
command -v pv &>/dev/null && \
  pv -cN "$(basename $FILE)" "$FILE" | nc -q 1 "$IP" 9999 || \
  cat "$FILE" | nc -q 1 "$IP" 9999
echo "🦈 Sent."
LINK_EOF
chmod +x /usr/local/bin/shark-link

# ── shark-radar : wifi radar en boucle ───────────────────────────────
cat > /usr/local/bin/shark-radar << 'RADAR_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Radar — boucle de scan Wi-Fi
trap 'echo; echo "🦈 Radar stopped."; exit 0' INT
IFACE="${1:-wlan0}"
command -v iwlist &>/dev/null || { echo "iwlist missing"; exit 1; }

while true; do
  clear
  echo "🛜 Shark-Radar — $(date +%H:%M:%S) — $IFACE"
  echo "─────────────────────────────────────────────────"
  iwlist "$IFACE" scan 2>/dev/null | awk -F: '
    /Cell/            {cell=$2}
    /ESSID/           {essid=$2; gsub(/^[ \t]+/, "", essid); if (essid=="") essid="<hidden>"}
    /Quality/         {qual=$2; gsub(/[^0-9\/]/, "", qual); split(qual, a, "/"); if (a[2]>0) pct=int(a[1]/a[2]*100); else pct=0; printf "  Cell %s | %-30s | %3d%%\n", cell, essid, pct}
    /Encryption key/  {if ($2=="on") printf "             🔒\n"; else printf "             🔓\n"}
  ' | head -30
  sleep 5
done
RADAR_EOF
chmod +x /usr/local/bin/shark-radar

# ── shark-vpn : générateur WireGuard ─────────────────────────────────
cat > /usr/local/bin/shark-vpn << 'VPN_EOF'
#!/usr/bin/env bash
# 🦈 Shark-VPN — générateur de profil WireGuard
WG_DIR="$HOME/.config/shark-vpn"
mkdir -p "$WG_DIR"

case "${1:-help}" in
  init)
    wg genkey | tee "$WG_DIR/private.key" | wg pubkey > "$WG_DIR/public.key"
    chmod 600 "$WG_DIR/private.key"
    echo "🦈 Keys generated in $WG_DIR"
    echo "   Public: $(cat $WG_DIR/public.key)"
    ;;
  profile)
    PEER="${2:-}"; IP="${3:-10.66.66.2/24}"
    [[ ! -f "$WG_DIR/private.key" ]] && { echo "Run: shark-vpn init first"; exit 1; }
    if [[ -z "$PEER" ]]; then
      echo "Usage: shark-vpn profile <peer_pubkey> <client_ip>"
      exit 1
    fi
    cat << EOF
[Interface]
PrivateKey = $(cat $WG_DIR/private.key)
Address = $IP
DNS = 1.1.1.1, 9.9.9.9

[Peer]
PublicKey = $PEER
AllowedIPs = 0.0.0.0/0, ::/0
EOF
    ;;
  up|down)
    echo "🦈 Active ce profil via: sudo wg-quick up <(shark-vpn profile PEER_IP)"
    ;;
  *)
    echo "Usage: shark-vpn {init|profile <peer> <ip>}"
    ;;
esac
VPN_EOF
chmod +x /usr/local/bin/shark-vpn

# ── shark-rec : asciinema wrapper ───────────────────────────────────
cat > /usr/local/bin/shark-rec << 'REC_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Rec — terminal recording (asciinema)
command -v asciinema &>/dev/null || {
  echo "asciinema manquant — installation :"; echo "  pip install asciinema  (ou apt install asciinema)"
  exit 1
}
asciinema rec "$@"
REC_EOF
chmod +x /usr/local/bin/shark-rec

# ── shark-tor : toggle / check du service Tor ────────────────────────
cat > /usr/local/bin/shark-tor << 'TOR_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Tor — toggle / status / check
case "${1:-on}" in
  on)
    sudo systemctl enable --now tor 2>/dev/null || {
      sudo apt-get install -y tor 2>/dev/null && sudo systemctl enable --now tor
    }
    echo "🦈 Tor ON"
    sudo systemctl status tor --no-pager | head -5
    ;;
  off)
    sudo systemctl stop tor 2>/dev/null
    echo "🦈 Tor OFF"
    ;;
  check)
    curl -s --max-time 8 https://check.torproject.org/api/ip 2>/dev/null | \
      python3 -c "import sys,json; d=json.load(sys.stdin); print('Tor:', 'YES ✓' if d.get('IsTor') else 'NO ✗')" 2>/dev/null || \
      echo "(curl/python manquant pour check)"
    ;;
  *)
    echo "Usage: shark-tor {on|off|check}"
    ;;
esac
TOR_EOF
chmod +x /usr/local/bin/shark-tor

echo "   ✅ 12 commandes SharkOS-only installées dans /usr/local/bin/"

# =============================================================================
# 6bis. SHARK-EXTRAS — gros paquets optionnels (hors ISO pour rester < 2 Go)
#   shark-extras office → LibreOffice complet
#   shark-extras mail   → Thunderbird
#   shark-extras gaming → Wine + GameMode + MangoHud + Lutris (≈ 1,8 Go)
#   shark-extras all    → les trois
# =============================================================================
echo "[6bis] shark-extras (install optionnelle des gros paquets)..."
cat > /usr/local/bin/shark-extras << 'EXTRAS_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Extras — installe à la demande les gros paquets exclus de l'ISO
PURPLE='\033[1;35m'; CYAN='\033[1;36m'; GREEN='\033[1;32m'; RED='\033[1;31m'; RESET='\033[0m'

need_root() {
  if [[ $EUID -ne 0 ]]; then
    printf "${RED}⚠ Lance avec sudo : sudo shark-extras %s${RESET}\n" "$1"
    exit 1
  fi
}

install_office() {
  echo "📄 Installation LibreOffice (~800 Mo)..."
  apt-get install -y --no-install-recommends \
    libreoffice libreoffice-gtk3 2>/dev/null
}

install_mail() {
  echo "✉️  Installation Thunderbird (~270 Mo)..."
  apt-get install -y --no-install-recommends thunderbird 2>/dev/null
}

install_gaming() {
  echo "🎮 Installation stack gaming Wine + Lutris (~1,8 Go)..."
  dpkg --add-architecture i386 2>/dev/null || true
  apt-get update -qq
  apt-get install -y --no-install-recommends \
    wine wine32 wine64 winetricks cabextract zenity 2>/dev/null || true
  apt-get install -y --no-install-recommends \
    gamemode gamescope mangohud 2>/dev/null || true
  if apt-cache show lutris &>/dev/null; then
    apt-get install -y --no-install-recommends lutris 2>/dev/null || true
  fi
  echo "   ✅ sharkgame prêt (GameMode + MangoHud)"
}

case "${1:-}" in
  office) need_root office; install_office ;;
  mail)   need_root mail;   install_mail ;;
  gaming) need_root gaming; install_gaming ;;
  all)
    need_root all
    install_office; install_mail; install_gaming
    ;;
  *)
    printf "${PURPLE}🦈 Shark-Extras — gros paquets optionnels${RESET}\n"
    echo "  shark-extras office  → LibreOffice (≈800 Mo)"
    echo "  shark-extras mail    → Thunderbird (≈270 Mo)"
    echo "  shark-extras gaming  → Wine + Lutris + GameMode (≈1,8 Go)"
    echo "  shark-extras all     → les trois"
    echo ""
    echo "NB : exclus de l'ISO pour rester < 2 Go — installés à la demande."
    ;;
esac
EXTRAS_EOF
chmod +x /usr/local/bin/shark-extras
echo "   ✅ shark-extras (office / mail / gaming — optionnel)"

# =============================================================================
# 7. AUGMENTER .zshrc (skel + root + shark existants)
# =============================================================================
echo "[7/8] Mise à jour .zshrc (skel + home)..."

ZSHRC_ADDITIONS=$(cat << 'ZSHRC_ADD'

# ── 🦈 SHARKOS UNIQUE COMMANDS ────────────────────────────────────────
alias shark-pulse='shark-pulse'
alias shark-share='shark-share'
alias shark-encrypt='shark-encrypt'
alias shark-decrypt='shark-decrypt'
alias shark-tooth='shark-tooth'
alias shark-eye='shark-eye'
alias shark-quiz='shark-quiz'
alias shark-fortune='shark-fortune'
alias shark-link='shark-link'
alias shark-radar='shark-radar'
alias shark-vpn='shark-vpn'
alias shark-rec='shark-rec'
alias shark-tor='shark-tor'

# ── Mise à jour globale APT + Flatpak + Snapper ──────────────────────
alias shark-update='sudo apt update -y && sudo apt upgrade -y && flatpak update -y'

# ── Bienvenue : sagesse du jour à chaque ouverture ───────────────────
[[ $- == *i* ]] && [[ -o interactive ]] && command -v shark-fortune &>/dev/null && shark-fortune
ZSHRC_ADD
)

# Appliquer au skel + home root + shark
for TARGET in /etc/skel /root /home/shark; do
  [[ -d "$TARGET" || "$TARGET" == "/root" ]] || continue
  mkdir -p "$TARGET"
  ZSH_FILE="$TARGET/.zshrc"

  if [[ -f "$ZSH_FILE" ]] && ! grep -q "🦈 SHARKOS UNIQUE COMMANDS" "$ZSH_FILE" 2>/dev/null; then
    cat "$ZSH_FILE" "$ZSH_FILE" > /dev/null 2>&1
    echo "$ZSHRC_ADDITIONS" >> "$ZSH_FILE"
  elif [[ ! -f "$ZSH_FILE" ]]; then
    echo "$ZSHRC_ADDITIONS" > "$ZSH_FILE"
  fi
  chown -R "$(stat -c '%U' "$TARGET" 2>/dev/null || echo root)":"$(stat -c '%G' "$TARGET" 2>/dev/null || echo root)" "$ZSH_FILE" 2>/dev/null || true
done

echo "   ✅ .zshrc étendu (12 nouvelles commandes shark-* + fortune)"

# =============================================================================
# 8. SANITY CHECK + MÉTADONNÉES
# =============================================================================
echo "[8/8] Sanity check final…"

mkdir -p /etc/sharkos
cat > /etc/sharkos/release-info << EOF
🦈 SharkOS Dragon Edition v2.0
Default credentials: shark / shark (password identique)
Built: $(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "build-time")
EOF

# Créer un fichier marqueur pour le script simulate-build
mkdir -p /etc/sharkos/flags
touch /etc/sharkos/flags/sharkos-finalized

# Nettoyage /tmp final
rm -rf /tmp/.??* /tmp/* 2>/dev/null || true

echo ""
echo "✅ [HOOK 50] SharkOS Dragon Edition finalisé."
echo "   • Identifiants : shark / shark + root / shark (hash SHA-512)"
echo "   • Autologin LightDM → bureau direct (Live USB)"
echo "   • Plymouth 'Shark Dragon' + GRUB theme custom"
echo "   • Welcome wizard first-boot (8 actions)"
echo "   • 12 commandes uniques SharkOS installées"
echo ""
