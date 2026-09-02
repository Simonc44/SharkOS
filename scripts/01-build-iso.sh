#!/usr/bin/env bash
# =============================================================================
# SharkOS — 01-build-iso.sh v3.0 (Garuda-style)
# Build l'ISO avec compression zstd maximale
# =============================================================================
set -uo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Ce script doit être lancé en root : sudo bash $0"
  exit 1
fi

echo ""
echo "🦈 SharkOS — Build ISO Dragon Edition"
echo "======================================"
echo ""

LB_DIR="$(dirname "$0")/../iso-build"
cd "$LB_DIR" || exit 1

# Vérifier que le bootstrap a été fait (config live-build présente)
if [[ ! -d "config/package-lists" || ! -d "config/hooks" ]]; then
  echo "❌ Bootstrap non effectué — lance d'abord : sudo bash scripts/00-bootstrap.sh"
  exit 1
fi

echo "⚡ Démarrage du build live-build (zstd max)..."
echo "   Ça peut prendre 20-60 min selon la connexion."
echo ""

# Build — `|| true` pour ne PAS tuer le script avec set -e si lb build échoue :
# on doit pouvoir lire /tmp/sharkos-build.log et sortir un code 1 maîtrisé.
sudo lb build 2>&1 | tee /tmp/sharkos-build.log || true

# Récupérer l'ISO générée — `|| true` pour ne PAS tuer le script si `ls` ne
# trouve rien (sortie 2 dans set -e). On veut juste passer au bloc "échec" plus bas.
# shellcheck disable=SC2012   # ls -t | head : compatible avec noms alphanumériques
ISO_GENERATED=$(ls -t ./*.hybrid.iso ./*.iso 2>/dev/null | head -1 || true)

if [[ -n "${ISO_GENERATED:-}" && -f "${ISO_GENERATED:-}" ]]; then
  ISO_DEST="SharkOS-Dragon-Edition.iso"
  mv "$ISO_GENERATED" "$ISO_DEST"

  # SHA256
  sha256sum "$ISO_DEST" > "${ISO_DEST}.sha256"

  ISO_SIZE=$(du -sh "$ISO_DEST" | cut -f1)
  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║  ✅ ISO SharkOS Dragon générée !                   ║"
  echo "╠══════════════════════════════════════════════════════╣"
  echo "║  📁 Fichier : $ISO_DEST"
  echo "║  📦 Taille  : $ISO_SIZE"
  echo "║  🔐 SHA256  : ${ISO_DEST}.sha256"
  echo "╠══════════════════════════════════════════════════════╣"
  echo "║  Flash USB : bash scripts/02-flash-usb.sh /dev/sdX  ║"
  echo "╚══════════════════════════════════════════════════════╝"
else
  echo ""
  echo "❌ Build échoué — ISO non générée dans $(pwd)"
  echo "   Log complet : /tmp/sharkos-build.log"
  echo "   ————————————————————————————————————————————"
  echo "   Dernières lignes du log :"
  if [[ -f /tmp/sharkos-build.log ]]; then
    tail -60 /tmp/sharkos-build.log
  else
    echo "   (log introuvable)"
  fi
  exit 1
fi
