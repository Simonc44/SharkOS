#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — test-assets.sh
# Vérifie la présence des assets critiques (wallpapers, scripts, hooks).
# =============================================================================
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo -e "${BLUE}🦈 Test assets — fichiers critiques du projet${NC}"
echo ""

CHECK=(
  ".gitignore:file"
  "README.md:file"
  "INSTRUCTIONS.md:file"
  "scripts/00-bootstrap.sh:file"
  "scripts/01-build-iso.sh:file"
  "scripts/02-flash-usb.sh:file"
  "scripts/simulate-build.sh:file"
  "chroot-hooks/10-install-tools.sh:file"
  "chroot-hooks/20-apply-theme.sh:file"
  "chroot-hooks/30-configure-shell.sh:file"
  "chroot-hooks/40-cleanup.sh:file"
  "chroot-hooks/50-sharkos-finalize.sh:file"
  "chroot-hooks/60-sharkos-polish.sh:file"
  "config/.zshrc:file"
  "config/plank.dconf:file"
  "config/xfce4-panel.xml:file"
  "config/performance-tweaks.conf:file"
  "config/garuda-packages.list:file"
  "wallpapers:dir"
  "iso-build:dir"
  ".github/workflows:dir"
)

PASS=0
FAIL=0

for ENTRY in "${CHECK[@]}"; do
  IFS=':' read -r PATH_ TYPE <<< "$ENTRY"
  LABEL="$(printf '%-50s' "$PATH_")"
  if [[ "$TYPE" == "file" ]]; then
    if [[ -f "$PATH_" ]]; then
      printf "  ${GREEN}✓${NC}  file  %s\n" "$LABEL"
      PASS=$((PASS + 1))
    else
      printf "  ${RED}✗${NC}  file  %s  (manquant)\n" "$LABEL"
      FAIL=$((FAIL + 1))
    fi
  elif [[ "$TYPE" == "dir" ]]; then
    if [[ -d "$PATH_" ]]; then
      printf "  ${GREEN}✓${NC}  dir   %s\n" "$LABEL"
      PASS=$((PASS + 1))
    else
      printf "  ${RED}✗${NC}  dir   %s  (manquant)\n" "$LABEL"
      FAIL=$((FAIL + 1))
    fi
  fi
done

# Pas de SVG dans wallpapers/
echo ""
echo -e "${BLUE}  Vérifications additionnelles :${NC}"
SVG_COUNT=$(find wallpapers -maxdepth 2 -name "*.svg" 2>/dev/null | wc -l)
if (( SVG_COUNT == 0 )); then
  printf "  ${GREEN}✓${NC}  Aucun SVG parasite dans wallpapers/\n"
  PASS=$((PASS + 1))
else
  printf "  ${YELLOW}⚠${NC}  %d SVG trouvé(s) dans wallpapers/ (SharkOS préfère les PNG)\n" "$SVG_COUNT"
fi

# Tous les scripts shell sont exécutables
echo ""
echo -e "${BLUE}  Permissions :${NC}"
NON_EXEC=0
for SCRIPT in scripts/*.sh chroot-hooks/*.sh tests/*.sh; do
  if [[ -x "$SCRIPT" ]]; then
    : # OK silencieux pour éviter le bruit
  else
    printf "  ${YELLOW}⚠${NC}  %s (non exécutable — sera fixé par chmod)\n" "$SCRIPT"
    NON_EXEC=$((NON_EXEC + 1))
  fi
done
if (( NON_EXEC == 0 )); then
  printf "  ${GREEN}✓${NC}  Tous les scripts sont exécutables\n"
  PASS=$((PASS + 1))
fi

echo ""
echo -e "  Total: $((PASS + FAIL))  |  ${GREEN}Pass: ${PASS}${NC}  |  ${RED}Fail: ${FAIL}${NC}"
(( FAIL == 0 )) || exit 1
exit 0
