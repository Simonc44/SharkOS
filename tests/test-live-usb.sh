#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — test-live-usb.sh
# Vérifie que la repo supporte bien la création d'une Live USB :
#   - scripts/02-flash-usb.sh existe, exécutable, interactif (OUI obligatoire)
#   - scripts/03-verify-iso.sh existe, listée
#   - 00-bootstrap.sh utilise iso-hybrid (clé USB amorçable)
#   - hooks/wiring cohérents (sharkos-installer + cycle)
#   - CI (build-iso.yml) upload l'ISO + .sha256 comme artefacts
# =============================================================================
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'

cd "$(cd "$(dirname "$0")/.." && pwd)"

echo -e "${BLUE}🦈 Test Live USB readiness${NC}"
echo ""

PASS=0; FAIL=0

# 1. Flash script
echo -e "${BLUE}  1. scripts/02-flash-usb.sh${NC}"
FLASH="scripts/02-flash-usb.sh"
if [[ -f "$FLASH" ]]; then
  printf "     ${GREEN}✓${NC}  présent\n"; PASS=$((PASS + 1))
  if [[ -x "$FLASH" ]]; then
    printf "     ${GREEN}✓${NC}  exécutable\n"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  non exécutable\n"; FAIL=$((FAIL + 1))
  fi
  if bash -n "$FLASH" 2>/dev/null; then
    printf "     ${GREEN}✓${NC}  syntaxe OK\n"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  syntax error\n"; FAIL=$((FAIL + 1))
  fi
  if grep -q "OUI" "$FLASH"; then
    printf "     ${GREEN}✓${NC}  confirmation interactive OUI requise\n"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  pas de confirmation OUI — DANGER\n"; FAIL=$((FAIL + 1))
  fi
  if grep -q "dd if" "$FLASH"; then
    printf "     ${GREEN}✓${NC}  utilise dd (standard pour ISO-hybrid)\n"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  dd absent — comment flashe-t-on l'ISO ?\n"; FAIL=$((FAIL + 1))
  fi
else
  printf "     ${RED}✗${NC}  %s manquant\n" "$FLASH"; FAIL=$((FAIL + 1))
fi

# 2. Verify script
echo -e "${BLUE}  2. scripts/03-verify-iso.sh${NC}"
VERIFY="scripts/03-verify-iso.sh"
if [[ -f "$VERIFY" ]]; then
  printf "     ${GREEN}✓${NC}  présent\n"; PASS=$((PASS + 1))
  if bash -n "$VERIFY" 2>/dev/null; then
    printf "     ${GREEN}✓${NC}  syntaxe OK\n"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  syntax error\n"; FAIL=$((FAIL + 1))
  fi
  # Au moins 4 checks distincts
  for K in "SHA256" "El Torito" "squashfs" "vmlinuz"; do
    if grep -q "$K" "$VERIFY"; then
      printf "     ${GREEN}✓${NC}  check %s référencé\n" "$K"; PASS=$((PASS + 1))
    else
      printf "     ${RED}✗${NC}  check %s absent\n" "$K"; FAIL=$((FAIL + 1))
    fi
  done
else
  printf "     ${RED}✗${NC}  %s manquant\n" "$VERIFY"; FAIL=$((FAIL + 1))
fi

# 3. Bootstrap config
echo -e "${BLUE}  3. Bootstrap iso-hybrid + zstd (USB-flashable?)${NC}"
BS="scripts/00-bootstrap.sh"
if [[ -f "$BS" ]]; then
  if grep -q "iso-hybrid" "$BS"; then
    printf "     ${GREEN}✓${NC}  --binary-images iso-hybrid (flashable USB)\n"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  iso-hybrid absent — l'ISO ne sera pas flashable\n"; FAIL=$((FAIL + 1))
  fi
  if grep -q "zstd" "$BS"; then
    printf "     ${GREEN}✓${NC}  compression zstd (rapide au boot)\n"; PASS=$((PASS + 1))
  else
    printf "     ${YELLOW}⚠${NC}  compression zstd non affirmée\n"
  fi
  if grep -q "non-free" "$BS"; then
    printf "     ${GREEN}✓${NC}  dépôts non-free inclus (drivers Wi-Fi)\n"; PASS=$((PASS + 1))
  else
    printf "     ${YELLOW}⚠${NC}  non-free absent — matériel exotique pourrait ne pas booter\n"
  fi
fi

# 4. CI workflow boot essentials
echo -e "${BLUE}  4. CI workflow build-iso.yml : artefacts ISO + SHA256${NC}"
CI=".github/workflows/build-iso.yml"
if [[ -f "$CI" ]]; then
  if grep -q "SharkOS-Dragon-Edition.iso" "$CI"; then
    printf "     ${GREEN}✓${NC}  ISO uploadé\n"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  ISO non uploadé\n"; FAIL=$((FAIL + 1))
  fi
  if grep -qE '\.sha256' "$CI"; then
    printf "     ${GREEN}✓${NC}  .sha256 uploadé\n"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  .sha256 absent de la CI\n"; FAIL=$((FAIL + 1))
  fi
  if grep -qE "v\*\.\*|v\*" "$CI"; then
    printf "     ${GREEN}✓${NC}  trigger sur tag v*\n"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  trigger sur tag manquant\n"; FAIL=$((FAIL + 1))
  fi
  if grep -q "tests/run-all.sh" "$CI"; then
    printf "     ${GREEN}✓${NC}  tests exécutés avant build\n"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  tests non exécutés en CI\n"; FAIL=$((FAIL + 1))
  fi
fi

# 5. Hook 60 shippe intégrer
echo -e "${BLUE}  5. Hook 60 : installer + Calamares présents${NC}"
H60="chroot-hooks/60-sharkos-polish.sh"
for NEEDED in "sharkos-installer" "sharkos-install-cycle.sh" "settings.conf" "sharkos.qss"; do
  if grep -q "$NEEDED" "$H60"; then
    printf "     ${GREEN}✓${NC}  %s shipé dans hook 60\n" "$NEEDED"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  %s NON shipé par hook 60\n" "$NEEDED"; FAIL=$((FAIL + 1))
  fi
done

# 6. README mentionne verification
echo -e "${BLUE}  6. README mentionne verify et tag-triggered CI${NC}"
if grep -qi "03-verify-iso\|03-verify\|verify-iso\|Live USB" "README.md"; then
  printf "     ${GREEN}✓${NC}  README évoque vérification Live USB\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  README n'évoque pas la vérif\n"; FAIL=$((FAIL + 1))
fi

echo ""
echo -e "  Total: $((PASS + FAIL))  |  ${GREEN}Pass: ${PASS}${NC}  |  ${RED}Fail: ${FAIL}${NC}"
(( FAIL == 0 )) || exit 1
exit 0
