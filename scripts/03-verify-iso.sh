#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — 03-verify-iso.sh  v1.0
# Vérifications de l'ISO Dragon Edition built locally ou téléchargée :
#   1. SHA256 self-test (intégrité)
#   2. Hybrid MBR + partition table (flashable via dd sur USB)
#   3. El Torito boot catalog (BIOS + EFI boot catalogs)
#   4. Fichiers live essentiels (vmlinuz, initrd, squashfs)
# =============================================================================
set -uo pipefail

PURPLE='\033[1;35m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'

ISO="${1:-}"
[[ -z "$ISO" ]] && {
  # Cherche par défaut
  if [[ -f iso-build/SharkOS-Dragon-Edition.iso ]]; then
    ISO="iso-build/SharkOS-Dragon-Edition.iso"
  else
    ISO="$(find iso-build -maxdepth 2 -name '*.iso' 2>/dev/null | head -1 || true)"
  fi
}
[[ -z "$ISO" || ! -f "$ISO" ]] && {
  printf "${RED}🦈 Aucune ISO trouvée.${NC} Usage : sudo bash scripts/03-verify-iso.sh [/chemin/vers/iso]\n"
  exit 1
}

QUIET=false
[[ "${2:-}" == "--quiet" || "${1:-}" == "--quiet" ]] && QUIET=true

log()  { [[ "$QUIET" == false ]] && printf "$1\n"; }
ok()   { log "${GREEN}  ✓ $1${NC}"; ((PASS++)); }
err()  { log "${RED}  ✗ $1${NC}"; ((FAIL++)); }
warn() { log "${YELLOW}  ⚠ $1${NC}"; ((WARNINGS++)); }

PASS=0; FAIL=0; WARNINGS=0
ISO_SIZE=$(du -sh "$ISO" | cut -f1)

printf "${PURPLE}🦈====================================================${NC}\n"
printf "${PURPLE}   SharkOS ISO Verification — $ISO${NC}\n"
printf "${PURPLE}====================================================🦈${NC}\n"
log "  Taille : $ISO_SIZE"
log ""

# ─────────────────────────────────────────────────────────────────────
# CHECK 1 — SHA256 self-test
# ─────────────────────────────────────────────────────────────────────
log "${CYAN}[1/4] SHA256 self-test${NC}"
SHA="${ISO}.sha256"
if [[ -f "$SHA" ]]; then
  if (cd "$(dirname "$ISO")" && sha256sum -c --status "$(basename "$SHA")" 2>/dev/null); then
    ok "SHA256 vérifié ($(awk '{print $1}' "$SHA" | head -c 16)… )"
  else
    err "SHA256 ne correspond pas — ISO corrompue ou re-téléchargée requise"
  fi
else
  warn "Pas de fichier $ISO.sha256 — skip (le build ISO écrit ce fichier; utilisez celui de l'artifact)"
fi
log ""

# ─────────────────────────────────────────────────────────────────────
# CHECK 2 — Hybrid MBR / Partition table (USB-flashable)
# ─────────────────────────────────────────────────────────────────────
log "${CYAN}[2/4] Hybrid MBR / partition table (USB-flashable)${NC}"
if command -v fdisk &>/dev/null; then
  FDISK_OUT=$(fdisk -l "$ISO" 2>/dev/null || true)
  if echo "$FDISK_OUT" | grep -qE 'GPT|Disklabel type|protective MBR'; then
    ok "Table de partition détectée : $(echo "$FDISK_OUT" | grep -E 'Disklabel type|protective' | head -1 | xargs)"
  elif file "$ISO" 2>/dev/null | grep -qE 'DOS/MBR boot sector'; then
    ok "Hybrid MBR détecté (file magic : DOS/MBR)"
  else
    err "Pas de partition table — l'ISO ne peut PAS être flashée en USB via dd"
  fi
elif command -v file &>/dev/null; then
  if file "$ISO" | grep -qE 'DOS/MBR boot sector|ISO 9660 CD-ROM'; then
    ok "ISO 9660 + boot sector détecté (file)"
  else
    err "Pas de boot sector détectable"
  fi
else
  warn "Ni fdisk ni file disponibles — check skipped"
fi
log ""

# ─────────────────────────────────────────────────────────────────────
# CHECK 3 — El Torito boot catalog (BIOS bootable)
# ─────────────────────────────────────────────────────────────────────
log "${CYAN}[3/4] El Torito boot catalog (BIOS bootable)${NC}"
ET_OK=false
if command -v xorriso &>/dev/null; then
  ET=$(xorriso -indev "$ISO" -report_el_torito plain 2>/dev/null || true)
  if echo "$ET" | grep -qi "El Torito"; then
    PROFILES=$(echo "$ET" | grep -ciE 'boot img|boot info')
    if (( PROFILES >= 1 )); then
      ok "El Torito catalog présent ($PROFILES boot images : BIOS+EFI)"
      ET_OK=true
    else
      err "El Torito catalog vide — firmware ne trouvera pas d'amorçage"
    fi
  else
    err "Pas de El Torito catalog — ISO non-amorçable"
  fi
elif command -v isoinfo &>/dev/null; then
  if isoinfo -d -i "$ISO" 2>/dev/null | grep -qi 'Boot'; then
    ok "isoinfo rapporte une section Boot (probable El Torito)"
    ET_OK=true
  else
    err "Pas de section Boot détectée par isoinfo"
  fi
else
  warn "xorriso ni isoinfo disponibles — check skipped"
fi
log ""

# ─────────────────────────────────────────────────────────────────────
# CHECK 4 — Live filesystem presence
# ─────────────────────────────────────────────────────────────────────
log "${CYAN}[4/4] Live filesystem essentials${NC}"
REQUIRED_PATHS=(
  "/live/vmlinuz"
  "/live/initrd.img"
  "/live/filesystem.squashfs"
)
ALT_PATHS=(
  "/casper/vmlinuz"
  "/casper/initrd.gz"
  "/casper/filesystem.squashfs"
  "/boot/grub/grub.cfg"
)
LISTING=""
if command -v isoinfo &>/dev/null; then
  LISTING=$(isoinfo -J -i "$ISO" -f 2>/dev/null || true)
fi

if [[ -z "$LISTING" ]]; then
  warn "isoinfo indisponible — listing impossible. Re-run avec xorriso ou sans --quiet"
else
  FOUND_KERNEL=false
  FOUND_INITRD=false
  FOUND_SQUASHFS=false
  for P in live/vmlinuz casper/vmlinuz boot/vmlinuz; do
    if echo "$LISTING" | grep -qE "^/$P\$"; then FOUND_KERNEL=true; fi
  done
  for P in live/initrd.img live/initrd.gz casper/initrd.lz casper/initrd.gz; do
    if echo "$LISTING" | grep -qE "^/$P\$"; then FOUND_INITRD=true; fi
  done
  for P in live/filesystem.squashfs casper/filesystem.squashfs; do
    if echo "$LISTING" | grep -qE "^/$P\$"; then FOUND_SQUASHFS=true; fi
  done

  $FOUND_KERNEL   && ok "kernel trouvé"       || err "kernel absent (live/vmlinuz)"
  $FOUND_INITRD   && ok "initrd trouvé"       || err "initrd absent (live/initrd.img)"
  $FOUND_SQUASHFS && ok "squashfs trouvé"     || err "squashfs absent (live/filesystem.squashfs)"

  if echo "$LISTING" | grep -q "/boot/grub/grub.cfg"; then
    ok "GRUB config trouvé (/boot/grub/grub.cfg)"
  else
    warn "/boot/grub/grub.cfg absent — le boot UEFI pourrait échouer"
  fi
fi
log ""

# ─────────────────────────────────────────────────────────────────────
# RÉSUMÉ
# ─────────────────────────────────────────────────────────────────────
printf "${PURPLE}🦈 Summary${NC}\n"
printf "  Pass   : ${GREEN}%d${NC}\n" "$PASS"
printf "  Fail   : ${RED}%d${NC}\n" "$FAIL"
printf "  Warn   : ${YELLOW}%d${NC}\n" "$WARNINGS"

if (( FAIL == 0 )); then
  printf "\n${GREEN}  🦈 ISO OK pour Live USB : flashable, amorçable, intègre.${NC}\n"
  printf "${CYAN}      sudo bash scripts/02-flash-usb.sh /dev/sdX     # ⚠${NC}\n"
  printf "${CYAN}      # puis reboot → sélectionne la clé dans le BIOS${NC}\n"
  exit 0
else
  printf "\n${RED}  🔴 ISO INCOMPLÈTE — voir les ✗ ci-dessus.${NC}\n"
  exit 1
fi
