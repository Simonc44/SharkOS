#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — test-configs.sh
# Vérifie la validité des fichiers de configuration : XML, plank, .zshrc.
# =============================================================================
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo -e "${BLUE}🦈 Test configs — XML, plank, .zshrc${NC}"
echo ""

PASS=0; FAIL=0; ISSUES=()

# ── 1. xfce4-panel.xml — XML valide ─────────────────────────────────
echo -e "${BLUE}  1. xfce4-panel.xml${NC}"
XFCE_XML="config/xfce4-panel.xml"
if [[ -f "$XFCE_XML" ]]; then
  if command -v xmllint &>/dev/null; then
    if xmllint --noout "$XFCE_XML" 2>/dev/null; then
      printf "     ${GREEN}✓${NC}  XML valide (xmllint)\n"
      PASS=$((PASS + 1))
    else
      printf "     ${RED}✗${NC}  XML invalide\n"
      ISSUES+=("xfce4-panel.xml — XML invalide")
      FAIL=$((FAIL + 1))
    fi
  elif grep -q "<?xml" "$XFCE_XML" && grep -q "</channel>" "$XFCE_XML"; then
    printf "     ${GREEN}✓${NC}  structure XML présente (xmllint absent)\n"
    PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  balises XML basiques manquantes\n"
    FAIL=$((FAIL + 1))
  fi
else
  printf "     ${YELLOW}⚠${NC}  $XFCE_XML absent\n"
fi

# ── 2. plank.dconf — Position + Zoom ─────────────────────────────────
echo -e "${BLUE}  2. plank.dconf${NC}"
PLANK="config/plank.dconf"
if [[ -f "$PLANK" ]]; then
  if grep -qE "Position=3|position=.bottom." "$PLANK"; then
    printf "     ${GREEN}✓${NC}  Position=3 / position='bottom' (bas)\n"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  Plank pas positionné en bas (Position=3 / position='bottom' absent)\n"
    ISSUES+=("plank.dconf — Plank non en bas")
    FAIL=$((FAIL + 1))
  fi
  if grep -qi "zoom" "$PLANK"; then
    printf "     ${GREEN}✓${NC}  effet Zoom activé\n"; PASS=$((PASS + 1))
  else
    printf "     ${YELLOW}⚠${NC}  effet Zoom absent\n"
    ISSUES+=("plank.dconf — zoom absent")
  fi
  if grep -E -q '\b(SharkDragon|Dracula)\b' "$PLANK"; then
    printf "     ${GREEN}✓${NC}  thème SharkDragon/Dracula référencé\n"; PASS=$((PASS + 1))
  else
    printf "     ${YELLOW}⚠${NC}  thème custom non détecté (optionnel)\n"
  fi
else
  printf "     ${RED}✗${NC}  plank.dconf absent\n"; FAIL=$((FAIL + 1))
fi

# ── 3. .zshrc — clés requises ───────────────────────────────────────
echo -e "${BLUE}  3. config/.zshrc${NC}"
ZSHRC="config/.zshrc"
REQUIRED=(
  "ZSH_THEME="
  "SharkOS"
  "alias dir="
  "alias cls="
  "alias ipconfig="
  "alias sharkscan="
  "alias sharkfw="
  "alias sharkav="
  "alias shark-pulse="
  "alias shark-share="
  "alias shark-fortune="
  "alias shark-tor="
  "shark-eye"
  "shark-encrypt"
)

if [[ -f "$ZSHRC" ]]; then
  Z_PASS=0; Z_FAIL=0
  for KEY in "${REQUIRED[@]}"; do
    if grep -q "$KEY" "$ZSHRC"; then
      Z_PASS=$((Z_PASS + 1))
    else
      printf "     ${RED}✗${NC}  clé manquante : %s\n" "$KEY"
      Z_FAIL=$((Z_FAIL + 1))
    fi
  done
  if (( Z_FAIL == 0 )); then
    printf "     ${GREEN}✓${NC}  toutes les %d clés sont présentes\n" "${#REQUIRED[@]}"
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + Z_FAIL))
  fi
else
  printf "     ${RED}✗${NC}  .zshrc introuvable\n"; FAIL=$((FAIL + 1))
fi

# ── 4. performance-tweaks.conf existe ───────────────────────────────
echo -e "${BLUE}  4. performance-tweaks.conf${NC}"
PT="config/performance-tweaks.conf"
if [[ -f "$PT" ]]; then
  printf "     ${GREEN}✓${NC}  présent (%s lignes)\n" "$(wc -l < $PT)"
  PASS=$((PASS + 1))
else
  printf "     ${YELLOW}⚠${NC}  absent — sysctl sera inline dans les hooks\n"
fi

# ── 5. .zshrc — intégrité des alias (pas de \n littéral) ─────────────
echo -e "${BLUE}  5. config/.zshrc — intégrité des lignes alias${NC}"
if grep -q '\\nalias' "$ZSHRC" 2>/dev/null; then
  printf "     ${RED}✗${NC}  alias fusionnés par un \\n littéral — .zshrc illisible par zsh\n"
  ISSUES+=(".zshrc — alias fusionnés (\\n littéral)")
  FAIL=$((FAIL + 1))
else
  printf "     ${GREEN}✓${NC}  aucun alias fusionné par \\n\n"
  PASS=$((PASS + 1))
fi

# ── 6. Design HyperOS 6.0 — police MiSans + glassmorphism + coins ──
echo -e "${BLUE}  6. Design HyperOS 6.0 (MiSans, picom, rofi, dock)${NC}"
H10="chroot-hooks/10-install-tools.sh"
H20="chroot-hooks/20-apply-theme.sh"
H30="chroot-hooks/30-configure-shell.sh"
H50="chroot-hooks/50-sharkos-finalize.sh"
H60="chroot-hooks/60-sharkos-polish.sh"
DESIGN_OK=0; DESIGN_BAD=0
design_check() {
  local FILE="$1" PATTERN="$2" LABEL="$3" MATCH="$4"
  if grep -q "$PATTERN" "$FILE"; then
    printf "     ${GREEN}✓${NC}  %s\n" "$LABEL"
    DESIGN_OK=$((DESIGN_OK + 1))
  else
    printf "     ${RED}✗${NC}  %s (manquant : %s)\n" "$LABEL" "$PATTERN"
    DESIGN_BAD=$((DESIGN_BAD + 1))
    ISSUES+=("$LABEL")
  fi
}
design_check "$H10" "MiSans"            "Police MiSans (HyperOS) téléchargée (hook 10)" 1
design_check "$H60" "shark-turbo"       "shark-turbo installé (hook 60)" 1
design_check "$H20" "#e0eaff"           "Fond pastel clair HyperOS (hook 20)" 1
design_check "$H20" "WhiteSur-Light"     "Thème GTK clair WhiteSur-Light" 1
design_check "$H30" "corner-radius = 20" "Coins arrondis 20px — signature HyperOS (picom)" 1
design_check "$H30" "blur-strength = 14" "Blur glassmorphism renforcé (picom)" 1
design_check "$H30" "MiSans 11"          "MiSans police par défaut GTK/xsettings" 1
design_check "$H30" "TopRoundness=18"     "Dock Plank glass clair arrondi" 1
design_check "$H30" "Papirus-Light"       "Icônes claires Papirus-Light (xsettings)" 1
design_check "$H30" "rofi -show drun"    "Launcher rofi HyperOS (touche Super)" 1
design_check "$H30" "border-radius.*14"   "Panel XFCE arrondi translucide" 1
design_check "$H50" "conky-hyperos.conf"  "Widgets vivants conky HyperOS" 1
design_check "$H50" "select.png"          "GRUB menu glass arrondi (select.png)" 1
design_check "$H50" "#dbeafe"             "GRUB fond clair HyperOS" 1
design_check "$H60" "shark-turbo {on|off}" "shark-turbo documenté (cheatsheet)" 1
design_check "$H30" "cycle_workspaces"    "Animations workspace XFWM4 (cycle)" 1
design_check "$H30" "zoom_desktop"        "Zoom desktop animé (XFWM4)" 1
design_check "$H60" "shark-anim"          "shark-anim : Compiz scale/cube/wobble" 1
design_check "$H60" "compiz --replace"    "Bascule Compiz réelle (shark-anim)" 1
PASS=$((PASS + DESIGN_OK))
(( DESIGN_BAD > 0 )) && FAIL=$((FAIL + DESIGN_BAD))
echo ""

# ── 7. Sécurité maximale — UFW, AppArmor, hardening sysctl/boot ─────────
echo -e "${BLUE}  7. Sécurité (UFW, AppArmor, hardening)${NC}"
H10="chroot-hooks/10-install-tools.sh"
H40="chroot-hooks/40-cleanup.sh"
BS="scripts/00-bootstrap.sh"
SEC_OK=0; SEC_BAD=0
sec_check() {
  local FILE="$1" PATTERN="$2" LABEL="$3"
  if grep -q "$PATTERN" "$FILE"; then
    printf "     ${GREEN}✓${NC}  %s\n" "$LABEL"
    SEC_OK=$((SEC_OK + 1))
  else
    printf "     ${RED}✗${NC}  %s (manquant : %s)\n" "$LABEL" "$PATTERN"
    SEC_BAD=$((SEC_BAD + 1))
    ISSUES+=("$LABEL")
  fi
}
sec_check "$H40" "ufw default deny incoming" "UFW deny entrant par défaut (hook 40)"
sec_check "$H40" "ufw enable"                "UFW activé au boot"
sec_check "$H40" "apparmor"                  "AppArmor installé + activé"
sec_check "$H40" "limits.d/99-sharkos-hardened" "Core dumps bloqués (limits.conf)"
sec_check "$H40" "avahi-daemon"              "Services inutiles désactivés (avahi, cups…)"
sec_check "$H10" "kernel.dmesg_restrict = 1"  "dmesg restreint (hook 10)"
sec_check "$H10" "kernel.yama.ptrace_scope = 2" "ptrace durci (anti-injection)"
sec_check "$H10" "net.ipv4.tcp_syncookies = 1" "tcp_syncookies (anti-SYN flood)"
sec_check "$H10" "net.ipv4.conf.all.log_martians = 1" "log martians (anti-spoof)"
sec_check "$BS"  "mitigations=on"            "Boot : mitigations CPU actives"
sec_check "$BS"  "page_poison=1"             "Boot : poison pages (durcissement slab)"
sec_check "$BS"  'syslinux-theme "live-build"' "Thème syslinux Debian intégré (sinon thèmes syslinux Ubuntu → build échoue)"
sec_check "$BS"  'linux-packages "linux-image"' "Kernel Debian forcé (sinon linux-generic Ubuntu → build échoue)"
sec_check "$BS"  'initramfs "live-boot"'      "Initramfs Debian live-boot (sinon casper Ubuntu → build échoue)"
sec_check "$BS"  'initsystem "systemd"'      "Initsystem systemd (sinon live-config-upstart Ubuntu → build échoue)"
sec_check "$H50" "shark-extras"              "shark-extras (gros paquets optionnels)"
PASS=$((PASS + SEC_OK))
(( SEC_BAD > 0 )) && FAIL=$((FAIL + SEC_BAD))
echo ""

# ── 8. Configs Calamares — YAML propre (pas de commentaire flèche) ──
echo -e "${BLUE}  8. config/calamares/ — YAML sans commentaire inline invalide${NC}"
YAML_OK=0; YAML_BAD=0
for YF in config/calamares/settings.conf \
          config/calamares/branding/sharkos.desc \
          config/calamares/modules/sharkos-install-cycle.conf; do
  if [[ -f "$YF" ]]; then
    if grep -qE '←|→[[:space:]]+[^#]|\|\s*""' "$YF" 2>/dev/null; then
      printf "     ${RED}✗${NC}  %s — commentaire inline invalide détecté\n" "$YF"
      YAML_BAD=$((YAML_BAD + 1))
    else
      printf "     ${GREEN}✓${NC}  %s propre\n" "$YF"
      YAML_OK=$((YAML_OK + 1))
    fi
  fi
done
PASS=$((PASS + YAML_OK))
(( YAML_BAD > 0 )) && FAIL=$((FAIL + YAML_BAD))

echo ""
echo -e "  Total: $((PASS + FAIL))  |  ${GREEN}Pass: ${PASS}${NC}  |  ${RED}Fail: ${FAIL}${NC}"
if (( FAIL > 0 )); then
  printf "${RED}  Issues:\n"
  for I in "${ISSUES[@]}"; do echo "    • $I"; done
  exit 1
fi
exit 0
