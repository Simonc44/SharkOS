#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — sharkos-install-cycle.sh  v1.0
# Cycle d'installation "live" pour sharkos-installer : exécute les hooks
# 10-install-tools → 20-apply-theme → 30-configure-shell → 40-cleanup →
# 50-sharkos-finalize → 60-sharkos-polish à l'intérieur du chroot cible.
# NB : 00-bootstrap.sh (qui configure lb sur l'hôte) est IGNORÉ ici.
# =============================================================================
set -euo pipefail

# Cette version chroot n'a PAS accès à /tmp/sharkos-build (sauf si sharkos-installer
# l'a rsyncé). On attend que les hooks soient à /tmp/sharkos-build/chroot-hooks/

CYCLE_DIR="/tmp/sharkos-build"
HOOKS_DIR="$CYCLE_DIR/chroot-hooks"

[[ -d "$HOOKS_DIR" ]] || {
  echo "🦈 ERREUR : /tmp/sharkos-build/chroot-hooks absent — sharkos-installer doit avoir rsync-é." >&2
  exit 1
}

echo "🦈 SharkOS Install Cycle"
echo "═══════════════════════════════════════════"
echo ""

for HOOK in \
  "$HOOKS_DIR/10-install-tools.sh" \
  "$HOOKS_DIR/20-apply-theme.sh" \
  "$HOOKS_DIR/30-configure-shell.sh" \
  "$HOOKS_DIR/40-cleanup.sh" \
  "$HOOKS_DIR/50-sharkos-finalize.sh" \
  "$HOOKS_DIR/60-sharkos-polish.sh"; do
  if [[ -f "$HOOK" ]]; then
    echo "── [CYCLE] $(basename $HOOK) "
    bash "$HOOK" || echo "  ⚠ $HOOK returned non-zero — continuent"
    echo ""
  fi
done

echo "🦈 Cycle terminé — reboot imminent."
