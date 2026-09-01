#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — test-syntax.sh
# Vérifie que tous les scripts shell du repo passent `bash -n`.
# =============================================================================
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[1;34m'; NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo -e "${BLUE}🦈 Test syntax — bash -n sur tous les scripts .sh${NC}"
echo ""

SCRIPTS=(
  scripts/*.sh
  chroot-hooks/*.sh
  tests/*.sh
)

OK=0
FAIL=0
FAILED=()

for PATTERN in "${SCRIPTS[@]}"; do
  for F in $PATTERN; do
    [[ -f "$F" ]] || continue
    if bash -n "$F" 2>/dev/null; then
      printf "  ${GREEN}✓${NC} %s\n" "$F"
      OK=$((OK + 1))
    else
      printf "  ${RED}✗${NC} %s\n" "$F"
      bash -n "$F" 2>&1 | sed 's/^/      /'
      FAIL=$((FAIL + 1))
      FAILED+=("$F")
    fi
  done
done

echo ""
echo -e "  Total scripts: $((OK + FAIL))  |  ${GREEN}Passed: ${OK}${NC}  |  ${RED}Failed: ${FAIL}${NC}"

if (( FAIL > 0 )); then
  echo ""
  echo -e "${RED}  Failed files:${NC}"
  for F in "${FAILED[@]}"; do echo "    • $F"; done
  exit 1
fi
exit 0
