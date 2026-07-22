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
FAILED_TESTS=()
DURATION_START=$(date +%s)

for TEST_FILE in tests/test-*.sh; do
  [[ -f "$TEST_FILE" ]] || continue
  TOTAL=$((TOTAL + 1))

  NAME="$(basename "$TEST_FILE" .sh)"
  printf "${CYAN}▶ ${NAME}${NC} ... "
  T_START=$(date +%s)
  if bash "$TEST_FILE" >/tmp/sharkos-test.log 2>&1; then
    T_END=$(date +%s)
    printf "${GREEN}PASS${NC} (%ds)\n" $((T_END - T_START))
    PASSED=$((PASSED + 1))
  else
    T_END=$(date +%s)
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
echo -e "  Duration    : ${DURATION}s"
echo ""

if (( FAILED > 0 )); then
  echo -e "${RED}🔴 Failed tests:${NC}"
  for T in "${FAILED_TESTS[@]}"; do echo -e "   ❌ ${T}"; done
  echo ""
  echo -e "${RED}🦈 SharkOS test suite FAILED — fix before building the ISO.${NC}"
  exit 1
else
  echo -e "${GREEN}🟢 All tests passed — SharkOS is ready to build.${NC}"
  exit 0
fi
