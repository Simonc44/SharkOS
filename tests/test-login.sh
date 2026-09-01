#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — test-login.sh
# Vérifie la chaîne de login de bout en bout :
#   - Le compte shark est créé avec mot de passe shark/shark (hooks 10/30/50)
#   - root:shark + sudo NOPASSWD (hooks 10/30/50)
#   - L'autologin LightDM pointe vers shark + session xfce (hook 50)
#   - Le PAM lightdm-autologin garde la pile standard (pam_systemd → session
#     logind + XDG_RUNTIME_DIR) au lieu d'un pam_deny cassant la session
#   - Le re-login manuel reste possible après déconnexion (manual-login=true)
#   - Le bureau XFCE + LightDM sont bien dans les paquets installés
#   - chpasswd/useradd sont protégés (ne cassent pas la build sous set -e)
# =============================================================================
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo -e "${BLUE}🦈 Test login — compte shark + autologin LightDM + PAM${NC}"
echo ""

PASS=0; FAIL=0; ISSUES=()

H10="chroot-hooks/10-install-tools.sh"
H30="chroot-hooks/30-configure-shell.sh"
H50="chroot-hooks/50-sharkos-finalize.sh"
BS="scripts/00-bootstrap.sh"

# ── 1. Mot de passe shark:shark + root:shark cohérents dans les 3 hooks ─────
echo -e "${BLUE}  1. Identifiants shark:shark / root:shark (hooks 10/30/50)${NC}"
for H in "$H10" "$H30" "$H50"; do
  if grep -q "shark:shark" "$H" && grep -q "root:shark" "$H"; then
    printf "     ${GREEN}✓${NC}  %s définit shark:shark + root:shark\n" "$(basename "$H")"
    PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  %s ne définit pas shark:shark / root:shark\n" "$(basename "$H")"
    FAIL=$((FAIL + 1))
  fi
done

# ── 2. Compte shark créé (useradd) + hash SHA-512 + déverrouillage ──────────
echo -e "${BLUE}  2. Création du compte (hook 50)${NC}"
if grep -q "useradd.*shark" "$H50"; then
  printf "     ${GREEN}✓${NC}  compte créé via useradd\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  useradd shark absent\n"; FAIL=$((FAIL + 1))
fi
if grep -q "openssl passwd -6" "$H50" && grep -q "usermod -p" "$H50"; then
  printf "     ${GREEN}✓${NC}  hash SHA-512 appliqué au shadow\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  hash SHA-512 manquant\n"; FAIL=$((FAIL + 1))
fi
if grep -qE "passwd -u shark|usermod -U shark" "$H50"; then
  printf "     ${GREEN}✓${NC}  compte déverrouillé (passwd -u / usermod -U)\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  compte non déverrouillé\n"; FAIL=$((FAIL + 1))
fi

# ── 3. sudo NOPASSWD ─────────────────────────────────────────────────────────
echo -e "${BLUE}  3. sudo NOPASSWD${NC}"
if grep -q "NOPASSWD:ALL" "$H50"; then
  printf "     ${GREEN}✓${NC}  /etc/sudoers.d/shark NOPASSWD\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  sudo NOPASSWD absent\n"; FAIL=$((FAIL + 1))
fi

# ── 4. Autologin LightDM : shark + session xfce (hook 50) ────────────────────
echo -e "${BLUE}  4. Autologin LightDM${NC}"
AUTOLOGIN_CONF="$(sed -n '/50-sharkos-autologin.conf/,/EOF/p' "$H50" 2>/dev/null)"
if grep -q "autologin-user=shark" <<< "$AUTOLOGIN_CONF"; then
  printf "     ${GREEN}✓${NC}  autologin-user=shark\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  autologin-user manquant\n"; FAIL=$((FAIL + 1))
fi
if grep -q "autologin-session=xfce" <<< "$AUTOLOGIN_CONF"; then
  printf "     ${GREEN}✓${NC}  autologin-session=xfce\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  autologin-session=xfce manquant\n"; FAIL=$((FAIL + 1))
fi
if grep -q "greeter-show-manual-login=true" <<< "$AUTOLOGIN_CONF"; then
  printf "     ${GREEN}✓${NC}  re-login manuel possible après déconnexion\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  login manuel désactivé — impossible de se reloger !\n"
  FAIL=$((FAIL + 1)); ISSUES+=("LightDM greeter-show-manual-login != true")
fi

# ── 5. PAM lightdm-autologin : pile standard conservée (pas de pam_deny) ─────
echo -e "${BLUE}  5. PAM lightdm-autologin (session logind / XDG_RUNTIME_DIR)${NC}"
PAM_BLOCK="$(sed -n '/pam.d\/lightdm-autologin/,/EOF/p' "$H50" 2>/dev/null)"
if grep -q "common-session" <<< "$PAM_BLOCK"; then
  printf "     ${GREEN}✓${NC}  @include common-session (pam_systemd → session logind)\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  common-session absent — arrêt/verrouillage d'écran cassés\n"
  FAIL=$((FAIL + 1)); ISSUES+=("PAM lightdm-autologin sans common-session")
fi
if grep -q "common-auth" <<< "$PAM_BLOCK"; then
  printf "     ${GREEN}✓${NC}  @include common-auth (login manuel toujours possible)\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  common-auth absent\n"; FAIL=$((FAIL + 1))
fi
if grep -q "pam_succeed_if.so user ingroup autologin" <<< "$PAM_BLOCK"; then
  printf "     ${GREEN}✓${NC}  autologin sans mot de passe via groupe autologin\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  règle pam_succeed_if autologin absente\n"; FAIL=$((FAIL + 1))
fi
if grep -q "pam_deny.so" <<< "$PAM_BLOCK"; then
  printf "     ${RED}✗${NC}  pam_deny présent — casse la session/le login\n"
  FAIL=$((FAIL + 1)); ISSUES+=("PAM lightdm-autologin contient pam_deny")
else
  printf "     ${GREEN}✓${NC}  pas de pam_deny (pile Debian standard)\n"; PASS=$((PASS + 1))
fi

# ── 6. Session xfce disponible (xsessions + x-session-manager) ───────────────
echo -e "${BLUE}  6. Session XFCE (hook 30)${NC}"
if grep -q "xsessions/xfce.desktop" "$H30" || grep -q "xfce.desktop" "$H30"; then
  printf "     ${GREEN}✓${NC}  /usr/share/xsessions/xfce.desktop fourni\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  xsessions/xfce.desktop absent\n"; FAIL=$((FAIL + 1))
fi
if grep -q "x-session-manager.*xfce4-session\|xfce4-session" "$H30"; then
  printf "     ${GREEN}✓${NC}  x-session-manager = xfce4-session\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  x-session-manager XFCE absent\n"; FAIL=$((FAIL + 1))
fi

# ── 7. XFCE + LightDM dans les paquets installés (bootstrap) ─────────────────
echo -e "${BLUE}  7. Paquets XFCE + LightDM (00-bootstrap.sh)${NC}"
for PKG in "xfce4$" "lightdm$" "lightdm-gtk-greeter$"; do
  if grep -qE "^${PKG}" "$BS" || grep -qE " ${PKG}" "$BS"; then
    printf "     ${GREEN}✓${NC}  paquet %s présent\n" "${PKG%$}"
    PASS=$((PASS + 1))
  else
    printf "     ${RED}✗${NC}  paquet %s absent — pas de bureau au boot !\n" "${PKG%$}"
    FAIL=$((FAIL + 1))
  fi
done

# ── 8. chpasswd protégé (set -euo pipefail ne casse pas la build) ────────────
echo -e "${BLUE}  8. Robustesse : chpasswd protégé sous set -e${NC}"
for H in "$H10" "$H30" "$H50"; do
  if grep -q "set -euo pipefail" "$H" || grep -q "set -e" "$H"; then
    if grep -q "chpasswd" "$H" && grep -q "chpasswd.*|| true" "$H"; then
      printf "     ${GREEN}✓${NC}  %s : chpasswd protégé (|| true)\n" "$(basename "$H")"
      PASS=$((PASS + 1))
    else
      printf "     ${RED}✗${NC}  %s : chpasswd non protégé — peut casser la build\n" "$(basename "$H")"
      FAIL=$((FAIL + 1))
    fi
  fi
done

# ── 9. Cohérence LightDM : greeter + activate (hooks 30/50) ─────────────────
echo -e "${BLUE}  9. LightDM activé + greeter${NC}"
if grep -q "systemctl enable lightdm" "$H30" || grep -q "systemctl enable lightdm" "$H50"; then
  printf "     ${GREEN}✓${NC}  lightdm activé au boot\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  lightdm jamais activé — pas de bureau au boot\n"; FAIL=$((FAIL + 1))
fi
if grep -q "greeter-session=" "$H30"; then
  printf "     ${GREEN}✓${NC}  greeter-session configuré (hook 30)\n"; PASS=$((PASS + 1))
else
  printf "     ${RED}✗${NC}  greeter-session absent\n"; FAIL=$((FAIL + 1))
fi

echo ""
echo -e "  Total: $((PASS + FAIL))  |  ${GREEN}Pass: ${PASS}${NC}  |  ${RED}Fail: ${FAIL}${NC}"
if (( FAIL > 0 )); then
  printf "${RED}  Issues:\n"
  for I in "${ISSUES[@]}"; do echo "    • $I"; done
  exit 1
fi
exit 0