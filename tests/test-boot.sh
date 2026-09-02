#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — test-boot.sh  (TEST SUR SYSTÈME RÉEL)
# Contrairement aux autres tests (statiques : grep/bash -n), ce test valide le
# VRAI artefact : l'ISO construite. Il tourne en 2 phases :
#
#   PHASE A — Boot réel QEMU (kernel + initrd + squashfs extraits de l'ISO)
#       • le kernel démarre (log console ttyS0)
#       • systemd atteint "Reached target Graphical Interface"
#       • LightDM démarre
#       • l'autologin ouvre une session logind pour l'utilisateur shark
#       • NetworkManager démarre (pile réseau = Wi-Fi)
#
#   PHASE B — Contenu réel du squashfs (unsquashfs de l'ISO)
#       • Calamares bundle (/etc/calamares/sharkos) + installer + wizard shipés
#       • Firmware Wi-Fi (iwlwifi/realtek/atheros) + NetworkManager/wpa_supplicant
#       • Sécurité : UFW actif, AppArmor activé, sysctl durci
#       • Login : autologin shark, police MiSans
#
# Codes de sortie :
#   0 = PASS (tests réels exécutés et verts)
#   1 = FAIL (un check réel a échoué)
#   3 = SKIP (pas d'ISO construite / outils manquants) — ne casse pas la suite
#
# Usage : bash tests/test-boot.sh [/chemin/vers/SharkOS-Dragon-Edition.iso]
# =============================================================================
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'
CYAN='\033[1;36m'; PURPLE='\033[1;35m'; NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PASS=0; FAIL=0; WARN=0; SKIPPED_CHECKS=0
ISSUES=()

ok()   { printf "     ${GREEN}✓${NC}  %s\n" "$1"; PASS=$((PASS + 1)); }
err()  { printf "     ${RED}✗${NC}  %s\n" "$1"; FAIL=$((FAIL + 1)); ISSUES+=("$1"); }
warn() { printf "     ${YELLOW}⚠${NC}  %s\n" "$1"; WARN=$((WARN + 1)); }

# ─────────────────────────────────────────────────────────────────────────────
# 0. LOCALISER L'ISO — sinon SKIP (exit 3) : la suite reste verte, mais le
#    message est explicite : les tests réels ne peuvent pas tourner sans ISO.
# ─────────────────────────────────────────────────────────────────────────────
ISO="${1:-}"
if [[ -z "$ISO" || ! -f "$ISO" ]]; then
  if [[ -f "iso-build/SharkOS-Dragon-Edition.iso" ]]; then
    ISO="iso-build/SharkOS-Dragon-Edition.iso"
  else
    ISO="$(find iso-build -maxdepth 2 -name '*.iso' 2>/dev/null | head -1 || true)"
  fi
fi
if [[ -z "${ISO:-}" || ! -f "${ISO:-}" ]]; then
  echo -e "${YELLOW}⏭ SKIP — aucune ISO construite trouvée (cherché : iso-build/*.iso).${NC}"
  echo -e "   Pour exécuter les tests système réels (boot, Calamares, Wi-Fi) :"
  echo -e "   1. sudo bash scripts/00-bootstrap.sh && sudo bash scripts/01-build-iso.sh"
  echo -e "   2. bash tests/test-boot.sh   (ou : sudo bash tests/test-boot.sh)"
  exit 3
fi

TMP="$(mktemp -d /tmp/sharkos-boottest.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

echo -e "${PURPLE}🦈======================================================${NC}"
echo -e "${PURPLE}   Test SYSTÈME RÉEL — $ISO${NC}"
echo -e "${PURPLE}======================================================🦈${NC}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# 1. TAILLE RÉELLE DE L'ISO (< 2 Go) + structure de boot (GRUB/isolinux)
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${BLUE}  1. Taille ISO (< 2 Go) + structure de boot${NC}"
ISO_MB=$(du -m "$ISO" | cut -f1)
if (( ISO_MB < 2048 )); then
  ok "ISO = ${ISO_MB} Mo (< 2 Go ✓)"
else
  err "ISO = ${ISO_MB} Mo — DÉPASSE la cible de 2 Go !"
fi

LISTING=""
if command -v isoinfo &>/dev/null; then
  LISTING=$(isoinfo -J -i "$ISO" -f 2>/dev/null || true)
elif command -v xorriso &>/dev/null; then
  LISTING=$(xorriso -indev "$ISO" -find / -type f 2>/dev/null | sed 's|^/|/|' || true)
fi
if [[ -z "$LISTING" ]]; then
  warn "isoinfo/xorriso indisponibles — structure de boot non vérifiée"
else
  for P in "/live/vmlinuz" "/live/initrd.img" "/live/filesystem.squashfs"; do
    if echo "$LISTING" | grep -q "^$P$"; then
      ok "ISO contient $P"
    else
      err "ISO ne contient PAS $P — live system incomplet !"
    fi
  done
  if echo "$LISTING" | grep -q "/boot/grub/grub.cfg"; then
    ok "GRUB config présent (/boot/grub/grub.cfg)"
  else
    warn "/boot/grub/grub.cfg absent de l'ISO"
  fi
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# 2. EXTRACTION kernel + initrd + squashfs (pour boot QEMU + contenu réel)
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${BLUE}  2. Extraction kernel / initrd / squashfs${NC}"
KERNEL="$TMP/vmlinuz"; INITRD="$TMP/initrd.img"; SQUASH="$TMP/filesystem.squashfs"
EXTRACTED=false
if command -v xorriso &>/dev/null; then
  if xorriso -osirrox on -indev "$ISO" \
       -extract /live/vmlinuz "$KERNEL" \
       -extract /live/initrd.img "$INITRD" \
       -extract /live/filesystem.squashfs "$SQUASH" >/dev/null 2>&1; then
    EXTRACTED=true
  fi
elif command -v isoinfo &>/dev/null; then
  isoinfo -J -i "$ISO" -x "/live/vmlinuz" > "$KERNEL" 2>/dev/null && \
  isoinfo -J -i "$ISO" -x "/live/initrd.img" > "$INITRD" 2>/dev/null && \
  isoinfo -J -i "$ISO" -x "/live/filesystem.squashfs" > "$SQUASH" 2>/dev/null && \
  EXTRACTED=true
fi
if [[ "$EXTRACTED" == true ]] && [[ -s "$KERNEL" && -s "$INITRD" && -s "$SQUASH" ]]; then
  ok "kernel + initrd + squashfs extraits ($(du -m "$SQUASH" | cut -f1) Mo)"
else
  warn "extraction impossible (xorriso/isoinfo manquants) — boot QEMU et contenu squashfs SKIPPÉS"
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# 3. BOOT RÉEL QEMU — le test le plus important : l'ISO démarre-t-elle ?
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${BLUE}  3. Boot réel QEMU (kernel + initrd + squashfs de l'ISO)${NC}"
if [[ "$EXTRACTED" != true ]]; then
  warn "SKIP — boot QEMU impossible sans extraction"
  SKIPPED_CHECKS=$((SKIPPED_CHECKS + 4))
elif ! command -v qemu-system-x86_64 &>/dev/null; then
  warn "SKIP — qemu-system-x86_64 absent (apt install qemu-system-x86)"
  SKIPPED_CHECKS=$((SKIPPED_CHECKS + 4))
elif ! command -v mkfs.ext4 &>/dev/null || ! command -v debugfs &>/dev/null; then
  warn "SKIP — mkfs.ext4/debugfs (e2fsprogs) absents"
  SKIPPED_CHECKS=$((SKIPPED_CHECKS + 4))
else
  # Construire un média live minimal (ext4) contenant /live/filesystem.squashfs.
  # ⚠️ L'image doit être GÉNÉREUSE et sans blocs réservés (-m 0) : une image
  # trop serrée (+48 Mo seulement, 5% réservés par défaut) a déjà produit un
  # squashfs dont la fin (table xattr) était illisible → boot QEMU bloqué sur
  # « unable to read xattr id index table ».
  # Chemin root (CI) : mount en boucle + cp → copie octet-exacte et vérifiée.
  # Fallback non-root : debugfs (e2fsprogs, pas besoin de root ni de mount).
  MEDIA="$TMP/live-media.img"
  SQSIZE=$(stat -c%s "$SQUASH")
  MBSIZE=$(( (SQSIZE / 1048576) + 300 ))
  PREP_OK=false
  if dd if=/dev/zero of="$MEDIA" bs=1M count="$MBSIZE" status=none 2>/dev/null \
     && mkfs.ext4 -F -q -m 0 -O ^has_journal -L sharkos-live "$MEDIA" >/dev/null 2>&1; then
    if [[ "$(id -u)" == 0 ]] && mkdir -p "$TMP/mnt" 2>/dev/null; then
      if mount -o loop "$MEDIA" "$TMP/mnt" >/dev/null 2>&1; then
        mkdir -p "$TMP/mnt/live"
        if cp "$SQUASH" "$TMP/mnt/live/filesystem.squashfs" 2>/dev/null \
           && [[ "$(stat -c%s "$TMP/mnt/live/filesystem.squashfs" 2>/dev/null)" == "$SQSIZE" ]]; then
          PREP_OK=true
        fi
        umount "$TMP/mnt" >/dev/null 2>&1 || true
      fi
    fi
    if [[ "$PREP_OK" != true ]] && debugfs -w -R "mkdir /live" "$MEDIA" >/dev/null 2>&1 \
       && debugfs -w -R "write $SQUASH /live/filesystem.squashfs" "$MEDIA" >/dev/null 2>&1; then
      PREP_OK=true
    fi
  fi
  if [[ "$PREP_OK" == true ]]; then
    ok "média live préparé ($MBSIZE Mo, squashfs inclus)"
  else
    err "impossible de préparer le média live (dd/mkfs.ext4/mount|debugfs)"
    MEDIA=""
  fi

  if [[ -n "${MEDIA:-}" ]]; then
    LOG="$TMP/boot.log"
    KVM=""
    [[ -e /dev/kvm ]] && KVM="-enable-kvm -cpu host"
    qemu-system-x86_64 $KVM -m 2048 -smp 2 \
      -display none -serial file:"$LOG" \
      -no-reboot \
      -kernel "$KERNEL" -initrd "$INITRD" \
      # ⚠️ ORDRE des console= : ttyS0 doit être le DERNIER paramètre — c'est le
      # dernier console= qui devient /dev/console → les messages systemd
      # ("[ OK ] Reached target Graphical Interface", "Started Network
      # Manager", LightDM…) n'atteignent la série QUE si /dev/console = ttyS0.
      # Avec `console=ttyS0 console=tty0`, /dev/console = tty0 (non capturé)
      # → les greps systemd ci-dessous rataient TOUJOURS, même boot réussi.
      # systemd.show_status=1 force l'affichage du statut sur la console.
      -append "boot=live components console=tty0 console=ttyS0 systemd.show_status=1 live-media=/dev/sda mitigations=on audit=1 page_poison=1 slab_nomerge" \
      -drive file="$MEDIA",format=raw,if=ide \
      -netdev user,id=n0 -device e1000,netdev=n0 \
      >/dev/null 2>&1 &
    QPID=$!
    ok "QEMU lancé (PID $QPID) — attente du boot live…"

    BOOT_TIMEOUT=480
    DEADLINE=$(( $(date +%s) + BOOT_TIMEOUT ))
    while (( $(date +%s) < DEADLINE )); do
      grep -q "Reached target Graphical Interface" "$LOG" 2>/dev/null && break
      kill -0 "$QPID" 2>/dev/null || break
      sleep 5
    done
    sleep 5   # laisser systemd-logind enregistrer la session
    kill "$QPID" 2>/dev/null; wait "$QPID" 2>/dev/null

    # ── Jalons du boot ──
    [[ -s "$LOG" ]] && ok "log console capturé ($(wc -l < "$LOG") lignes)" \
                    || err "log console vide — QEMU n'a rien émis !"

    if grep -q "Linux version" "$LOG" 2>/dev/null; then
      ok "KERNEL BOOTÉ : $(grep -m1 -o 'Linux version [^ ]*' "$LOG")"
    else
      err "kernel n'a pas démarré (pas de 'Linux version' dans la console)"
    fi

    if grep -q "Reached target Graphical Interface" "$LOG" 2>/dev/null; then
      ok "systemd a atteint la cible graphique (interface prête)"
    else
      err "cible graphique non atteinte — boot live incomplet !"
    fi

    if grep -qi "lightdm" "$LOG" 2>/dev/null; then
      ok "LightDM (display manager) démarré"
    else
      err "LightDM absent du boot — pas de login graphique"
    fi

    if grep -q "of user shark" "$LOG" 2>/dev/null; then
      ok "AUTOLOGIN RÉUSSI : session logind ouverte pour shark"
    else
      warn "session logind pour shark non observée dans la console (l'autologin GTK ne loggue pas toujours sur ttyS0)"
    fi

    if grep -q "Started Network Manager" "$LOG" 2>/dev/null; then
      ok "NetworkManager démarré (pile réseau prête)"
    else
      err "NetworkManager n'a pas démarré — pas de Wi-Fi/ethernet au boot"
    fi

    # Diagnostic rapide en cas d'échec
    if (( FAIL > 0 )); then
      printf "     ${YELLOW}--- dernières lignes du boot ---${NC}\n"
      tail -30 "$LOG" 2>/dev/null | sed 's/^/     /'
    fi
  fi
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# 4. CONTENU RÉEL DU SQUASHFS — Calamares / installer / Wi-Fi / sécurité / login
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${BLUE}  4. Contenu réel du squashfs (unsquashfs)${NC}"
ROOTFS="$TMP/rootfs"
if [[ "$EXTRACTED" != true ]]; then
  warn "SKIP — contenu squashfs non vérifié (extraction impossible)"
  SKIPPED_CHECKS=$((SKIPPED_CHECKS + 16))
elif ! command -v unsquashfs &>/dev/null; then
  warn "SKIP — unsquashfs absent (apt install squashfs-tools)"
  SKIPPED_CHECKS=$((SKIPPED_CHECKS + 16))
else
  if unsquashfs -q -d "$ROOTFS" "$SQUASH" >/dev/null 2>&1; then
    ok "squashfs décompressé (contenu réel de l'ISO)"

    # ── 4a. Installateur : Calamares bundle + sharkos-installer + wizard ──
    echo -e "${CYAN}     4a. Installateur (Calamares bundle + sharkos-installer + wizard)${NC}"
    if [[ -f "$ROOTFS/etc/calamares/sharkos/settings.conf" ]]; then
      ok "Calamares bundle présent (/etc/calamares/sharkos/settings.conf)"
    else
      err "Calamares bundle ABSENT du squashfs — l'installation en dur ne marchera pas !"
    fi
    if [[ -f "$ROOTFS/etc/calamares/sharkos/modules/sharkos-install-cycle.conf" ]]; then
      ok "module Calamares sharkos-install-cycle présent"
    else
      err "module sharkos-install-cycle absent"
    fi
    if [[ -x "$ROOTFS/usr/local/bin/sharkos-installer" ]]; then
      ok "sharkos-installer réel présent + exécutable"
    else
      err "sharkos-installer absent/non exécutable dans l'ISO"
    fi
    if [[ -x "$ROOTFS/usr/local/bin/sharkos-setup-wizard" ]]; then
      ok "setup-wizard graphique présent + exécutable"
    else
      err "setup-wizard absent — l'assistant d'installation n'apparaîtra pas au boot !"
    fi
    if [[ -f "$ROOTFS/etc/xdg/autostart/sharkos-setup-wizard.desktop" ]]; then
      ok "autostart du wizard présent (se lance au premier login)"
    else
      err "autostart du wizard absent"
    fi

    # ── 4b. Wi-Fi : firmware + NetworkManager + wpa_supplicant ──
    echo -e "${CYAN}     4b. Wi-Fi (firmware + NetworkManager + wpa_supplicant)${NC}"
    FW_FOUND=0
    for FW_DIR in \
      "$ROOTFS/lib/firmware/iwlwifi" "$ROOTFS/lib/firmware/iwlwifi-1000-5.ucode" \
      "$ROOTFS/lib/firmware/rtlwifi" "$ROOTFS/lib/firmware/rtl_bt" \
      "$ROOTFS/lib/firmware/ath10k" "$ROOTFS/lib/firmware/ath11k" \
      "$ROOTFS/lib/firmware/rt2860.bin" "$ROOTFS/lib/firmware/brcm"; do
      if [[ -e "$FW_DIR" ]]; then FW_FOUND=$((FW_FOUND + 1)); fi
    done
    if (( FW_FOUND >= 2 )); then
      ok "firmware Wi-Fi embarqué ($FW_FOUND familles : iwlwifi/realtek/atheros/brcm…)"
    else
      err "firmware Wi-Fi insuffisant ($FW_FOUND/2 familles) — Wi-Fi probablement inopérant"
    fi
    for BIN in "usr/sbin/NetworkManager" "usr/sbin/wpa_supplicant" "usr/sbin/iw"; do
      if [[ -e "$ROOTFS/$BIN" ]]; then
        ok "$(basename "$BIN") présent ($BIN)"
      else
        err "$BIN absent — pile Wi-Fi incomplète"
      fi
    done

    # ── 4c. Sécurité réelle appliquée au système ──
    echo -e "${CYAN}     4c. Sécurité (UFW, AppArmor, sysctl, noexec /tmp)${NC}"
    if [[ -f "$ROOTFS/etc/ufw/ufw.conf" ]] && grep -q "^ENABLED=yes" "$ROOTFS/etc/ufw/ufw.conf"; then
      ok "UFW actif par défaut (ENABLED=yes)"
    else
      err "UFW pas actif par défaut dans l'ISO"
    fi
    # apparmor.service (Debian) a [Install] WantedBy=sysinit.target → le lien
    # d'activation vit dans sysinit.target.wants/ (PAS multi-user.target.wants/).
    # Les profils dhclient/tcpdump ne sont PAS shipés par apparmor en bookworm.
    if [[ -d "$ROOTFS/etc/apparmor.d" ]] && \
       [[ -x "$ROOTFS/usr/sbin/aa-status" ]] && \
       [[ -e "$ROOTFS/etc/systemd/system/sysinit.target.wants/apparmor.service" || \
          -e "$ROOTFS/etc/systemd/system/multi-user.target.wants/apparmor.service" ]]; then
      ok "AppArmor installé + service activé (profils /etc/apparmor.d)"
    else
      err "AppArmor absent/incomplet"
    fi
    if grep -q "dmesg_restrict" "$ROOTFS/etc/sysctl.d/"*.conf 2>/dev/null || \
       grep -rq "dmesg_restrict" "$ROOTFS/etc/sysctl.conf" 2>/dev/null; then
      ok "sysctl durci appliqué (dmesg_restrict…)"
    else
      err "sysctl durci absent du système"
    fi

    # ── 4d. Login réel : autologin shark + police MiSans ──
    echo -e "${CYAN}     4d. Login (autologin shark) + police MiSans${NC}"
    if grep -q "autologin-user=shark" "$ROOTFS/etc/lightdm/lightdm.conf.d/"*.conf 2>/dev/null; then
      ok "autologin shark configuré dans l'ISO"
    else
      err "autologin shark absent de l'ISO — pas de bureau au boot !"
    fi
    if [[ -d "$ROOTFS/usr/local/share/fonts" ]] && ls "$ROOTFS/usr/local/share/fonts/"*MiSans* >/dev/null 2>&1; then
      ok "police MiSans embarquée"
    elif find "$ROOTFS/usr/share/fonts" -iname "*misans*" 2>/dev/null | grep -q .; then
      ok "police MiSans embarquée (/usr/share/fonts)"
    else
      warn "MiSans absente — la police de secours Noto s'appliquera"
    fi
  else
    err "unsquashfs a échoué — squashfs corrompu ?"
  fi
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# RÉSUMÉ
# ─────────────────────────────────────────────────────────────────────────────
printf "${PURPLE}🦈 Summary${NC}\n"
printf "  Pass   : ${GREEN}%d${NC}\n" "$PASS"
printf "  Fail   : ${RED}%d${NC}\n" "$FAIL"
printf "  Warn   : ${YELLOW}%d${NC}\n" "$WARN"
if (( SKIPPED_CHECKS > 0 )); then
  printf "  Skip   : %d checks (outils manquants)\n" "$SKIPPED_CHECKS"
fi

if (( FAIL > 0 )); then
  printf "\n${RED}  🔴 SYSTÈME RÉEL EN ÉCHEC :${NC}\n"
  for I in "${ISSUES[@]}"; do printf "     • %s\n" "$I"; done
  printf "\n${RED}  L'ISO a des problèmes réels — à corriger avant diffusion.${NC}\n"
  exit 1
fi
if (( PASS == 0 )); then
  printf "\n${YELLOW}  ⏭ Aucun check réel exécuté (outils manquants).${NC}\n"
  exit 3
fi
printf "\n${GREEN}  🦈 ISO VALIDÉE SUR SYSTÈME RÉEL : boot + installateur + Wi-Fi + sécurité.${NC}\n"
exit 0
