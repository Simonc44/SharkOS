# =============================================================================
# 🦈 SharkOS — .zshrc v2.0
# ZSH + Oh My Zsh + Agnoster + Aliases Windows + Aliases SharkOS + update-system
# =============================================================================

# --- Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"

# Plugins actifs
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  z
  colored-man-pages
  command-not-found
  sudo
  history
)

source $ZSH/oh-my-zsh.sh 2>/dev/null || true

# Plugins système (installés via apt)
[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# =============================================================================
# 🦈 PROMPT SHARKOS PERSONNALISÉ
# =============================================================================
# Surcharge du build_prompt Oh My Zsh (thème agnoster)
prompt_sharkos_logo() {
  echo -n "%F{cyan}🦈 SharkOS%f "
}

build_prompt() {
  RETVAL=$?
  prompt_sharkos_logo
  prompt_status
  prompt_virtualenv
  prompt_dir
  prompt_git
  prompt_end
}

PROMPT='$(build_prompt) '

# =============================================================================
# 🪟 ALIASES WINDOWS → LINUX (ADN Windows)
# =============================================================================

# --- Navigation & fichiers ---
alias dir='ls -la --color=auto'
alias cls='clear'
alias md='mkdir -p'
alias rd='rmdir'
alias move='mv'
alias copy='cp -i'
alias del='rm -i'
alias ren='mv'
alias type='cat'
alias attrib='chmod'
alias xcopy='cp -r'

# --- Réseau ---
alias ipconfig='ip a'
alias ipconfig_all='echo "=== Interfaces ===" && ip a && echo "" && echo "=== Routes ===" && ip route && echo "" && echo "=== DNS ===" && cat /etc/resolv.conf'
alias tracert='traceroute'
alias netstat='ss -tulnp'
alias ping='ping -c 4'
alias arp='arp -a'
alias route='ip route'
alias nbtstat='nmblookup'

# --- Processus / système ---
alias tasklist='ps aux'
alias taskkill='kill -9'
alias systeminfo='inxi -Fxz 2>/dev/null || uname -a && lsb_release -a'
alias ver='lsb_release -a 2>/dev/null || cat /etc/os-release'
alias hostname='hostname -f'
alias shutdown='sudo shutdown -h now'
alias restart='sudo reboot'
alias mem='free -h'
alias cpu='lscpu'
alias disk='df -h'

# --- Editeur / applications ---
alias notepad='mousepad 2>/dev/null || gedit 2>/dev/null || nano'
alias edit='mousepad 2>/dev/null || nano'
alias explorer='thunar . 2>/dev/null || xdg-open . 2>/dev/null'
alias calc='xcalc 2>/dev/null || bc -l'

# --- Divers ---
alias cls='clear'
alias echo='echo'
alias find='find'
alias time='time'

# =============================================================================
# 🦈 ALIASES SHARKOS — Sécurité & Outils
# =============================================================================

# --- Identité SharkOS ---
alias shark='echo "🦈 SharkOS — Rapide. Furtif. Létal. 🦈"'
alias sharkinfo='neofetch --config /etc/sharkos/neofetch.conf 2>/dev/null || neofetch'

# --- Réseau & sécurité ---
alias sharkscan='sudo nmap -sV -O --open'
alias sharksniff='sudo wireshark & 2>/dev/null'
alias sharksniff-cli='sudo tcpdump -i any -n'
alias sharkmac='sudo /usr/local/bin/sharkos-mac-randomize'
alias sharkip='curl -s https://ipinfo.io/ip && echo ""'
alias sharkdns='cat /etc/resolv.conf'

# --- Pare-feu ---
alias sharkfw='sudo ufw status verbose'
alias sharkfw-on='sudo ufw enable && echo "🦈 Pare-feu activé."'
alias sharkfw-off='sudo ufw disable && echo "⚠️  Pare-feu désactivé."'
alias sharkfw-add='sudo ufw allow'
alias sharkfw-del='sudo ufw delete allow'

# --- Antivirus ClamAV ---
alias sharkav='echo "🦈 Scan ClamAV en cours..." && sudo clamscan -r --bell -i'
alias sharkav-update='sudo freshclam && echo "🦈 Définitions ClamAV mises à jour."'
alias sharkav-home='sudo clamscan -r --bell -i $HOME'

# --- Exécution Windows (.exe) via Wine ---
alias sharkrun='/usr/local/bin/sharkrun'
alias wine-prefix='WINEPREFIX="$HOME/.wine-sharkos" wine'

# =============================================================================
# 🔄 UPDATE-SYSTEM — Mise à jour universelle de tout le système
# =============================================================================
update-system() {
  echo ""
  echo "🦈 ========================================================"
  echo "   SharkOS — Mise à jour complète du système"
  echo "======================================================== 🦈"
  echo ""

  # --- APT (Debian/Ubuntu) ---
  echo "📦 [1/6] Mise à jour APT (paquets Debian)..."
  sudo apt-get update -qq && \
  sudo apt-get upgrade -y && \
  sudo apt-get dist-upgrade -y && \
  sudo apt-get autoremove -y --purge && \
  sudo apt-get autoclean -y
  echo "   ✅ APT à jour."
  echo ""

  # --- SNAP ---
  echo "📦 [2/6] Mise à jour Snap..."
  if command -v snap &>/dev/null; then
    sudo snap refresh 2>/dev/null && echo "   ✅ Snap à jour." || echo "   ⚠️  Snap : aucune mise à jour ou erreur."
  else
    echo "   ℹ️  Snap non installé, ignoré."
  fi
  echo ""

  # --- FLATPAK ---
  echo "📦 [3/6] Mise à jour Flatpak..."
  if command -v flatpak &>/dev/null; then
    flatpak update -y 2>/dev/null && echo "   ✅ Flatpak à jour." || echo "   ⚠️  Flatpak : aucune mise à jour ou erreur."
  else
    echo "   ℹ️  Flatpak non installé, ignoré."
  fi
  echo ""

  # --- ClamAV (Définitions antivirus) ---
  echo "🛡️  [4/6] Mise à jour ClamAV (définitions virales)..."
  if command -v freshclam &>/dev/null; then
    sudo freshclam 2>/dev/null && echo "   ✅ ClamAV définitions à jour." || echo "   ⚠️  ClamAV : déjà à jour ou erreur réseau."
  else
    echo "   ℹ️  ClamAV non installé, ignoré."
  fi
  echo ""

  # --- OH MY ZSH ---
  echo "🐚 [5/6] Mise à jour Oh My Zsh..."
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ( cd "$HOME/.oh-my-zsh" && git pull --quiet origin master 2>/dev/null ) && \
      echo "   ✅ Oh My Zsh à jour." || echo "   ⚠️  Oh My Zsh : erreur de mise à jour."
  else
    echo "   ℹ️  Oh My Zsh non installé, ignoré."
  fi
  echo ""

  # --- WINE / WINETRICKS ---
  echo "🍷 [6/6] Mise à jour Winetricks..."
  if command -v winetricks &>/dev/null; then
    sudo winetricks --self-update 2>/dev/null && echo "   ✅ Winetricks à jour." || echo "   ℹ️  Winetricks : déjà à jour."
  else
    echo "   ℹ️  Winetricks non installé, ignoré."
  fi
  echo ""

  echo "🦈 ========================================================"
  echo "   ✅ SharkOS entièrement mis à jour !"
  echo "   Système propre, rapide et à jour. 🦈"
  echo "========================================================"
  echo ""
}

# Alias court pour update-system
alias update='update-system'
alias up='update-system'
alias maj='update-system'

# =============================================================================
# ALIASES ADMINISTRATION RAPIDE
# =============================================================================
alias install='sudo apt install -y'
alias remove='sudo apt purge -y'
alias search='apt search'
alias pkg-info='apt show'
alias list-installed='dpkg -l | grep "^ii"'

# Snap
alias snap-install='sudo snap install'
alias snap-remove='sudo snap remove'
alias snap-list='snap list'
alias snap-find='snap find'

# Flatpak
alias flat-install='flatpak install flathub -y'
alias flat-remove='flatpak uninstall -y'
alias flat-list='flatpak list'
alias flat-find='flatpak search'

# =============================================================================
# VARIABLES D'ENVIRONNEMENT
# =============================================================================
export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8
export EDITOR="mousepad"
export VISUAL="mousepad"
export TERM=xterm-256color
export OS_NAME="SharkOS"
export GTK_THEME="WhiteSur-Dark"

# PATH étendu
export PATH="$HOME/.local/bin:/usr/local/bin:/snap/bin:$PATH"

# =============================================================================
# ÉCRAN DE BIENVENUE 🦈
# =============================================================================
# Neofetch au démarrage du terminal
if command -v neofetch &>/dev/null && [[ -z "$SHARKOS_GREETED" ]]; then
  export SHARKOS_GREETED=1
  neofetch --config /etc/sharkos/neofetch.conf 2>/dev/null || neofetch
  echo ""
  echo "  🦈 Bienvenue dans SharkOS — Rapide. Furtif. Létal."
  echo "  📦 update-system   → Met à jour APT + Snap + Flatpak + ClamAV + ZSH"
  echo "  🔍 sharkscan <ip>  → Scan réseau Nmap"
  echo "  🔒 sharkfw         → Statut du pare-feu"
  echo "  🦠 sharkav <dir>   → Scan antivirus ClamAV"
  echo "  🍷 sharkrun <exe>  → Lance un .exe Windows"
  echo "  🎭 sharkmac        → Randomise tes adresses MAC"
  echo ""
fi
