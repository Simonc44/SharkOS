#!/usr/bin/env bash
# =============================================================================
# SharkOS — 12-syslinux-compat.sh
# Aligne le syslinux Debian (bookworm) sur les attentes du live-build Ubuntu
# (runner CI 22.04) pour l'étape binaire lb_binary_syslinux :
#
#   1. Le thème isolinux embarqué de live-build contient des symlinks absolus
#      vers le layout « flat » Ubuntu : /usr/lib/syslinux/{isolinux.bin,vesamenu.c32}.
#      En Debian, isolinux.bin vit dans le paquet séparé `isolinux`
#      (/usr/lib/ISOLINUX/isolinux.bin) et vesamenu.c32 dans syslinux-common
#      (/usr/lib/syslinux/modules/bios/vesamenu.c32). On installe les paquets
#      Debian puis on recrée les chemins Ubuntu en symlinks pour que le
#      `cp -aL` de dereferencement du thème réussisse.
#   2. En mode Ubuntu, live-build exécute INCONDITIONNELLEMENT
#      `tar xfz /usr/share/gfxboot-theme-ubuntu/bootlogo.tar.gz` (même avec le
#      thème live-build). On fournit un tarball vide valide pour que cette
#      étape soit un no-op inoffensif.
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 12] Compatibilité syslinux Debian ↔ live-build Ubuntu..."
echo ""

# 1) Packages syslinux Debian (layout bookworm) — `isolinux` est un paquet
#    séparé en Debian ; syslinux-common fournit vesamenu.c32.
apt-get install -y --no-install-recommends syslinux syslinux-common isolinux

# 2) Shims des chemins « flat » Ubuntu → layout Debian. Le symlink peut être
#    temporairement pendant (cible manquante) : syslinux-common est déjà
#    installé ci-dessus, donc les cibles existent immédiatement.
mkdir -p /usr/lib/syslinux
ln -sf /usr/lib/ISOLINUX/isolinux.bin /usr/lib/syslinux/isolinux.bin
ln -sf /usr/lib/syslinux/modules/bios/vesamenu.c32 /usr/lib/syslinux/vesamenu.c32

# 3) bootlogo gfxboot : extraction inconditionnelle en mode ubuntu → on la
#    neutralise avec un tarball vide valide.
mkdir -p /usr/share/gfxboot-theme-ubuntu
if [ ! -e /usr/share/gfxboot-theme-ubuntu/bootlogo.tar.gz ]; then
  tar czf /usr/share/gfxboot-theme-ubuntu/bootlogo.tar.gz --files-from /dev/null
fi

echo "   ✓ syslinux Debian aligné (isolinux.bin + vesamenu.c32) — gfxboot neutralisé"