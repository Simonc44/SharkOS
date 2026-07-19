#!/usr/bin/env bash
# =============================================================================
# SharkOS — 01-build-iso.sh v3.0 (Garuda-style)
# Build l'ISO avec compression zstd maximale
# =============================================================================
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Ce script doit être lancé en root : sudo bash $0"
  exit 1
fi

echo ""
echo "🦈 SharkOS — Build ISO Dragon Edition"
echo "======================================"
echo ""

LB_DIR="$(dirname "$0")/../iso-build"
cd "$LB_DIR"

# Vérifier que le bootstrap a été fait
[[ ! -f "config/binary" ]] || true

echo "⚡ Démarrage du build live-build (zstd max)..."
echo "   Ça peut prendre 20-60 min selon la connexion."
echo ""

# Build !
sudo lb build 2>&1 | tee /tmp/sharkos-build.log

# Récupérer l'ISO générée
ISO_GENERATED=$(ls -t ./*.hybrid.iso ./*.iso 2>/dev/null | head -1)

if [[ -f "${ISO_GENERATED:-}" ]]; then
  ISO_DEST="SharkOS-Dragon-Edition.iso"
  mv "$ISO_GENERATED" "$ISO_DEST"

  # SHA256
  sha256sum "$ISO_DEST" > "${ISO_DEST}.sha256"

  ISO_SIZE=$(du -sh "$ISO_DEST" | cut -f1)
  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║  ✅ ISO SharkOS Dragon générée !         ║"
  echo "╠══════════════════════════════════════════╣"
  echo "║  📁 Fichier : $ISO_DEST  ║"
  echo "║  📦 Taille  : $ISO_SIZE                         ║"
  echo "║  🔐 SHA256  : ${ISO_DEST}.sha256     ║"
  echo "╠══════════════════════════════════════════╣"
  echo "║  Flash USB : bash scripts/02-flash-usb.sh /dev/sdX  ║"
  echo "╚══════════════════════════════════════════╝"
else
  echo ""
  echo "❌ Build échoué. Voir : /tmp/sharkos-build.log"
  echo "   Dernières lignes du log :"
  tail -30 /tmp/sharkos-build.log
  exit 1
fi
