#!/usr/bin/env bash
# =============================================================================
# SharkOS — 02-flash-usb.sh
# Flash l'ISO SharkOS sur une clé USB bootable
# Usage : sudo bash scripts/02-flash-usb.sh /dev/sdX
# =============================================================================
set -euo pipefail

SHARK_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Localiser l'ISO générée par 01-build-iso.sh (iso-build/SharkOS-Dragon-Edition.iso)
# avec repli sur n'importe quelle .iso du dossier iso-build/ puis l'ancien chemin v1.
ISO_PATH=""
for CAND in \
  "$SHARK_DIR/iso-build/SharkOS-Dragon-Edition.iso" \
  "$SHARK_DIR/iso-build"/*.iso \
  "$SHARK_DIR/SharkOS.iso"; do
  if [[ -f "$CAND" ]]; then
    ISO_PATH="$CAND"
    break
  fi
done

echo ""
echo "🦈 ============================================"
echo "   SharkOS — Flash USB"
echo "============================================ 🦈"
echo ""

# --- Vérification root ---
if [[ $EUID -ne 0 ]]; then
  echo "[ERREUR] Exécute en root : sudo bash scripts/02-flash-usb.sh /dev/sdX"
  exit 1
fi

# --- Vérification argument ---
if [[ -z "${1:-}" ]]; then
  echo "[ERREUR] Spécifie le périphérique USB. Ex: sudo bash scripts/02-flash-usb.sh /dev/sdb"
  echo ""
  echo "Périphériques détectés :"
  lsblk -d -o NAME,SIZE,MODEL | grep -v loop
  exit 1
fi

USB_DEV="$1"

# --- Vérification que le périphérique existe ---
if [[ ! -b "$USB_DEV" ]]; then
  echo "[ERREUR] Périphérique '$USB_DEV' introuvable."
  exit 1
fi

# --- Vérification que l'ISO existe ---
if [[ -z "$ISO_PATH" ]]; then
  echo "[ERREUR] ISO introuvable dans iso-build/ (SharkOS-Dragon-Edition.iso)"
  echo "         Lance d'abord : sudo bash scripts/01-build-iso.sh"
  exit 1
fi

# --- Confirmation utilisateur ---
USB_SIZE=$(lsblk -d -o SIZE "$USB_DEV" | tail -n1)
ISO_SIZE=$(du -sh "$ISO_PATH" | cut -f1)
echo "⚠️  ATTENTION : Toutes les données sur $USB_DEV ($USB_SIZE) seront effacées !"
echo ""
echo "   ISO source  : $ISO_PATH ($ISO_SIZE)"
echo "   Cible USB   : $USB_DEV ($USB_SIZE)"
echo ""
read -rp "   Confirmer ? (tape 'OUI' en majuscules) : " CONFIRM

if [[ "$CONFIRM" != "OUI" ]]; then
  echo "Opération annulée."
  exit 0
fi

# --- Démontage des partitions ---
echo ""
echo "[1/3] Démontage des partitions..."
umount "${USB_DEV}"* 2>/dev/null || true

# --- Flash avec dd ---
echo "[2/3] Flash en cours (patiente...)  "
dd if="$ISO_PATH" of="$USB_DEV" bs=4M status=progress oflag=sync

# --- Sync ---
echo "[3/3] Synchronisation..."
sync

echo ""
echo "✅ Clé USB SharkOS prête !"
echo "   Branche la clé, redémarre et sélectionne '$USB_DEV' dans ton BIOS/UEFI."
echo ""
