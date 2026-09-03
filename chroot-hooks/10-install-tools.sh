#!/usr/bin/env bash
# =============================================================================
# SharkOS — 10-install-tools.sh  v3.0 (Garuda-style)
# Inspiré de Garuda Linux :
#  - Kernel XanMod LTS (gaming/performance)
#  - Zram (compression RAM)
#  - Zstd partout
#  - Flatpak + Flathub par défaut
#  - Outils sécurité Kali-grade
#  - Gaming stack (Wine, Lutris, gamemode)
# =============================================================================
set -euo pipefail

echo ""
echo "🦈 [HOOK 10] Installation des outils SharkOS (Garuda-style)..."
echo ""

# =============================================================================
# 1. MISE À JOUR + PAQUETS DE BASE
# =============================================================================
echo "[1/12] Base APT..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends \
  curl wget git unzip zip ca-certificates \
  lsb-release software-properties-common \
  apt-transport-https gnupg2 \
  xz-utils zstd lz4 \
  build-essential dkms

# =============================================================================
# 2. KERNEL XANMOD LTS (performance / gaming — succède à Liquorix sur Debian)
#    NB : Liquorix n'existe pas pour Debian (script + PPA Ubuntu uniquement).
#    XanMod est le kernel de performance officiellement packagé pour bookworm
#    (branche LTS, scheduler + BBRv3 + MGLRU + latence optimisée → fluide).
# =============================================================================
echo "[2/12] Kernel XanMod LTS (gaming/performance)..."
XANMOD_OK=0
if command -v wget &>/dev/null && command -v gpg &>/dev/null; then
  mkdir -p /etc/apt/keyrings
  wget -qO - https://dl.xanmod.org/archive.key 2>/dev/null | \
    gpg --dearmor -o /etc/apt/keyrings/xanmod-archive-keyring.gpg 2>/dev/null && \
  echo "deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] \
http://deb.xanmod.org bookworm main" > /etc/apt/sources.list.d/xanmod-release.list && \
  apt-get update -qq 2>/dev/null && XANMOD_OK=1
fi

if (( XANMOD_OK == 1 )); then
  # Détection du niveau x86-64 psABI : v3 (AVX2/BMI2/FMA), sinon v2, sinon v1
  XANMOD_PKG="linux-xanmod-lts-x64v3"
  if ! grep -qE '\bavx2\b' /proc/cpuinfo || ! grep -qE '\bbmi2\b' /proc/cpuinfo; then
    XANMOD_PKG="linux-xanmod-lts-x64v2"
  fi
  # v2 requiert SSE4.2 + POPCNT ; sinon on retombe sur v1 (compat max)
  if ! grep -qE '\bsse4_2\b' /proc/cpuinfo || ! grep -qE '\bpopcnt\b' /proc/cpuinfo; then
    XANMOD_PKG="linux-xanmod-lts-x64v1"
  fi
  if apt-cache show "$XANMOD_PKG" &>/dev/null; then
    apt-get install -y --no-install-recommends "$XANMOD_PKG" 2>/dev/null || \
      echo "   ⚠ XanMod $XANMOD_PKG indisponible — kernel Debian par défaut conservé"
  else
    echo "   ⚠ Paquet XanMod introuvable — kernel Debian par défaut conservé"
  fi
else
  echo "   ⚠ Repo XanMod inaccessible (pas de wget/gpg/réseau) — kernel Debian par défaut"
fi

# =============================================================================
# 3. ZRAM (compression RAM — Garuda active ça par défaut)
# =============================================================================
echo "[3/12] Zram + zstd compression..."
apt-get install -y --no-install-recommends \
  zram-tools 2>/dev/null || \
apt-get install -y --no-install-recommends \
  zramswap-enabler 2>/dev/null || true

# Config Zram : 50% de la RAM en zstd
mkdir -p /etc/default
cat > /etc/default/zramswap << 'EOF'
# SharkOS Zram — style Garuda
PERCENT=50
PRIORITY=100
COMPRESSION=zstd
EOF

# Script zram-setup fallback (si zram-tools absent)
cat > /usr/local/bin/sharkos-zram-setup << 'ZRAM'
#!/usr/bin/env bash
# SharkOS — Activation Zram au boot
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
ZRAM_KB=$((RAM_KB / 2))
modprobe zram 2>/dev/null || exit 0
echo zstd > /sys/block/zram0/comp_algorithm 2>/dev/null || \
  echo lz4  > /sys/block/zram0/comp_algorithm 2>/dev/null || true
echo "${ZRAM_KB}K" > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon -p 100 /dev/zram0
echo "🦈 Zram actif : ${ZRAM_KB}K en swap compressé"
ZRAM
chmod +x /usr/local/bin/sharkos-zram-setup

cat > /etc/systemd/system/sharkos-zram.service << 'EOF'
[Unit]
Description=SharkOS Zram Setup
Before=swap.target
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/usr/local/bin/sharkos-zram-setup
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl enable sharkos-zram.service 2>/dev/null || true

# =============================================================================
# 3b. CPU GOVERNOR — fluidité (schedutil au boot, performance sur demande)
# =============================================================================
echo "[3b/12] CPU governor (schedutil au boot)..."
apt-get install -y --no-install-recommends \
  linux-cpupower 2>/dev/null || true

cat > /etc/systemd/system/sharkos-governor.service << 'EOF'
[Unit]
Description=SharkOS CPU Governor (schedutil)
After=multi-user.target

[Service]
Type=oneshot
# Résilient : en VM/QEMU il n'y a pas de pilote cpufreq → cpupower échoue
# ([FAILED] sharkos-governor au boot, vu dans le test QEMU v3.0.20). Sortie
# silencieuse si cpupower absent OU /sys cpufreq inexistant. shark-turbo
# (hook 60) continue de marcher : il sed-remplace "-g <governor>" ici même.
ExecStart=/bin/sh -c 'command -v cpupower >/dev/null 2>&1 || exit 0; [ -d /sys/devices/system/cpu/cpu0/cpufreq ] || exit 0; exec cpupower frequency-set -g schedutil'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl enable sharkos-governor.service 2>/dev/null || true

# =============================================================================
# 4. OPTIMISATIONS PERFORMANCES (sysctl — comme Garuda)
# =============================================================================
echo "[4/12] Sysctl performance (vm.swappiness, inotify, etc)..."

cat > /etc/sysctl.d/99-sharkos-performance.conf << 'EOF'
# SharkOS Performance — inspiré Garuda Linux

# Swappiness faible (préférer RAM)
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# Réseau haute performance
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
# BBR (module chargé via /etc/modules — voir hook 40)
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# Inotify (dev / IDE)
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512

# Sécurité réseau
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Perf I/O
vm.page-cluster = 0
kernel.nmi_watchdog = 0

# Fluidité interaction (autogroup évite les à-coups quand plusieurs apps tournent)
kernel.sched_autogroup_enabled = 1
# Writeback plus fréquent → moins de gel disque sous charge
vm.dirty_writeback_centisecs = 500
vm.dirty_expire_centisecs = 3000

# ─────────────────────────────────────────────────────────────────────
# HARDENING KERNEL (sécurité maximale)
# ─────────────────────────────────────────────────────────────────────
# Restreindre dmesg aux root (fuite d'infos kernel)
kernel.dmesg_restrict = 1
# Masquer les pointeurs kernel (mitigation KASLR)
kernel.kptr_restrict = 2
# Restreindre ptrace (anti-injection entre processus d'utilisateurs différents)
kernel.yama.ptrace_scope = 2
# Pas de core dumps de setuid dans /tmp (fuite de données sensibles)
fs.suid_dumpable = 0
# Anti-spoofing
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
# Anti-synflood + time-wait recycling
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 1
# Ignorer les ICMP broadcast
net.ipv4.icmp_ignore_bogus_error_responses = 1
# Pas de redirection source-routed
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.send_redirects = 0
# Logguer les paquets martiens
net.ipv4.conf.all.log_martians = 1
# Réduire l'exposition IPv6
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2
EOF

# =============================================================================
# 5. ZSH + OH MY ZSH (Powerlevel10k comme Garuda)
# =============================================================================
echo "[5/12] ZSH + Powerlevel10k..."
apt-get install -y --no-install-recommends \
  zsh \
  zsh-syntax-highlighting \
  zsh-autosuggestions \
  fonts-powerline \
  fonts-font-awesome

# JetBrainsMono Nerd Font (essentiel pour Powerlevel10k)
mkdir -p /usr/local/share/fonts/JetBrainsMono
curl -sL \
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" \
  -o /tmp/JBMono.zip 2>/dev/null && \
  unzip -q /tmp/JBMono.zip -d /usr/local/share/fonts/JetBrainsMono/ 2>/dev/null && \
  rm /tmp/JBMono.zip && \
  fc-cache -f 2>/dev/null || \
echo "   ⚠ JetBrainsMono Nerd Font : installation manuelle recommandée"

# MiSans — police officielle HyperOS (Xiaomi) → look HyperOS 6.0
# Licence : libre d'usage avec attribution (pas de redistribution du fichier
# seul → on télécharge au build, comme Catppuccin/JetBrainsMono).
mkdir -p /usr/local/share/fonts/MiSans
curl -sL \
  "https://cdn.jsdelivr.net/gh/iota9star/fonts@master/misans/MiSans-Regular.ttf" \
  -o /usr/local/share/fonts/MiSans/MiSans-Regular.ttf 2>/dev/null && \
curl -sL \
  "https://cdn.jsdelivr.net/gh/iota9star/fonts@master/misans/MiSans-Medium.ttf" \
  -o /usr/local/share/fonts/MiSans/MiSans-Medium.ttf 2>/dev/null && \
curl -sL \
  "https://cdn.jsdelivr.net/gh/iota9star/fonts@master/misans/MiSans-Bold.ttf" \
  -o /usr/local/share/fonts/MiSans/MiSans-Bold.ttf 2>/dev/null && \
fc-cache -f 2>/dev/null && \
echo "   ✓ MiSans (police HyperOS) installée" || \
echo "   ⚠ MiSans indisponible — fallback fonts-noto (déjà installé)"

ZSH_PATH="$(command -v zsh 2>/dev/null || echo /bin/bash)"

# Compte shark
if ! id "shark" &>/dev/null; then
  useradd -m -s "$ZSH_PATH" -G sudo,audio,video,plugdev,netdev shark 2>/dev/null || \
  useradd -m -s "$ZSH_PATH" shark 2>/dev/null || true
fi
echo "shark:shark" | chpasswd 2>/dev/null || true
echo "root:shark"  | chpasswd 2>/dev/null || true

if ! grep -q "^shark " /etc/sudoers 2>/dev/null; then
  echo "shark ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

for TARGET_USER in root shark; do
  HOME_DIR="/home/$TARGET_USER"
  [[ "$TARGET_USER" == "root" ]] && HOME_DIR="/root"
  mkdir -p "$HOME_DIR"

  # Oh My Zsh
  if [[ ! -d "$HOME_DIR/.oh-my-zsh" ]]; then
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git \
      "$HOME_DIR/.oh-my-zsh" 2>/dev/null || true
  fi

  ZSH_CUSTOM="$HOME_DIR/.oh-my-zsh/custom"

  # Powerlevel10k
  if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$ZSH_CUSTOM/themes/powerlevel10k" 2>/dev/null || true
  fi

  # Plugins
  for PLUGIN_REPO in \
    "zsh-users/zsh-syntax-highlighting" \
    "zsh-users/zsh-autosuggestions" \
    "zsh-users/zsh-history-substring-search"; do
    PLUGIN_NAME="$(basename $PLUGIN_REPO)"
    if [[ ! -d "$ZSH_CUSTOM/plugins/$PLUGIN_NAME" ]]; then
      git clone --depth=1 "https://github.com/$PLUGIN_REPO.git" \
        "$ZSH_CUSTOM/plugins/$PLUGIN_NAME" 2>/dev/null || true
    fi
  done

  chown -R "$TARGET_USER:$TARGET_USER" "$HOME_DIR" 2>/dev/null || true
done

chsh -s "$ZSH_PATH" root  2>/dev/null || true
chsh -s "$ZSH_PATH" shark 2>/dev/null || true

# =============================================================================
# 6. OUTILS SÉCURITÉ (grade Kali)
# =============================================================================
echo "[6/12] Arsenal sécurité Kali-grade..."
apt-get install -y --no-install-recommends \
  nmap \
  wireshark \
  ufw gufw \
  net-tools iputils-ping traceroute dnsutils whois \
  tcpdump netcat-openbsd macchanger \
  aircrack-ng \
  john \
  hydra \
  sqlmap \
  nikto \
  dirb \
  gobuster \
  hashcat \
  binwalk \
  foremost \
  steghide \
  libimage-exiftool-perl 2>/dev/null || true

# volatility3 absent des dépôts bookworm (arrivé en trixie) — install séparé
# pour ne pas faire échouer tout l'arsenal sécurité ci-dessus (même schéma
# que le bug snap-sync/btrfs-progs corrigé précédemment).
apt-get install -y --no-install-recommends \
  volatility3 2>/dev/null || true

echo "wireshark-common wireshark-common/install-setuid boolean true" \
  | debconf-set-selections
dpkg-reconfigure -f noninteractive wireshark-common 2>/dev/null || true
usermod -aG wireshark shark 2>/dev/null || true

# Macchanger service
cat > /usr/local/bin/sharkos-mac-randomize << 'MACSCRIPT'
#!/usr/bin/env bash
for IFACE in $(ip link show | awk -F': ' '/^[0-9]+: (wl|en|eth)/{print $2}' | cut -d'@' -f1); do
  ip link set "$IFACE" down 2>/dev/null || continue
  macchanger -r "$IFACE" 2>/dev/null && echo "  ✓ $IFACE randomisée" || true
  ip link set "$IFACE" up   2>/dev/null || true
done
MACSCRIPT
chmod +x /usr/local/bin/sharkos-mac-randomize

cat > /etc/systemd/system/sharkos-mac-randomize.service << 'EOF'
[Unit]
Description=SharkOS MAC Randomize
Before=network.target
After=udev.target
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/usr/local/bin/sharkos-mac-randomize
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl enable sharkos-mac-randomize.service 2>/dev/null || true

# =============================================================================
# 7. GAMING STACK — OPTIONNEL (hors ISO pour rester < 2 Go)
#    NB taille : Wine 64+32 + libs i386 ≈ 1,8 Go. Installé à la demande avec
#    `shark-extras gaming` (voir 50-sharkos-finalize.sh). Le dépôt i386 est
#    activé ici pour que l'install à la demande fonctionne du premier coup.
# =============================================================================
echo "[7/12] Multiarch i386 (pour shark-extras gaming)..."
dpkg --add-architecture i386 2>/dev/null || true
apt-get update -qq

# Script game-launcher helper (présent même sans la stack — shark-extras l'active)
cat > /usr/local/bin/sharkgame << 'SHARKGAME'
#!/usr/bin/env bash
# SharkOS Game Launcher — active GameMode + MangoHud (si installé)
if [[ -z "${1:-}" ]]; then
  echo "Usage: sharkgame <commande>"
  echo "       sharkgame lutris"
  echo "       sharkgame wine game.exe"
  echo "⚠  Stack gaming absente — lance : sudo shark-extras gaming"
  exit 1
fi
if ! command -v gamemoderun &>/dev/null; then
  echo "⚠  GameMode absent — lance : sudo shark-extras gaming"
  exit 1
fi
exec gamemoderun env MANGOHUD=1 "$@"
SHARKGAME
chmod +x /usr/local/bin/sharkgame

# =============================================================================
# 8. FLATPAK + FLATHUB (comme Garuda — pas de Snap par défaut)
# =============================================================================
echo "[8/12] Flatpak + Flathub..."
apt-get install -y --no-install-recommends \
  flatpak \
  xdg-desktop-portal \
  xdg-desktop-portal-kde 2>/dev/null || \
apt-get install -y --no-install-recommends \
  flatpak \
  xdg-desktop-portal-gtk 2>/dev/null || true

flatpak remote-add --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# =============================================================================
# 9. UTILITAIRES SYSTÈME
# =============================================================================
echo "[9/12] Utilitaires système..."
apt-get install -y --no-install-recommends \
  neofetch 2>/dev/null || true

# fastfetch absent des dépôts bookworm — install séparé pour ne pas bloquer
# neofetch (le hook écrit aussi une config fastfetch dans /etc/skel, elle
# sera utilisée dès que le paquet est disponible).
apt-get install -y --no-install-recommends \
  fastfetch 2>/dev/null || true

apt-get install -y --no-install-recommends \
  htop \
  btop \
  inxi \
  dconf-cli \
  gdebi-core \
  imagemagick \
  ripgrep \
  fd-find \
  bat \
  fzf 2>/dev/null || true

# eza absent des dépôts bookworm (présent depuis trixie) — htop/dconf-cli/…
# ne doivent pas être bloqués par lui ; exa (v1) sert de secours.
apt-get install -y --no-install-recommends \
  eza 2>/dev/null || \
apt-get install -y --no-install-recommends \
  exa 2>/dev/null || true

# Alias pour les outils modernes
cat > /etc/profile.d/sharkos-aliases.sh << 'ALIASES'
#!/bin/sh
# SharkOS — Outils modernes
command -v bat  &>/dev/null && alias cat='bat --style=plain'
command -v eza  &>/dev/null && alias ls='eza --icons' && alias ll='eza -la --icons'
command -v exa  &>/dev/null && alias ls='exa --icons' && alias ll='exa -la --icons'
command -v fd   &>/dev/null && alias find='fd'
command -v rg   &>/dev/null && alias grep='rg'
ALIASES
chmod +x /etc/profile.d/sharkos-aliases.sh

# =============================================================================
# 10. CLAMAV
# =============================================================================
echo "[10/12] ClamAV..."
apt-get install -y --no-install-recommends \
  clamav clamav-freshclam clamtk 2>/dev/null || true
freshclam --quiet 2>/dev/null || true
systemctl enable clamav-freshclam.service 2>/dev/null || true

# =============================================================================
# 11. BTRFS UTILS (Garuda utilise Btrfs + snapshots auto)
# =============================================================================
echo "[11/12] Btrfs utils + snapper..."
# btrfs-progs + snapper en premier : ne pas laisser un paquet optionnel
# (snap-sync, absent des dépôts Debian) bloquer leur installation.
apt-get install -y --no-install-recommends \
  btrfs-progs \
  snapper 2>/dev/null || true
apt-get install -y --no-install-recommends \
  snap-sync 2>/dev/null || true

cat > /usr/local/bin/sharkos-snapshot << 'SNAPSHOT'
#!/usr/bin/env bash
# SharkOS Snapshot — wrapper snapper
SUBVOL="${1:-.}"
DESC="${2:-SharkOS-auto-$(date +%Y%m%d-%H%M%S)}"
btrfs subvolume snapshot -r "$SUBVOL" "/snapshots/${DESC}" 2>/dev/null || \
snapper create --description "$DESC" 2>/dev/null || \
echo "⚠ Snapper non configuré (normal sur ext4)"
SNAPSHOT
chmod +x /usr/local/bin/sharkos-snapshot

# =============================================================================
# 12. NEOFETCH / FASTFETCH SHARKOS
# =============================================================================
echo "[12/12] Fastfetch config SharkOS..."
mkdir -p /etc/sharkos /etc/skel/.config/fastfetch

cat > /etc/skel/.config/fastfetch/config.jsonc << 'FFCONF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "builtin",
    "source": "debian",
    "color": { "1": "blue", "2": "bright_blue" }
  },
  "display": {
    "color": "blue",
    "separator": " → ",
    "key": { "width": 18 }
  },
  "modules": [
    { "type": "title",      "format": "🦈 {user-name}@{host-name}" },
    "break",
    { "type": "os",         "key": "  OS" },
    { "type": "kernel",     "key": "  Kernel" },
    { "type": "uptime",     "key": "  Uptime" },
    { "type": "packages",   "key": "  Packages" },
    { "type": "shell",      "key": "  Shell" },
    { "type": "de",         "key": "  Desktop" },
    { "type": "wm",         "key": "  WM" },
    { "type": "theme",      "key": "  Theme" },
    { "type": "icons",      "key": "  Icons" },
    { "type": "terminal",   "key": "  Terminal" },
    { "type": "font",       "key": "  Font" },
    { "type": "cpu",        "key": "  CPU" },
    { "type": "gpu",        "key": "  GPU" },
    { "type": "memory",     "key": "  RAM" },
    { "type": "disk",       "key": "  Disk" },
    "break",
    { "type": "colors",     "paddingLeft": 2 }
  ]
}
FFCONF

# Neofetch fallback
mkdir -p /etc/skel/.config/neofetch
cat > /etc/skel/.config/neofetch/config.conf << 'NEOFETCH'
print_info() {
    info "🦈 SharkOS" distro
    info "Kernel" kernel
    info "Uptime" uptime
    info "Packages" packages
    info "Shell" shell
    info "DE" de
    info "WM" wm
    info "Theme" theme
    info "Icons" icons
    info "Terminal" term
    info "CPU" cpu
    info "GPU" gpu
    info "RAM" memory
    info "Disk" disk
    prin ""
    prin "🦈 Rapide. Furtif. Létal."
    prin "⚡ Propulsé par XanMod + Zram + Btrfs"
}
ascii_distro="Debian"
colors=(4 4 4 4 4 4)
bold="on"
NEOFETCH

echo ""
echo "✅ [HOOK 10] Outils installés — Kernel XanMod + Zram + Gaming Stack"
echo ""
