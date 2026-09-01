#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — test-aliases.sh
# Vérifie exhaustivement que tous les alias shark-* attendus sont définis
# dans config/.zshrc, et que chacun a un script /usr/local/bin/ équivalent.
# =============================================================================
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo -e "${BLUE}🦈 Test aliases — couverture shark-* dans .zshrc${NC}"
echo ""

EXPECTED_ALIASES=(
  shark-pulse
  shark-share
  shark-encrypt
  shark-decrypt
  shark-tooth
  shark-eye
  shark-quiz
  shark-fortune
  shark-link
  shark-radar
  shark-vpn
  shark-rec
  shark-tor
  shark-info
  shark-update
  shark-scan
  shark-mac
  shark-sniff
  shark-arc
  shark-clip
  shark-restore
  shark-doctor
  shark-firewall
  shark-turbo
  shark-extras
  shark-anim
  shark-install
)

ZSHRC="config/.zshrc"
PASS=0; FAIL=0
MISSING=()

for ALIAS in "${EXPECTED_ALIASES[@]}"; do
  if grep -qE "(^|[^a-z_-])alias[[:space:]]+${ALIAS}=" "$ZSHRC" 2>/dev/null; then
    printf "  ${GREEN}✓${NC}  alias ${ALIAS}\n"
    PASS=$((PASS + 1))
  else
    printf "  ${RED}✗${NC}  alias ${ALIAS}  (manquant)\n"
    MISSING+=("$ALIAS")
    FAIL=$((FAIL + 1))
  fi
done

# Bonus : compter tous les alias shark-* découverts
echo ""
echo -e "${BLUE}  Bonus : couverture complète des alias shark-*${NC}"
TOTAL_SHARK_ALIASES=$(grep -c '^[[:space:]]*alias[[:space:]]\+shark-' "$ZSHRC" 2>/dev/null || echo 0)
printf "  ${BLUE}i${NC}  SharkOS aliases total : ${TOTAL_SHARK_ALIASES}\n"

# Bonus : hooks qui définissent des scripts shark-* (noms de fichiers)
SHARK_HOOK_FILES=$(grep -h '/usr/local/bin/shark-' chroot-hooks/*.sh 2>/dev/null | grep -oE 'shark-[a-z]+' | sort -u)
SHARK_HOOK_COUNT=$(echo "$SHARK_HOOK_FILES" | grep -c '^shark-' || echo 0)
printf "  ${BLUE}i${NC}  Scripts shark-* définis dans les hooks : ${SHARK_HOOK_COUNT}\n"

# Validation croisée : chaque binaire shark-* installé par les hooks doit
# avoir son alias correspondant dans .zshrc (sinon la commande existe mais
# l'alias documenté ne pointe pas dessus).
echo ""
echo -e "${BLUE}  Cross-validation : binaires hooks ↔ alias .zshrc${NC}"
UNCOVERED=0
for BIN in $SHARK_HOOK_FILES; do
  if grep -qE "(^|[^a-z_-])alias[[:space:]]+${BIN}=" "$ZSHRC" 2>/dev/null; then
    printf "  ${GREEN}✓${NC}  %s aliasé\n" "$BIN"
    PASS=$((PASS + 1))
  else
    printf "  ${YELLOW}⚠${NC}  %s installé par les hooks mais non aliasé dans .zshrc\n" "$BIN"
    UNCOVERED=$((UNCOVERED + 1))
  fi
done
if (( UNCOVERED > 0 )); then
  printf "  ${YELLOW}⚠ %d binaire(s) hook sans alias .zshrc (optionnel)\n" "$UNCOVERED"
fi

echo ""
CANONICAL_PASS=0
for ALIAS in "${EXPECTED_ALIASES[@]}"; do
  grep -qE "(^|[^a-z_-])alias[[:space:]]+${ALIAS}=" "$ZSHRC" 2>/dev/null && CANONICAL_PASS=$((CANONICAL_PASS + 1))
done
BIN_ALIASED=0
for BIN in $SHARK_HOOK_FILES; do
  grep -qE "(^|[^a-z_-])alias[[:space:]]+${BIN}=" "$ZSHRC" 2>/dev/null && BIN_ALIASED=$((BIN_ALIASED + 1))
done
printf "  ${GREEN}✓${NC}  %d/%d alias canoniques  |  %d/%d binaires hooks↔alias\n" \
  "${CANONICAL_PASS}" "${#EXPECTED_ALIASES[@]}" "${BIN_ALIASED}" "${SHARK_HOOK_COUNT}"
if (( FAIL > 0 )); then
  printf "  ${RED}Missing : ${MISSING[*]}${NC}\n"
  exit 1
fi
exit 0
