#!/usr/bin/env bash
# =============================================================================
# SharkOS — 40-cleanup.sh (CHROOT HOOK)
# Script de nettoyage post-installation
# Supprime tout ce qui est inutile pour garder SharkOS léger et furtif
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 40] Nettoyage SharkOS — Suppression du superflu..."
echo ""

# =============================================================================
# 1. PAQUETS INUTILES À SUPPRIMER
# =============================================================================
echo "[1/7] Suppression des paquets inutiles..."

PACKAGES_TO_REMOVE=(
  # Jeux Debian / Ubuntu inutiles
  "gnome-games"
  "aisleriot"
  "gnome-mahjongg"
  "gnome-mines"
  "gnome-sudoku"
  "quadrapassel"
  "five-or-more"
  "four-in-a-row"
  "hitori"
  "iagno"
  "lightsoff"
  "swell-foop"
  "tali"

  # Bureautique non demandée
  "libreoffice*"
  "abiword*"
  "gnumeric*"

  # Clients mail non demandés
  "evolution*"
  "thunderbird*"
  "geary*"

  # Lecteurs multimédia redondants
  "totem*"
  "rhythmbox*"
  "banshee*"

  # Outils GNOME non pertinents dans XFCE
  "gnome-software"
  "gnome-control-center"
  "gnome-packagekit*"
  "packagekit*"
  "update-manager*"
  "update-notifier*"

  # Accès internet non demandé
  "transmission*"
  "pidgin*"
  "empathy*"
  "hexchat*"

  # Docs hors ligne inutiles
  "xubuntu-docs"
  "ubuntu-docs"
  "yelp*"
  "scrollkeeper"

  # Outils d'impression (non nécessaire par défaut)
  "cups*"
  "hplip*"
  "system-config-printer*"

  # Accessibilité lourde (conserve le minimum)
  "orca*"
  "brltty*"
  "speech-dispatcher*"
  "espeak*"
)

for PKG in "${PACKAGES_TO_REMOVE[@]}"; do
  apt-get purge -y --auto-remove "$PKG" 2>/dev/null || true
done

# =============================================================================
# 2. NETTOYAGE DES FICHIERS TEMPORAIRES DE BUILD
# =============================================================================
echo "[2/7] Suppression des fichiers temporaires de build..."

# Dossiers de build clonés dans /tmp
rm -rf /tmp/WhiteSur-gtk-theme
rm -rf /tmp/WhiteSur-icon-theme
rm -rf /tmp/xubuntu-default-settings
rm -rf /tmp/*.tar.gz
rm -rf /tmp/*.deb
rm -rf /tmp/pip-*
rm -rf /var/tmp/*

# =============================================================================
# 3. NETTOYAGE APT
# =============================================================================
echo "[3/7] Nettoyage du cache APT..."

apt-get autoremove -y --purge 2>/dev/null || true
apt-get autoclean -y 2>/dev/null || true
apt-get clean 2>/dev/null || true

rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/archives/*.deb
rm -rf /var/cache/apt/archives/partial/*

# =============================================================================
# 4. NETTOYAGE DES LOGS SYSTÈME
# =============================================================================
echo "[4/7] Purge des logs système..."

find /var/log -type f -name "*.log" -delete 2>/dev/null || true
find /var/log -type f -name "*.gz" -delete 2>/dev/null || true
find /var/log -type f -name "*.1" -delete 2>/dev/null || true
find /var/log -type f -name "*.old" -delete 2>/dev/null || true

# Vider sans supprimer les fichiers de log actifs
for LOG in /var/log/syslog /var/log/auth.log /var/log/kern.log /var/log/dpkg.log; do
  [[ -f "$LOG" ]] && : > "$LOG"
done

# Journald
journalctl --vacuum-size=0 2>/dev/null || true
rm -rf /var/log/journal/*

# =============================================================================
# 5. NETTOYAGE DES FICHIERS PERSONNELS / HISTORIQUE
# =============================================================================
echo "[5/7] Effacement des historiques et données personnelles..."

# Historiques shell
find /root /home -name ".bash_history" -delete 2>/dev/null || true
find /root /home -name ".zsh_history" -delete 2>/dev/null || true
find /root /home -name ".sh_history" -delete 2>/dev/null || true
find /root /home -name ".python_history" -delete 2>/dev/null || true
find /root /home -name ".lesshst" -delete 2>/dev/null || true

# Historique sudo / auth
find /var/log -name "auth.log*" -delete 2>/dev/null || true

# Caches utilisateur
find /root /home -type d -name ".cache" -exec rm -rf {} + 2>/dev/null || true

# Clés SSH temporaires (ne pas embarquer de clés dans la live)
find /etc/ssh -name "ssh_host_*" -delete 2>/dev/null || true
find /root /home -name "authorized_keys" -delete 2>/dev/null || true
find /root /home -name "id_rsa" -delete 2>/dev/null || true
find /root /home -name "id_ed25519" -delete 2>/dev/null || true

# Clés GPG temporaires
rm -rf /root/.gnupg 2>/dev/null || true

# =============================================================================
# 6. NETTOYAGE DES LOCALES (garder fr + en)
# =============================================================================
echo "[6/7] Nettoyage des locales inutiles..."

# Conserver uniquement fr_FR et en_US
find /usr/share/locale -mindepth 1 -maxdepth 1 -type d \
  ! -name "fr*" ! -name "en*" ! -name "fr_FR*" ! -name "en_US*" \
  -exec rm -rf {} + 2>/dev/null || true

find /usr/share/man -mindepth 1 -maxdepth 1 -type d \
  ! -name "man*" ! -name "fr*" ! -name "en*" \
  -exec rm -rf {} + 2>/dev/null || true

# =============================================================================
# 7. NETTOYAGE FINAL — Docs, exemples, fichiers inutiles
# =============================================================================
echo "[7/7] Nettoyage des docs et exemples inutiles..."

# Docs des paquets (sauf SharkOS)
find /usr/share/doc -mindepth 1 -maxdepth 1 -type d \
  ! -name "sharkos*" \
  -exec rm -rf {} + 2>/dev/null || true

# Exemples
rm -rf /usr/share/example-content 2>/dev/null || true
rm -rf /usr/share/games 2>/dev/null || true

# Fichiers Python bytecode temporaires
find / -name "*.pyc" -delete 2>/dev/null || true
find / -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Thumbnails
find /root /home -name "thumbnails" -type d -exec rm -rf {} + 2>/dev/null || true
find /root /home -name ".thumbnails" -type d -exec rm -rf {} + 2>/dev/null || true

# =============================================================================
# RAPPORT FINAL
# =============================================================================
echo ""
DISK_USAGE=$(du -sh / --exclude=/proc --exclude=/sys --exclude=/dev 2>/dev/null | cut -f1)
echo "🦈 ============================================"
echo "   Nettoyage SharkOS terminé !"
echo "   Taille système actuelle : $DISK_USAGE"
echo "   Paquets restants : $(dpkg -l | grep -c '^ii')"
echo "============================================ 🦈"
# =============================================================================
# VÉRIFICATION FINALE — login shark/shark
# =============================================================================
echo "[FINAL] Vérification compte shark..."

# Re-forcer le mot de passe une dernière fois après tout le reste
echo "shark:shark" | chpasswd 2>/dev/null || true
echo "root:shark"  | chpasswd 2>/dev/null || true

# Vérifier que /etc/shadow contient bien shark
if grep -q "^shark:\*" /etc/shadow 2>/dev/null || \
   grep -q "^shark:!" /etc/shadow 2>/dev/null; then
  echo "   ⚠ ATTENTION : compte shark verrouillé dans /etc/shadow !"
  # Forcer le déverrouillage
  usermod -U shark 2>/dev/null || true
  HASH=$(openssl passwd -6 -salt "SharkOS01" "shark")
  sed -i "s|^shark:[^:]*:|shark:${HASH}:|" /etc/shadow
  echo "   ✓ Compte déverrouillé."
else
  echo "   ✓ Compte shark OK"
fi

# Vérifier sudoers
grep -q "shark" /etc/sudoers || echo "shark ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# S'assurer que LightDM est bien installé
dpkg -l lightdm 2>/dev/null | grep -q "^ii" && echo "   ✓ LightDM installé" || \
  echo "   ⚠ LightDM manquant !"

# Lister les sessions disponibles pour LightDM
echo "   Sessions disponibles :"
ls /usr/share/xsessions/ 2>/dev/null | sed 's/^/     - /'

echo "   ✅ Vérification terminée."
echo ""
