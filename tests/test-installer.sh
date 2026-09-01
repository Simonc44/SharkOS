#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — test-installer.sh
# Vérifie l'intégration du kit d'installation (sharkos-installer + sharkos-install-cycle
# + bundle Calamares + hook 60 wiring).
# =============================================================================
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo -e "${BLUE}🦈 Test installer — kit sharkos-installer + Calamares${NC}"
echo ""

PASS=0; FAIL=0; ISSUES=()

# ── 1. Script principal sharkos-installer ──────────────────────────
echo -e "${BLUE}  1. scripts/sharkos-installer${NC}"
INST="scripts/sharkos-installer"
if [[ -f "$INST" ]]; then
  printf "     ${GREEN}✓${NC}  présent (%d lignes)\n" "$(wc -l < $INST)"
  PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  %s absent\n" "$INST"; FAIL=$((FAIL + 1)); ISSUES+=("$INST manquant")
fi

if [[ -x "$INST" ]]; then
  printf "     ${GREEN}✓${NC}  exécutable\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  non exécutable — lance : chmod +x %s\n" "$INST"
  FAIL=$((FAIL + 1)); ISSUES+=("$INST non exécutable")
fi

if bash -n "$INST" 2>/dev/null; then
  printf "     ${GREEN}✓${NC}  syntaxe OK\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  erreur syntaxe\n"
  bash -n "$INST" 2>&1 | sed 's/^/        /'
  FAIL=$((FAIL + 1))
fi

# Vérifie que les phases de l'installateur sont présentes
for PHASE_KEY in "debootstrap" "chroot" "grub-install" "fstab"; do
  if grep -q "$PHASE_KEY" "$INST"; then
    printf "     ${GREEN}✓${NC}  phase %s référencée\n" "$PHASE_KEY"
    PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  phase %s absente\n" "$PHASE_KEY"
    FAIL=$((FAIL + 1))
  fi
done

# ── 2. Cycle des hooks (chroot) ───────────────────────────────────
echo -e "${BLUE}  2. scripts/sharkos-install-cycle.sh${NC}"
CYC="scripts/sharkos-install-cycle.sh"
if [[ -f "$CYC" ]]; then
  printf "     ${GREEN}✓${NC}  présent\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  %s absent\n" "$CYC"; FAIL=$((FAIL + 1))
fi

# Vérifie que le cycle référence bien tous les hooks présents sur disque
EXPECTED_HOOKS=(
  "10-install-tools.sh"
  "20-apply-theme.sh"
  "30-configure-shell.sh"
  "40-cleanup.sh"
  "50-sharkos-finalize.sh"
  "60-sharkos-polish.sh"
)
MISSING_HOOKS=0
for H in "${EXPECTED_HOOKS[@]}"; do
  if grep -q "$H" "$CYC"; then
    printf "     ${GREEN}✓${NC}  hook référencé : %s\n" "$H"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  hook NON référencé : %s\n" "$H"; MISSING_HOOKS=$((MISSING_HOOKS + 1))
  fi
done
(( MISSING_HOOKS > 0 )) && FAIL=$((FAIL + MISSING_HOOKS))

# Sanity check : chaque hook listé existe réellement sur disque
echo -e "${BLUE}  3. Croisement cycle ↔ disque${NC}"
for H in "${EXPECTED_HOOKS[@]}"; do
  if [[ -f "chroot-hooks/$H" ]]; then
    printf "     ${GREEN}✓${NC}  chroot-hooks/%s existe\n" "$H"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  chroot-hooks/%s MANQUANT\n" "$H"; FAIL=$((FAIL + 1))
  fi
done

# ── 4. Bundle Calamares (config repo) ──────────────────────────────
echo -e "${BLUE}  4. config/calamares/ (bundle config)${NC}"
CAL_DIR="config/calamares"
REQUIRED_CAL=(
  "settings.conf"
  "modules/sharkos-install-cycle.conf"
)
for F in "${REQUIRED_CAL[@]}"; do
  if [[ -f "$CAL_DIR/$F" ]]; then
    printf "     ${GREEN}✓${NC}  %s\n" "$CAL_DIR/$F"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  %s manquant\n" "$CAL_DIR/$F"; FAIL=$((FAIL + 1))
  fi
done

# ── 5. Welcome wizard pointe vers sharkos-installer / Calamares ─────
echo -e "${BLUE}  5. Welcome wizard hook 50 — fallback chain${NC}"
H50="chroot-hooks/50-sharkos-finalize.sh"
if [[ -f "$H50" ]]; then
  if grep -q "sharkos-installer" "$H50"; then
    printf "     ${GREEN}✓${NC}  sharkos-installer référencé\n"; PASS=$((PASS + 1))
  else
    printf "     ${YELLOW}⚠${NC}  sharkos-installer absent (fallback Calamares seul)\n"
  fi
fi
H60="chroot-hooks/60-sharkos-polish.sh"
if [[ -f "$H60" ]]; then
  for NEEDED in "sharkos-installer" "sharkos-install-cycle.sh" "/etc/calamares/sharkos/settings.conf" "calamares-sharkos-thick"; do
    if grep -q "$NEEDED" "$H60"; then
      printf "     ${GREEN}✓${NC}  %s shipé dans le hook\n" "$NEEDED"; PASS=$((PASS + 1))
    else
      printf "     ${RED}✗${NC}  %s NON shipé par hook 60\n" "$NEEDED"
      FAIL=$((FAIL + 1))
    fi
  done
fi

# ── 6. .zshrc : alias shark-install ─────────────────────────────
echo -e "${BLUE}  6. config/.zshrc — alias shark-install${NC}"
ZSHRC="config/.zshrc"
if grep -q "alias shark-install=" "$ZSHRC"; then
  printf "     ${GREEN}✓${NC}  alias shark-install défini\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  pas d'alias shark-install\n"; FAIL=$((FAIL + 1))
fi

# ── 6b. Régression : hook 60 sans $ROOT indéfini + bootstrap ship le vrai installer ──
echo -e "${BLUE}  6b. Bugs corrigés — hook 60 + bootstrap includes${NC}"
if grep -qE '\$ROOT/'\.\./'\.\./' "$H60" 2>/dev/null; then
  printf "     ${RED}✗${NC}  hook 60 référence \$ROOT (indéfini) — Calamares jamais copié\n"
  FAIL=$((FAIL + 1))
else
  printf "     ${GREEN}✓${NC}  hook 60 sans \$ROOT indéfini\n"; PASS=$((PASS + 1))
fi
if grep -q 'includes.chroot' "scripts/00-bootstrap.sh" && \
   grep -q 'sharkos-installer' "scripts/00-bootstrap.sh"; then
  printf "     ${GREEN}✓${NC}  bootstrap ship le vrai installer via includes.chroot\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  bootstrap ne ship pas le vrai installer\n"; FAIL=$((FAIL + 1))
fi

# ── 7. README mentionne installer/CI ─────────────────────────────
echo -e "${BLUE}  7. README.md — sections installer + CI${NC}"
README="README.md"
if grep -qi "sharkos-installer" "$README"; then
  printf "     ${GREEN}✓${NC}  README mentionne sharkos-installer\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  README n'évoque pas sharkos-installer\n"; FAIL=$((FAIL + 1))
fi
if grep -qi "Calamares" "$README"; then
  printf "     ${GREEN}✓${NC}  README mentionne Calamares\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  README n'évoque pas Calamares\n"; FAIL=$((FAIL + 1))
fi
if grep -qiE "ci\.yml|build-iso" "$README"; then
  printf "     ${GREEN}✓${NC}  README mentionne un workflow CI pour ISO\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  README n'évoque pas la CI ISO\n"; FAIL=$((FAIL + 1))
fi

echo ""
echo -e "  Total: $((PASS + FAIL))  |  ${GREEN}Pass: ${PASS}${NC}  |  ${RED}Fail: ${FAIL}${NC}"

if (( FAIL > 0 )); then
  echo ""
  printf "${RED}  Issues à corriger :${NC}\n"
  for I in "${ISSUES[@]}"; do echo "    • $I"; done
  exit 1
fi
exit 0
