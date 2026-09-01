#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — test-wizard.sh
# Vérifie le setup-wizard (config/sharkos-setup-wizard, Python/GTK) :
#   - Syntaxe Python valide (py_compile) + pas de bytes literals non-ASCII
#   - create_user() robuste (chpasswd → passwd --stdin → openssl)
#   - _step_session() met à jour le DROP-IN lightdm.conf.d (prioritaire) ET
#     lightdm.conf — sinon l'autologin resterait sur 'shark' verrouillé
#   - Le nouvel utilisateur rejoint le groupe 'autologin' (règle PAM hook 50)
#   - _step_final() désactive le compte live shark (cohérent : shark réservé)
#   - Noms réservés (root, shark, …) bloqués dans _on_finish
#   - La logique de validation (2 chars min, alnum/_, 6 chars pwd, match)
# =============================================================================
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

WIZ="config/sharkos-setup-wizard"

echo -e "${BLUE}🦈 Test wizard — setup-wizard Python (installation / autologin)${NC}"
echo ""

PASS=0; FAIL=0; ISSUES=()

[[ -f "$WIZ" ]] || { echo -e "${RED}✗ ${WIZ} absent${NC}"; exit 1; }

# ── 1. Syntaxe Python ────────────────────────────────────────────────────────
echo -e "${BLUE}  1. Syntaxe Python (py_compile)${NC}"
if command -v python3 &>/dev/null; then
  if python3 -m py_compile "$WIZ" 2>/tmp/wiz-py.log; then
    printf "     ${GREEN}✓${NC}  compilation OK\n"; PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  erreur de syntaxe :\n"
    sed 's/^/        /' /tmp/wiz-py.log | head -5
    FAIL=$((FAIL + 1))
  fi
  rm -rf config/__pycache__ 2>/dev/null
else
  printf "     ${YELLOW}⚠${NC}  python3 absent — saut du check syntaxe\n"
  PASS=$((PASS + 1))
fi

# ── 2. Pas de bytes literal non-ASCII (b"" avec émojis/─ = SyntaxError) ─────
echo -e "${BLUE}  2. CSS : pas de bytes literal cassé${NC}"
if grep -q '^CSS = (' "$WIZ" && grep -q 'encode()' "$WIZ"; then
  printf "     ${GREEN}✓${NC}  CSS en str UTF-8 encodé au chargement\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  CSS toujours en b\"\"\" — risque de SyntaxError\n"
  FAIL=$((FAIL + 1)); ISSUES+=("CSS en bytes literal non-ASCII")
fi

# ── 3. create_user robuste (3 fallbacks) ─────────────────────────────────────
echo -e "${BLUE}  3. create_user() : chpasswd + fallbacks${NC}"
for KEY in "chpasswd" "passwd.*--stdin" "openssl.*passwd.*-6"; do
  if grep -qE "$KEY" "$WIZ"; then
    printf "     ${GREEN}✓${NC}  %s\n" "$KEY"
    PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  %s absent\n" "$KEY"
    FAIL=$((FAIL + 1))
  fi
done

# ── 4. _step_session : drop-in lightdm.conf.d PRIORITAIRE + conf principal ──
echo -e "${BLUE}  4. Autologin : drop-in conf.d (prioritaire hook 50) + lightdm.conf${NC}"
if grep -q "lightdm.conf.d/50-sharkos-autologin.conf" "$WIZ"; then
  printf "     ${GREEN}✓${NC}  drop-in 50-sharkos-autologin.conf mis à jour\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  drop-in non touché — autologin resterait sur shark verrouillé !\n"
  FAIL=$((FAIL + 1)); ISSUES+=("wizard: drop-in lightdm.conf.d non mis à jour")
fi
if grep -q "autologin-user={self.username}" "$WIZ"; then
  printf "     ${GREEN}✓${NC}  autologin-user pointé vers le nouvel utilisateur\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  autologin-user non réassigné\n"; FAIL=$((FAIL + 1))
fi

# ── 5. Groupe autologin (règle PAM pam_succeed_if du hook 50) ───────────────
echo -e "${BLUE}  5. L'utilisateur rejoint le groupe autologin${NC}"
if grep -q 'usermod.*-aG.*autologin' "$WIZ"; then
  printf "     ${GREEN}✓${NC}  usermod -aG autologin <user>\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  groupe autologin absent — PAM refusera l'autologin\n"
  FAIL=$((FAIL + 1)); ISSUES+=("wizard: user pas dans le groupe autologin")
fi

# ── 6. _step_final verrouille le compte live shark (user final) ─────────────
echo -e "${BLUE}  6. Compte live shark désactivé à la fin (cohérent)${NC}"
if grep -q 'usermod.*-L.*shark' "$WIZ"; then
  printf "     ${GREEN}✓${NC}  usermod -L shark (compte live verrouillé après config)\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  compte shark jamais verrouillé\n"; FAIL=$((FAIL + 1))
fi

# ── 7. Noms réservés bloqués (shark, root, …) ───────────────────────────────
echo -e "${BLUE}  7. Noms réservés${NC}"
for RES in "root" "shark" "daemon"; do
  if grep -qE "\"${RES}\"|'${RES}'" "$WIZ" && grep -q 'Nom réservé' "$WIZ"; then
    printf "     ${GREEN}✓${NC}  %s réservé + message bloquant\n" "$RES"
    PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  %s non listé réservé — risque d'usermod -L sur soi-même\n" "$RES"
    FAIL=$((FAIL + 1))
  fi
done

# ── 8. Validation saisie (2 chars, alnum/_, 6 chars pwd, match) ─────────────
echo -e "${BLUE}  8. Validation des champs${NC}"
for KEY in "Minimum 2 caractères" "Lettres, chiffres et _ uniquement" "6 caractères minimum" "ne correspondent pas"; do
  if grep -qF "$KEY" "$WIZ"; then
    printf "     ${GREEN}✓${NC}  règle : %s\n" "$KEY"
    PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  règle absente : %s\n" "$KEY"
    FAIL=$((FAIL + 1))
  fi
done

# ── 9. Droits root (pkexec) + shebang ───────────────────────────────────────
echo -e "${BLUE}  9. Lancement root + shebang${NC}"
if head -1 "$WIZ" | grep -q "python3"; then
  printf "     ${GREEN}✓${NC}  shebang python3\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  shebang manquant\n"; FAIL=$((FAIL + 1))
fi
if grep -q 'pkexec' "$WIZ"; then
  printf "     ${GREEN}✓${NC}  relance en root via pkexec\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  pas de relance root\n"; FAIL=$((FAIL + 1))
fi

# ── 10. Logo : chemins v1 + v2 présents ─────────────────────────────────────
echo -e "${BLUE}  10. Logo (v1 + v2)${NC}"
for KEY in "sharkos-logo.png" "logo.png"; do
  if grep -qF "$KEY" "$WIZ"; then
    printf "     ${GREEN}✓${NC}  chemin logo %s\n" "$KEY"
    PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  chemin logo %s absent\n" "$KEY"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo -e "  Total: $((PASS + FAIL))  |  ${GREEN}Pass: ${PASS}${NC}  |  ${RED}Fail: ${FAIL}${NC}"
if (( FAIL > 0 )); then
  printf "${RED}  Issues:\n"
  for I in "${ISSUES[@]}"; do echo "    • $I"; done
  exit 1
fi
exit 0