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
  if grep -q "Position=3" "$PLANK"; then
    printf "     ${GREEN}✓${NC}  Position=3 (bas)\n"; PASS=$((PASS + 1))
  else
    printf "     ${YELLOW}⚠${NC}  Position != 3 (Plank non en bas par défaut)\n"
    ISSUES+=("plank.dconf — Position != 3")
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

echo ""
echo -e "  Total: $((PASS + FAIL))  |  ${GREEN}Pass: ${PASS}${NC}  |  ${RED}Fail: ${FAIL}${NC}"
if (( FAIL > 0 )); then
  printf "${RED}  Issues:\n"
  for I in "${ISSUES[@]}"; do echo "    • $I"; done
  exit 1
fi
exit 0
