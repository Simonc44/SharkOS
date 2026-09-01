#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — test-hooks.sh
# Vérifie la cohérence entre les hooks présents dans chroot-hooks/ et ceux
# référencés dans scripts/00-bootstrap.sh + scripts/simulate-build.sh.
# =============================================================================
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo -e "${BLUE}🦈 Test hooks — cohérence chroot ↔ bootstrap ↔ simulate${NC}"
echo ""

HOOKS_DIR="chroot-hooks"
BOOTSTRAP="scripts/00-bootstrap.sh"
SIMULATE="scripts/simulate-build.sh"

# 1. Lister les hooks sur disque
echo -e "${BLUE}  1. Hooks présents sur disque :${NC}"
DISK_HOOKS=()
for F in "$HOOKS_DIR"/*.sh; do
  DISK_HOOKS+=("$(basename "$F")")
  printf "     ${GREEN}✓${NC}  %s\n" "$(basename "$F")"
done
echo "     Total : ${#DISK_HOOKS[@]}"

# 2. Extraire les hooks référencés par 00-bootstrap.sh
echo ""
echo -e "${BLUE}  2. Hooks déclarés dans 00-bootstrap.sh :${NC}"
BOOTSTRAP_HOOKS=()
if [[ -f "$BOOTSTRAP" ]]; then
  while IFS= read -r LINE; do
    BOOTSTRAP_HOOKS+=("$(basename "$LINE")")
  done < <(grep -oE 'chroot-hooks/[0-9]+-[a-z0-9-]+\.sh' "$BOOTSTRAP" | sort -u)
  for H in "${BOOTSTRAP_HOOKS[@]}"; do
    printf "     • %s\n" "$H"
  done
fi

# 3. Extraire les hooks référencés par simulate-build.sh (CRITICAL_FILES + SHELL_FILES)
echo ""
echo -e "${BLUE}  3. Hooks déclarés dans simulate-build.sh :${NC}"
SIM_HOOKS=()
if [[ -f "$SIMULATE" ]]; then
  while IFS= read -r LINE; do
    SIM_HOOKS+=("$(basename "$LINE")")
  done < <(grep -oE 'chroot-hooks/[0-9]+-[a-z0-9-]+\.sh' "$SIMULATE" | sort -u)
  for H in "${SIM_HOOKS[@]}"; do
    printf "     • %s\n" "$H"
  done
fi

# 4. Vérifier la cohérence : tous les hooks présents doivent être référencés par les deux
echo ""
echo -e "${BLUE}  4. Cross-validation :${NC}"
PASS=0; FAIL=0
for H in "${DISK_HOOKS[@]}"; do
  IN_BOOT=0; IN_SIM=0
  for B in "${BOOTSTRAP_HOOKS[@]}"; do [[ "$H" == "$B" ]] && IN_BOOT=1; done
  for S in "${SIM_HOOKS[@]}"; do [[ "$H" == "$S" ]] && IN_SIM=1; done

  if (( IN_BOOT == 1 && IN_SIM == 1 )); then
    printf "     ${GREEN}✓${NC}  %-40s bootstrap + simulate\n" "$H"
    PASS=$((PASS + 1))
  else
    (( IN_BOOT == 0 )) && printf "     ${YELLOW}⚠${NC}  %-40s ABSENT du bootstrap loop\n" "$H"
    (( IN_SIM == 0 )) && printf "     ${YELLOW}⚠${NC}  %-40s ABSENT de simulate-build\n" "$H"
    FAIL=$((FAIL + 1))
  fi
done

# 5. Reverse : un hook listé par bootstrap doit exister sur disque
echo ""
echo -e "${BLUE}  5. Reverse check (hooks fantômes) :${NC}"
for B in "${BOOTSTRAP_HOOKS[@]}"; do
  if [[ ! -f "$HOOKS_DIR/$B" ]]; then
    printf "     ${RED}✗${NC}  %-40s référencé par bootstrap mais absent du disque\n" "$B"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo -e "  Total: $((PASS + FAIL))  |  ${GREEN}Pass: ${PASS}${NC}  |  ${RED}Fail: ${FAIL}${NC}"
(( FAIL == 0 )) || exit 1
exit 0
