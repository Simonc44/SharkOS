#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — run-all.sh
# Orchestrate all project-level tests, prints a summary, exits non-zero on fail.
# Usage:  bash tests/run-all.sh
# =============================================================================
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
NC='\033[0m'

echo -e "${PURPLE}🦈=======================================================${NC}"
echo -e "${PURPLE}   SharkOS — Test Suite${NC}"
echo -e "${PURPLE}=======================================================🦈${NC}"
echo ""

TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0
FAILED_TESTS=()
SKIPPED_TESTS=()
DURATION_START=$(date +%s)

for TEST_FILE in tests/test-*.sh; do
  [[ -f "$TEST_FILE" ]] || continue
  TOTAL=$((TOTAL + 1))

  NAME="$(basename "$TEST_FILE" .sh)"
  printf "${CYAN}▶ ${NAME}${NC} ... "
  T_START=$(date +%s)
  bash "$TEST_FILE" >/tmp/sharkos-test.log 2>&1
  RC=$?
  T_END=$(date +%s)
  if (( RC == 0 )); then
    printf "${GREEN}PASS${NC} (%ds)\n" $((T_END - T_START))
    PASSED=$((PASSED + 1))
  elif (( RC == 3 )); then
    # Code 3 = SKIP (test système réel sans ISO/outils) — suite verte, skip compté
    printf "${YELLOW}SKIP${NC} (%ds) — voir log\n" $((T_END - T_START))
    SKIPPED=$((SKIPPED + 1))
    SKIPPED_TESTS+=("$NAME")
    tail -3 /tmp/sharkos-test.log | sed 's/^/    /'
  else
    printf "${RED}FAIL${NC} (%ds)\n" $((T_END - T_START))
    FAILED=$((FAILED + 1))
    FAILED_TESTS+=("$NAME")
    echo -e "  ${YELLOW}--- last lines of ${NAME} output ---${NC}"
    tail -10 /tmp/sharkos-test.log | sed 's/^/    /'
    echo "  ---------------------------------------"
  fi
done

DURATION=$(( $(date +%s) - DURATION_START ))

echo ""
echo -e "${PURPLE}📊 ========================================================${NC}"
echo -e "${PURPLE}   Summary${NC}"
echo -e "${PURPLE}======================================================== 🦈${NC}"
echo -e "  Total tests : ${TOTAL}"
echo -e "  ${GREEN}Passed      : ${PASSED}${NC}"
echo -e "  ${RED}Failed      : ${FAILED}${NC}"
if (( SKIPPED > 0 )); then
  echo -e "  ${YELLOW}Skipped     : ${SKIPPED}${NC} (système réel — ISO/outils requis)"
fi
echo -e "  Duration    : ${DURATION}s"
echo ""

if (( SKIPPED > 0 )); then
  echo -e "${YELLOW}⏭ Tests système réel non exécutés :${NC}"
  for T in "${SKIPPED_TESTS[@]}"; do echo -e "   • ${T}"; done
  echo ""
fi

if (( FAILED > 0 )); then
  echo -e "${RED}🔴 Failed tests:${NC}"
  for T in "${FAILED_TESTS[@]}"; do echo -e "   ❌ ${T}"; done
  echo ""
  echo -e "${RED}🦈 SharkOS test suite FAILED — fix before building the ISO.${NC}"
  exit 1
else
  if (( SKIPPED > 0 )); then
    echo -e "${YELLOW}🟡 Tests passés — ${SKIPPED} test(s) système réel SKIPPÉ(S) (ISO non construite).${NC}"
    echo -e "${YELLOW}   Construis l'ISO puis relance : sudo bash tests/test-boot.sh${NC}"
  else
    echo -e "${GREEN}🟢 All tests passed — SharkOS is ready to build.${NC}"
  fi
  exit 0
fi
