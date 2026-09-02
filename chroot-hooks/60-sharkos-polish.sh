#!/usr/bin/env bash
# =============================================================================
# SharkOS — 60-sharkos-polish.sh  v1.0 (Dragon Edition)
# Polissage final, fonctionnalités inédites additionnelles :
#  - shark-doctor    : diagnostic complet (disk, ram, services, paquets cassés)
#  - shark-firewall  : switch instantané entre profils UFW office/balanced/paranoid
#  - shark-clip      : presse-papiers chiffré avec historique (clipboard securisé)
#  - shark-restore   : restauration des configs SharkOS depuis /etc/sharkos/backups
#  - shark-arc       : archivage intelligent (tar.{zst,xz,gz} auto-détecté)
#  - Plymouth splash enrichi (vraie image PNG en dégradé + mascotte)
#  - GRUB menu : logo texte + séparateurs typographiques Dracula
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 60] Polissage Dragon Edition..."
echo ""

# Outils nécessaires
apt-get install -y --no-install-recommends \
  xclip xsel imagemagick rsyslog logrotate dialog 2>/dev/null || true

# =============================================================================
# 1. shark-doctor — diagnostic complet
# =============================================================================
echo "[1/8] Installation shark-doctor..."
cat > /usr/local/bin/shark-doctor << 'DOC_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Doctor — diagnostic complet du système
PURPLE='\033[1;35m'; CYAN='\033[1;36m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; RESET='\033[0m'

OK_BAD()    { printf "  ${RED}✗${RESET} %s\n" "$1"; ((ISSUES++)); }
OK_GOOD()   { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
OK_WARN()   { printf "  ${YELLOW}⚠${RESET} %s\n" "$1"; }

ISSUES=0
HOST="$(hostname 2>/dev/null || echo sharkos)"
UPT="$(uptime -p 2>/dev/null | sed 's/^up //')"

printf "${PURPLE}🦈====================================================${RESET}\n"
printf "${PURPLE}   Shark-Doctor  •  %s  •  %s${RESET}\n" "$HOST" "$(date '+%Y-%m-%d %H:%M:%S')"
printf "${PURPLE}====================================================🦈${RESET}\n\n"

# Uptime
printf "${CYAN}Uptime${RESET}     : %s\n" "$UPT"

# Kernel & XanMod
KERNEL="$(uname -r 2>/dev/null)"
case "$KERNEL" in
  *xanmod*) OK_GOOD "Kernel XanMod détecté ($KERNEL)" ;;
  *) OK_WARN  "Kernel standard ($KERNEL) — XanMod non actif" ;;
esac

# Disk (racine)
DISK_PCT=$(df --output=pcent / 2>/dev/null | tail -1 | tr -dc '0-9.')
if [[ -z "$DISK_PCT" ]]; then
  OK_BAD "Impossible de lire l'espace disque /"
elif (( DISK_PCT >= 90 )); then
  OK_BAD  "Disque / plein à ${DISK_PCT}% — nettoyer d'urgence"
elif (( DISK_PCT >= 75 )); then
  OK_WARN "Disque / à ${DISK_PCT}% — penser à nettoyer"
else
  OK_GOOD "Disque / à ${DISK_PCT}%"
fi

# RAM swap (ZRAM attendu)
if grep -q zram0 /proc/swaps 2>/dev/null; then
  ZRAM_KB=$(awk '/zram0/{print $3}' /proc/swaps)
  ZRAM_MB=$(( ZRAM_KB / 1024 ))
  OK_GOOD "Zram actif : ${ZRAM_MB} MB en swap compressé"
else
  OK_WARN "Zram inactif (le service sharkos-zram peut être lancé : sudo systemctl start sharkos-zram)"
fi

# BBR TCP
if sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr; then
  OK_GOOD "BBR actif (congestion control moderne)"
else
  OK_WARN "BBR inactif (vérifier /etc/sysctl.d/99-sharkos-performance.conf)"
fi

# Services clés
for SVC in lightdm clamav-freshclam irqbalance thermald nohang sharkos-zram; do
  STATE=$(systemctl is-active "$SVC" 2>/dev/null || echo "inconnu")
  case "$STATE" in
    active) OK_GOOD "Service $SVC actif" ;;
    failed) OK_BAD  "Service $SVC en échec" ;;
    inactive) OK_WARN "Service $SVC inactif" ;;
    *)      [[ "$STATE" != unknown ]] && OK_WARN "Service $SVC : $STATE" ;;
  esac
done

# Paquets cassés / maintenus
BROKEN=$(dpkg --audit 2>/dev/null | grep -c '^' || echo 0)
if (( BROKEN > 0 )); then
  OK_BAD "$BROKEN paquets cassés ou en attente (dpkg --audit)"
else
  OK_GOOD "Aucun paquet cassé détecté"
fi

# Sécurité comptes
if id shark &>/dev/null && [[ "$(getent passwd shark | cut -d: -f6)" == "/home/shark" ]]; then
  OK_GOOD "Compte shark présent avec /home/shark"
else
  OK_BAD "Compte shark manquant ou home incorrect"
fi

# Réseau
if command -v shark-tor &>/dev/null && systemctl is-active tor &>/dev/null; then
  OK_GOOD "Tor en cours de routage"
else
  OK_WARN "Tor inactif"
fi

# Résumé
echo ""
printf "${PURPLE}🦈 Summary :${RESET}\n"
if (( ISSUES == 0 )); then
  printf "${GREEN}  🟢 Tout est en ordre — SharkOS ronronne.${RESET}\n"
else
  printf "${YELLOW}  🟡 ${ISSUES} point(s) à examiner — voir les éléments ⚠/✗ ci-dessus.${RESET}\n"
fi
DOC_EOF
chmod +x /usr/local/bin/shark-doctor
echo "   ✅ shark-doctor (diagnostic complet)"

# =============================================================================
# 2. shark-turbo — mode performance instantané (type HyperOS Turbo)
#    shark-turbo on   → CPU performance + animations off (fluidité maximale)
#    shark-turbo off  → CPU schedutil + animations on (équilibré, économe)
#    shark-turbo      → statut actuel
# =============================================================================
echo "[2/8] Installation shark-turbo..."
cat > /usr/local/bin/shark-turbo << 'TURBO_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Turbo — bascule performance instantanée (HyperOS Turbo mode)
PURPLE='\033[1;35m'; CYAN='\033[1;36m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'

GOV_ON="performance"
GOV_OFF="schedutil"

current_gov() {
  cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "?"
}

set_governor() {
  # Applique le governor sur tous les CPU
  for G in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "$1" > "$G" 2>/dev/null || true
  done
  # Met à jour la config systemd pour persister après reboot
  if command -v systemctl &>/dev/null; then
    sed -i "s/-g [a-z]*/-g $1/" /etc/systemd/system/sharkos-governor.service 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null || true
  fi
}

case "${1:-status}" in
  on)
    set_governor "$GOV_ON"
    # Désactive le compositing lourd en jeu (picom gère unredir lui-même)
    printf "${PURPLE}🦈 Turbo ON${RESET} — CPU ${CYAN}performance${RESET}, latence minimale\n"
    printf "  Governor : %s → %s\n" "$(current_gov)" "$GOV_ON"
    ;;
  off)
    set_governor "$GOV_OFF"
    printf "${PURPLE}🦈 Turbo OFF${RESET} — CPU ${CYAN}schedutil${RESET} (équilibré / économe)\n"
    printf "  Governor : %s → %s\n" "$(current_gov)" "$GOV_OFF"
    ;;
  status|*)
    printf "${PURPLE}🦈 Turbo status${RESET} : governor = ${CYAN}%s${RESET}\n" "$(current_gov)"
    printf "  shark-turbo on   → performance (jeux, latence min)\n"
    printf "  shark-turbo off  → schedutil (quotidien, économe)\n"
    ;;
esac
TURBO_EOF
chmod +x /usr/local/bin/shark-turbo
echo "   ✅ shark-turbo (mode performance instantané)"

# =============================================================================
# 2bis. SHARK-ANIM — animations spectaculaires type HyperOS (Compiz)
#   shark-anim on    → Compiz (scale, cube 3D, wobble, animations fenêtres)
#   shark-anim off   → retour picom (léger, stable, FPS gaming)
# =============================================================================
echo "[2bis/8] shark-anim (animations Compiz type HyperOS)..."
cat > /usr/local/bin/shark-anim << 'ANIM_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Anim — bascule entre animations spectaculaires (Compiz) et
# composition légère (picom). Type HyperOS : fenêtres qui s'ouvrent en
# scale/zoom, cube 3D entre workspaces, wobble, animations de focus.
PURPLE='\033[1;35m'; CYAN='\033[1;36m'; GREEN='\033[1;32m'; RED='\033[1;31m'; RESET='\033[0m'

PICOM_AUTOSTART="$HOME/.config/autostart/picom.desktop"

stop_picom() {
  pkill -f 'picom --config' 2>/dev/null || true
  rm -f "$PICOM_AUTOSTART" 2>/dev/null || true
}

start_compiz() {
  if ! command -v compiz &>/dev/null; then
    printf "${RED}⚠ Compiz absent — installation...${RESET}\n"
    sudo apt-get install -y --no-install-recommends \
      compiz compiz-plugins-default compizconfig-settings-manager 2>/dev/null || \
    { printf "${RED}✗ Compiz indisponible (réseau ?)${RESET}\n"; exit 1; }
  fi
  stop_picom
  # Profil animations HyperOS : scale (fenêtres en zoom), cube 3D, wobble
  mkdir -p "$HOME/.config/autostart"
  cat > "$HOME/.config/autostart/compiz.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Compiz Animations (HyperOS)
Exec=sh -c 'compiz --replace & sleep 1; compiz --replace ccp &'
OnlyShowIn=XFCE;
EOF
  pkill -f 'xfwm4 --daemon' 2>/dev/null || true
  compiz --replace ccp &>/dev/null &
  sleep 2
  # Activer les effets clés (scale, cube, wobble, animations)
  if command -v gsettings &>/dev/null; then
    gsettings set org.compiz.core:/org/compiz/profiles/unity/plugins/core/ \
      active-plugins "[scale, cube, animation, wobbly, expo]" 2>/dev/null || true
  fi
  printf "${PURPLE}🦈 Animations HyperOS ON${RESET} — scale, cube 3D, wobble\n"
}

stop_compiz() {
  pkill -f 'compiz' 2>/dev/null || true
  rm -f "$HOME/.config/autostart/compiz.desktop" 2>/dev/null || true
  # Relancer xfwm4 + picom (léger)
  setsid xfwm4 --daemon &>/dev/null || true
  mkdir -p "$HOME/.config/autostart"
  if [[ -f /etc/sharkos/picom.conf ]]; then
    cat > "$PICOM_AUTOSTART" << 'EOF'
[Desktop Entry]
Type=Application
Name=Picom Compositor
Exec=picom --config /etc/sharkos/picom.conf --experimental-backends
OnlyShowIn=XFCE;
X-XFCE-Autostart-Delay=1
EOF
    sleep 1
    picom --config /etc/sharkos/picom.conf --experimental-backends &>/dev/null &
  fi
  printf "${PURPLE}🦈 Animations OFF${RESET} — picom léger restauré (FPS gaming)\n"
}

case "${1:-}" in
  on)  start_compiz ;;
  off) stop_compiz  ;;
  *)
    printf "${PURPLE}🦈 Shark-Anim — animations type HyperOS${RESET}\n"
    echo "  shark-anim on   → Compiz : scale, cube 3D, wobble (spectaculaire)"
    echo "  shark-anim off  → picom : léger, stable, FPS en jeu"
    ;;
esac
ANIM_EOF
chmod +x /usr/local/bin/shark-anim
echo "   ✅ shark-anim (Compiz : scale/cube/wobble type HyperOS)"

# =============================================================================
# 3. shark-firewall — switch entre profils UFW
# =============================================================================
echo "[3/8] Installation shark-firewall..."
cat > /usr/local/bin/shark-firewall << 'FW_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Firewall — switch instantané entre profils UFW

PROFILES_DIR="/etc/sharkos/firewall-profiles"
mkdir -p "$PROFILES_DIR"

# Création des profils s'ils n'existent pas encore
profile_open() {
  cat << 'RULES'
# Profil OPEN — laisse tout entrer (utile pour tests LAN)
DEFAULT_INPUT_POLICY="ACCEPT"
DEFAULT_OUTPUT_POLICY="ACCEPT"
DEFAULT_FORWARD_POLICY="ACCEPT"
ALLOW_SSH=true
ALLOW_HTTP=true
RULES
}

profile_balanced() {
  cat << 'RULES'
# Profil BALANCED — bloque incoming, autorise outgoing + SSH local
DEFAULT_INPUT_POLICY="DROP"
DEFAULT_OUTPUT_POLICY="ACCEPT"
DEFAULT_FORWARD_POLICY="DROP"
ALLOW_SSH=true
ALLOW_HTTP=false
RULES
}

profile_paranoid() {
  cat << 'RULES'
# Profil PARANOID — bloque tout par défaut, autorise HTTP sortant seulement
DEFAULT_INPUT_POLICY="DROP"
DEFAULT_OUTPUT_POLICY="ACCEPT"
DEFAULT_FORWARD_POLICY="DROP"
ALLOW_SSH=false
ALLOW_HTTP=false
ENABLE_LOG=true
RULES
}

[[ -f "$PROFILES_DIR/open.conf"      ]] || profile_open      > "$PROFILES_DIR/open.conf"
[[ -f "$PROFILES_DIR/balanced.conf"  ]] || profile_balanced  > "$PROFILES_DIR/balanced.conf"
[[ -f "$PROFILES_DIR/paranoid.conf"  ]] || profile_paranoid  > "$PROFILES_DIR/paranoid.conf"

apply_profile() {
  local NAME="$1"
  local FILE="$PROFILES_DIR/$NAME.conf"
  PURPLE='\033[1;35m'; RESET='\033[0m'
  printf "${PURPLE}🦈 Shark-Firewall applies profile : %s${RESET}\n" "$NAME"

  if [[ ! -f "$FILE" ]]; then
    echo "  Profil '$NAME' introuvable dans $PROFILES_DIR"
    echo "  Disponibles : $(ls $PROFILES_DIR | tr '\n' ' ')"
    return 1
  fi

  source "$FILE"
  sudo ufw --force reset >/dev/null 2>&1 || true
  sudo ufw default "$DEFAULT_INPUT_POLICY"  incoming   || true
  sudo ufw default "$DEFAULT_OUTPUT_POLICY" outgoing   || true
  sudo ufw default "$DEFAULT_FORWARD_POLICY" routed    || true
  [[ "${ALLOW_SSH:-false}" == true ]] && sudo ufw allow OpenSSH  || true
  [[ "${ALLOW_HTTP:-false}" == true ]] && sudo ufw allow 80/tcp || true
  [[ "${ENABLE_LOG:-false}" == true ]] && sudo ufw logging on   || true
  sudo ufw --force enable
  sudo ufw status verbose | head -20
}

case "${1:-help}" in
  list)     ls -1 "$PROFILES_DIR" ;;
  status)   sudo ufw status verbose ;;
  open|balanced|paranoid) apply_profile "$1" ;;
  *)
    echo "🦈 Usage : shark-firewall {status|list|open|balanced|paranoid}"
    echo ""
    echo "Profils disponibles :"
    for P in open balanced paranoid; do
      echo "  • $P"
    done
    ;;
esac
FW_EOF
chmod +x /usr/local/bin/shark-firewall
echo "   ✅ shark-firewall (open/balanced/paranoid profiles UFW)"

# =============================================================================
# 4. shark-clip — clipboard chiffré
# =============================================================================
echo "[4/8] Installation shark-clip..."
mkdir -p /etc/sharkos/clip-secure
cat > /usr/local/bin/shark-clip << 'CLIP_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Clip — presse-papiers chiffré (AES-256 + base64) avec historique
CLIP_DIR="/etc/sharkos/clip-secure"
PASS_FILE="$CLIP_DIR/.passphrase"

PURPLE='\033[1;35m'; CYAN='\033[1;36m'; RESET='\033[0m'

init_passphrase() {
  if [[ ! -f "$PASS_FILE" ]]; then
    mkdir -p "$CLIP_DIR"
    head -c 32 /dev/urandom | base64 > "$PASS_FILE"
    chmod 600 "$PASS_FILE"
  fi
}

case "${1:-help}" in
  copy)
    init_passphrase
    CONTENT="$(cat 2>/dev/null || true)"
    if [[ -z "$CONTENT" ]]; then
      echo "Usage: <commande> | shark-clip copy"
      exit 1
    fi
    TS="$(date +%s)"
    echo -n "$CONTENT" | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 \
      -pass "file:$PASS_FILE" -base64 > "$CLIP_DIR/${TS}.enc"
    chmod 600 "$CLIP_DIR/${TS}.enc"
    # Limiter l'historique à 32 entrées
    ls -t "$CLIP_DIR"/*.enc 2>/dev/null | tail -n +33 | xargs -r rm --
    echo "$CONTENT" | xclip -selection clipboard 2>/dev/null || \
    echo "$CONTENT" | xsel --clipboard 2>/dev/null || true
    printf "${PURPLE}🦈 Clip encrypted and stored (id %s)${RESET}\n" "$TS"
    ;;
  list)
    init_passphrase
    printf "${PURPLE}🦈 Clip history (most recent last):${RESET}\n"
    for F in $(ls -t "$CLIP_DIR"/*.enc 2>/dev/null | head -20); do
      ID=$(basename "$F" .enc)
      printf "  ${CYAN}%s${RESET}  " "$(date -d @$ID '+%H:%M:%S' 2>/dev/null || echo $ID)"
      openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass "file:$PASS_FILE" -base64 -in "$F" 2>/dev/null | head -c 60
      echo ""
    done
    ;;
  paste)
    LAST="$(ls -t "$CLIP_DIR"/*.enc 2>/dev/null | head -1)"
    if [[ -z "$LAST" ]]; then
      echo "🦈 Clip vide — shark-clip copy d'abord"; exit 0
    fi
    init_passphrase
    openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass "file:$PASS_FILE" -base64 -in "$LAST" 2>/dev/null
    ;;
  clear)
    rm -f "$CLIP_DIR"/*.enc "$PASS_FILE"
    printf "${PURPLE}🦈 Clip wiped.${RESET}\n"
    ;;
  *)
    echo "Usage : <pipestuff> | shark-clip copy"
    echo "        shark-clip {list|paste|clear}"
    ;;
esac
CLIP_EOF
chmod +x /usr/local/bin/shark-clip
echo "   ✅ shark-clip (clipboard chiffré AES-256, historique 32 items)"

# =============================================================================
# 5. shark-restore — restauration configs depuis /etc/sharkos/backups
# =============================================================================
echo "[5/8] Installation shark-restore..."
mkdir -p /etc/sharkos/backups
cat > /usr/local/bin/shark-restore << 'RESTORE_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Restore — restaure les configs SharkOS depuis /etc/sharkos/backups
BACKUP_DIR="/etc/sharkos/backups"

PURPLE='\033[1;35m'; CYAN='\033[1;36m'; GREEN='\033[1;32m'; RESET='\033[0m'

# Crée une sauvegarde actuelle avant la restauration
make_snapshot() {
  local STAMP="$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_DIR/$STAMP"
  [[ -d /etc/skel/.themes ]] && cp -r /etc/skel/.themes "$BACKUP_DIR/$STAMP/themes" 2>/dev/null
  [[ -f /etc/skel/.zshrc ]]  && cp    /etc/skel/.zshrc   "$BACKUP_DIR/$STAMP/zshrc"  2>/dev/null
  [[ -f /etc/skel/.config/plank/dock1/settings ]] && \
    cp /etc/skel/.config/plank/dock1/settings "$BACKUP_DIR/$STAMP/plank-settings" 2>/dev/null
  [[ -f /etc/lightdm/lightdm.conf.d/50-sharkos-autologin.conf ]] && \
    cp /etc/lightdm/lightdm.conf.d/50-sharkos-autologin.conf "$BACKUP_DIR/$STAMP/lightdm-autologin" 2>/dev/null
  [[ -f /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml ]] && \
    cp /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml "$BACKUP_DIR/$STAMP/xfwm4.xml" 2>/dev/null
  printf "${PURPLE}🦈 Snapshot saved : %s${RESET}\n" "$BACKUP_DIR/$STAMP"
}

case "${1:-menu}" in
  fresh)
    make_snapshot
    echo "🦈 Restauration des défauts SharkOS depuis le repo…"
    sudo cp "$(dirname "$0")/../etc/sharkos/defaults/"*.conf /etc/sharkos/ 2>/dev/null || \
      echo "(repo defaults absents — utiliser 'menu' pour choisir)"
    ;;
  menu|*)
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]]; then
      echo "🦈 Aucune sauvegarde trouvée dans $BACKUP_DIR"
      echo "   L'état actuel est le seul connu."
      exit 0
    fi
    printf "${PURPLE}🦈 Snapshots disponibles :${RESET}\n"
    select SNAP in $(ls -1 "$BACKUP_DIR" | sort -r) "Quitter"; do
      [[ "$SNAP" == "Quitter" ]] && exit 0
      [[ -z "$SNAP" ]] && continue
      make_snapshot
      echo "🦈 Restauration du snapshot $SNAP..."
      [[ -d "$BACKUP_DIR/$SNAP/themes" ]] && cp -r "$BACKUP_DIR/$SNAP/themes" /etc/skel/.themes
      [[ -f "$BACKUP_DIR/$SNAP/zshrc" ]]  && cp    "$BACKUP_DIR/$SNAP/zshrc"  /etc/skel/.zshrc
      printf "${GREEN}✅ Restore complete. Logout/login pour appliquer.${RESET}\n"
      break
    done
    ;;
esac
RESTORE_EOF
chmod +x /usr/local/bin/shark-restore
echo "   ✅ shark-restore (rollback configs SharkOS depuis snapshots)"

# =============================================================================
# 6. shark-arc — archiveur intelligent
# =============================================================================
echo "[6/8] Installation shark-arc..."
cat > /usr/local/bin/shark-arc << 'ARC_EOF'
#!/usr/bin/env bash
# 🦈 Shark-Arc — archivage intelligent (zstd > xz > gz auto)
PURPLE='\033[1;35m'; CYAN='\033[1;36m'; RESET='\033[0m'

usage() {
  cat << 'USAGE'
🦈 Usage:
  shark-arc create <archive_name> <file_or_dir...>
       # auto-detect : zstd si dispo, sinon xz, sinon gz
  shark-arc extract <archive>
  shark-arc list    <archive>
USAGE
  exit 1
}

case "${1:-}" in
  create)
    NAME="${2:-}"; shift 2 || usage
    [[ -z "$NAME" || $# -eq 0 ]] && usage
    if command -v zstd &>/dev/null; then
      EXT="tar.zst"; FLAG=(zstd -T0)
    elif command -v xz &>/dev/null; then
      EXT="tar.xz";  FLAG=(xz -T0)
    else
      EXT="tar.gz";  FLAG=(gzip)
    fi
    ARCHIVE="${NAME%.tar*}"; [[ "$ARCHIVE" == "$NAME" ]] && ARCHIVE="${NAME}.$EXT"
    printf "${PURPLE}🦈 Archiving → %s${RESET}\n" "$ARCHIVE"
    tar -cf - "$@" | "${FLAG[@]}" > "$ARCHIVE"
    ls -lh "$ARCHIVE"
    ;;
  extract)
    ARCH="${2:-}"; [[ -z "$ARCH" ]] && usage
    case "$ARCH" in
      *.tar.zst|*.tzst) tar --zstd -xf "$ARCH" ;;
      *.tar.xz)  tar -xJf "$ARCH" ;;
      *.tar.gz|*.tgz) tar -xzf "$ARCH" ;;
      *.tar.bz2) tar -xjf "$ARCH" ;;
      *.zip)  unzip "$ARCH" ;;
      *.rar)  unrar x "$ARCH" ;;
      *) echo "🦈 Format non reconnu : $ARCH"; exit 1 ;;
    esac
    printf "${PURPLE}🦈 Extracted.${RESET}\n"
    ;;
  list)
    ARCH="${2:-}"; [[ -z "$ARCH" ]] && usage
    case "$ARCH" in
      *.tar.zst|*.tzst) tar --zstd -tf "$ARCH" ;;
      *.tar.xz)  tar -tJf "$ARCH" ;;
      *.tar.gz|*.tgz) tar -tzf "$ARCH" ;;
      *) echo "🦈 Format non reconnu : $ARCH"; exit 1 ;;
    esac
    ;;
  *) usage ;;
esac
ARC_EOF
chmod +x /usr/local/bin/shark-arc
echo "   ✅ shark-arc (zstd > xz > gz auto-détecté)"

# =============================================================================
# 7. Plymouth + GRUB polish
# =============================================================================
echo "[Bonus] Plymouth + GRUB polish..."

if [[ -d /usr/share/plymouth/themes/shark-dragon ]] && command -v convert &>/dev/null; then
  # Logo PNG plus grand et détaillé
  convert -size 800x400 xc:'#0d0221' \
    -fill '#e94560' -stroke '#bd93f9' -strokewidth 4 \
    -font DejaVu-Sans-Bold -pointsize 140 \
    -gravity center -annotate +0-40 '🦈' \
    -fill '#bd93f9' -pointsize 56 \
    -annotate +0+80 'SHARKOS  DRAGON  EDITION' \
    /usr/share/plymouth/themes/shark-dragon/logo.png 2>/dev/null || true

  # Barre de progression néon
  convert -size 240x10 xc:'#282a36' -fill '#44475a' -draw "roundrectangle 0,0 240,10 5,5" \
    /usr/share/plymouth/themes/shark-dragon/progress_box.png 2>/dev/null
  convert -size 240x10 xc:'#e94560' -alpha set -channel A -evaluate set 90% +channel \
    /usr/share/plymouth/themes/shark-dragon/progress_bar.png 2>/dev/null
fi

# GRUB : re-génération d'un fond plus détaillé si Inkscape absent
if command -v convert &>/dev/null; then
  convert -size 1920x1080 xc:'#0d0221' \
    -fill 'rgba(233,69,96,0.20)' -gravity center \
    -font DejaVu-Sans-Bold -pointsize 480 -annotate +0+0 '🦈' \
    -fill 'rgba(189,147,249,0.8)' -gravity south \
    -font DejaVu-Sans-Bold -pointsize 32 \
    -annotate +0+60 'SharkOS Dragon Edition' \
    -fill 'rgba(238,250,248,0.7)' -pointsize 22 \
    -annotate +0+30 '🦈 login: shark / shark' \
    /usr/share/grub/themes/sharkdragon/background.png 2>/dev/null || true
fi

# Post-install cheat-sheet
cat > /etc/sharkos/cheatsheet.txt << 'CHEAT'
═══════════════════════════════════════════════════════════════
🦈 SharkOS Dragon Edition — Post-install cheat-sheet
═══════════════════════════════════════════════════════════════

IDENTIFIANTS  : shark / shark   (sudo NOPASSWD)
ROOT           : root  / shark

── MONITORING / DIAG ────────────────────────────────────────
  shark-pulse                 live CPU/RAM/DISK/NET sparkline
  shark-eye                   tcpdump Dracula-highlighted
  shark-doctor                diagnostic complet
  shark-doctor                lance-le après chaque update

── RÉSEAU / TRANSFERT ───────────────────────────────────────
  shark-radar wlan0           scan Wi-Fi en boucle
  shark-share ~/file          HTTPS + QR code (3 min/utils)
  shark-link 192.168.1.10 a   envoi fichier LAN (nc progress)
  shark-tor {on|off|check}    service Tor toggle

── SÉCURITÉ ────────────────────────────────────────────────
  shark-encrypt secret.txt    produit secret.txt.enc AES-256
  shark-decrypt secret.txt.enc
  shark-tooth sensitive.iso   shredder 3 passes + zero-fill
  shark-clip copy / list      presse-papier chiffré
  shark-clip paste            récupère dernière entrée
  shark-firewall paranoid     profil UFW strict
  shark-firewall open         profil UFW permissif (test)
  shark-quiz                  quiz cybersécurité 10 questions

── PRODUCTIVITÉ ─────────────────────────────────────────────
  shark-update                apt update + flatpak update
  shark-arc create            archiveur zstd > xz > gz
  shark-restore               rollback configs depuis backups
  shark-turbo {on|off}        mode performance instantané (CPU)
  shark-vpn {init|profile}    générateur profil WireGuard
  shark-fortune               quote aléatoire
  shark-info                  neofetch/fastfetch SharkOS

── PREMIER REBOOT ───────────────────────────────────────────
  La machine boote en autologin shark → XFCE Dragon.
  Le menu sharkos-welcome apparaît (clic pour installer en dur).

═══════════════════════════════════════════════════════════════
CHEAT
chmod 644 /etc/sharkos/cheatsheet.txt


# =============================================================================
# 8. INSTALLER + BUNDLE CALAMARES (kit d'installation sur disque)
# =============================================================================
echo "[8/9] Installer SharkOS + bundle Calamares…"

mkdir -p /usr/local/bin /etc/calamares/sharkos/modules \
         /etc/calamares/sharkos/branding /etc/calamares/sharkos/images

# Installer scripts — le VRAI installer/cycle est fourni par 00-bootstrap.sh via
# config/includes.chroot/usr/local/bin/. On n'écrit des versions minimales QUE si
# ces fichiers sont absents (flux sharkos-installer où le repo est rsyncé).
if [[ ! -x /usr/local/bin/sharkos-installer ]]; then
  cat > /usr/local/bin/sharkos-installer << 'INST_EOF'
#!/usr/bin/env bash
# Shark-Installer (stub de secours)
# Source complète : scripts/sharkos-installer du repo Git.
# Ce stub ne doit apparaître que si le vrai installer n'a pas été fourni.
PURPLE="\033[1;35m"; RESET="\033[0m"
printf "${PURPLE}🦈 Shark-Installer${RESET} — lance : sudo sharkos-installer /dev/sdX\n"
printf "         (voir scripts/sharkos-installer dans le repo pour le contenu complet)\n"
printf "         Crée GPT + EFI 260M + root, debootstrap bookworm, lance hooks 10→60\n"
printf "         dans le chroot, GRUB UEFI + BIOS, compte shark/shark.\n"
INST_EOF
  chmod +x /usr/local/bin/sharkos-installer
fi

if [[ ! -x /usr/local/bin/sharkos-install-cycle.sh ]]; then
  cat > /usr/local/bin/sharkos-install-cycle.sh << 'CYC_EOF'
#!/usr/bin/env bash
# Cycle hooks minimal : 10->20->30->40->50->60
for h in /tmp/sharkos-build/chroot-hooks/{10-install-tools,20-apply-theme,30-configure-shell,40-cleanup,50-sharkos-finalize,60-sharkos-polish}.sh; do
  [[ -f "$h" ]] && bash "$h" || echo "⚠ $h absent"
done
CYC_EOF
  chmod +x /usr/local/bin/sharkos-install-cycle.sh
fi

# Calamares config — ne PAS écraser le bundle riche fourni par includes.chroot
if [[ ! -f /etc/calamares/sharkos/settings.conf ]]; then
  cat > /etc/calamares/sharkos/settings.conf << 'CAL_EOF'
--- !CalamaresConfiguration
productName: SharkOS Dragon Edition
version: 2.0
shortVersion: 2.0
displayName: SharkOS Dragon Edition
displayVersion: 2.0
branding: sharkos
brandingShortName: sharkos
modulesSearchPaths:
  - /etc/calamares/sharkos/modules
sequence:
  - welcome
  - locale
  - keyboard
  - partition
  - mount
  - unpackfs
  - machineid
  - fstab
  - sharkos-install-cycle
  - displaymanager
  - network
  - summary
requireConfigVersion: 3
CAL_EOF
fi

if [[ ! -f /etc/calamares/sharkos/modules/sharkos-install-cycle.conf ]]; then
  cat > /etc/calamares/sharkos/modules/sharkos-install-cycle.conf << 'CAL_MOD_EOF'
---
type: "shellprocess"
command: "/usr/local/bin/sharkos-install-cycle.sh"
timeout: 1800
chroot: true
weight: 1000
---
CAL_MOD_EOF
fi

if [[ ! -f /etc/calamares/sharkos/branding/sharkos.desc ]]; then
  cat > /etc/calamares/sharkos/branding/sharkos.desc << 'BRD_EOF'
---
windowTitle: "SharkOS Dragon Edition — Installation"
windowIcon: "sharkos-logo.png"
productName: "SharkOS"
productUrl: "https://github.com/Simonc44/SharkOS"
version: "2.0"
shortVersion: "2.0"
---
BRD_EOF
fi

# Logo Calamares (si ImageMagick dispo dans le chroot build)
if command -v convert &>/dev/null; then
  convert -size 128x128 xc:'#0d0221' -fill '#e94560' \
    -gravity center -font DejaVu-Sans-Bold -pointsize 80 -annotate +0+0 'S' \
    /etc/calamares/sharkos/branding/sharkos-logo.png 2>/dev/null || true
fi

# Wrapper : lance Calamares avec le bundle SharkOS, sinon sharkos-installer
cat > /usr/local/bin/calamares-sharkos-thick << 'WRAP_EOF'
#!/usr/bin/env bash
PURPLE="\033[1;35m"; RESET="\033[0m"
if command -v calamares &>/dev/null && [[ -d /etc/calamares/sharkos ]]; then
  printf "${PURPLE}🦈 Launching Calamares with SharkOS profile${RESET}\n"
  exec calamares -D /etc/calamares/sharkos "$@"
elif [[ -x /usr/local/bin/sharkos-installer ]]; then
  printf "${PURPLE}🦈 Calamares absent — fallback sur sharkos-installer${RESET}\n"
  exec sudo /usr/local/bin/sharkos-installer "$@"
else
  echo "🦈 Ni Calamares ni sharkos-installer disponibles"; exit 1
fi
WRAP_EOF
chmod +x /usr/local/bin/calamares-sharkos-thick

echo "   ✅ /usr/local/bin/sharkos-installer + /etc/calamares/sharkos/ + wrapper"

echo ""
echo "✅ [HOOK 60] Polissage terminé — 5 commandes inédites + Plymouth + GRUB polish."
echo ""


# =============================================================================
# 9. CALAMARES UI POLISH (overwrite prior minimal branding + ship verify-iso)
# =============================================================================
echo "[9/9] Calamares UI polish (QSS Dracula + intro/sidebar HTML + multi-size logos)…"

# Localise le repo SharkOS. Dans le flux sharkos-installer, il est rsyncé dans
# /tmp/sharkos-build ; dans le chroot live-build il est absent (le bundle vient de
# config/includes.chroot, déjà fusionné dans /etc/calamares/sharkos).
SHARKOS_REPO=""
for CAND in /tmp/sharkos-build /build "${ROOT:-}"; do
  if [[ -n "$CAND" && -f "$CAND/config/calamares/branding/sharkos.qss" ]]; then
    SHARKOS_REPO="$CAND"
    break
  fi
done

# Re-ship the rich QSS (overrides any earlier minimal branding)
if [[ -n "$SHARKOS_REPO" ]]; then
  for SRC in \
    config/calamares/branding/sharkos.qss \
    config/calamares/branding/sharkos.desc \
    config/calamares/branding/intro.html \
    config/calamares/branding/sidebar.html; do
    FNAME="$(basename "$SRC")"
    install -m 0644 "$SHARKOS_REPO/$SRC" \
      /etc/calamares/sharkos/branding/"$FNAME" 2>/dev/null || true
  done
fi

# Multi-size logos + splash 1920x1080
if command -v convert &>/dev/null; then
  for SIZE in 16 32 64 128 256 512; do
    convert -size ${SIZE}x${SIZE} xc:'#0d0221' -fill '#e94560' \
      -gravity center -font DejaVu-Sans-Bold -pointsize $((SIZE*7/10)) \
      -annotate +0+0 'S' \
      /etc/calamares/sharkos/branding/sharkos-logo-${SIZE}.png 2>/dev/null || true
  done
  cp /etc/calamares/sharkos/branding/sharkos-logo-128.png \
     /etc/calamares/sharkos/branding/sharkos-logo.png 2>/dev/null || true
  # Splash pleine taille
  convert -size 1920x1080 gradient:'#0d0221-#1a0a2e' \
    -fill 'rgba(233,69,96,0.95)' -gravity center \
    -font DejaVu-Sans-Bold -pointsize 280 -annotate +0-40 '🦈' \
    -fill 'rgba(189,147,249,0.95)' -pointsize 64 \
    -annotate +0+140 'SHARKOS DRAGON EDITION' \
    -fill 'rgba(238,250,248,0.75)' -pointsize 28 \
    -annotate +0+220 '🦈 login: shark / shark' \
    /etc/calamares/sharkos/branding/calamares-splash.png 2>/dev/null || true
fi

# Ship 03-verify-iso.sh dans l'ISO (alias shardé depuis la session live)
if [[ -n "$SHARKOS_REPO" && -f "$SHARKOS_REPO/scripts/03-verify-iso.sh" ]]; then
  install -m 0755 "$SHARKOS_REPO/scripts/03-verify-iso.sh" \
    /usr/local/bin/sharkos-verify-iso
fi

echo "   ✅ Calamares Dracula polish appliqué (QSS, intro, sidebar, splash, multi-logo)"

echo "   [xattr] purge des xattrs du chroot (ACLs posix → squashfs sans table xattr illisible)..."
# 💥 CRITIQUE BOOT : le log QEMU réel montre « unable to read xattr id index
# table » — le squashfs embarquait des xattrs (ACLs posix copiées depuis
# l'hôte Ubuntu, warnings mksquashfs « Unrecognised xattr prefix ») que le
# kernel 6.1 refuse de lire au montage → live-boot ne monte JAMAIS le rootfs
# → pas de cible graphique. Fix : purger TOUS les xattrs du chroot avant la
# création du squashfs → mksquashfs ne stocke aucune table xattr.
if command -v python3 &>/dev/null; then
  python3 - << 'PYEOF'
import os
skip = {'/proc', '/sys', '/dev', '/run', '/tmp', '/var/tmp', '/var/run'}
def purge(path):
    try:
        for x in os.listxattr(path):
            try:
                os.removexattr(path, x)
            except OSError:
                pass
    except OSError:
        pass
count = 0
for root, dirs, files in os.walk('/'):
    # Ne pas descendre dans les pseudo-fs montés
    dirs[:] = [d for d in dirs if os.path.join(root, d) not in skip]
    for name in dirs + files:
        p = os.path.join(root, name)
        purge(p)
        count += 1
print(f"   xattrs purgés sur {count} entrées")
PYEOF
  echo "   ✓ xattrs purgés (squashfs bootable : pas de table xattr à lire)"
else
  echo "   ⚠ python3 absent — xattrs non purgés (risque boot squashfs)"
fi
