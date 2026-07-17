# =============================================================================
# 🦈 SharkOS — .zshrc v3.0
# =============================================================================

# --- Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"

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

[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# =============================================================================
# 🎨 COULEURS UTILITAIRES
# =============================================================================
SHARK_BLUE='\033[1;34m'
SHARK_CYAN='\033[1;36m'
SHARK_GREEN='\033[0;32m'
SHARK_RED='\033[0;31m'
SHARK_YELLOW='\033[1;33m'
SHARK_RESET='\033[0m'
SHARK_BOLD='\033[1m'

_ok()   { echo -e "   ${SHARK_GREEN}✅  $*${SHARK_RESET}"; }
_warn() { echo -e "   ${SHARK_YELLOW}⚠️   $*${SHARK_RESET}"; }
_err()  { echo -e "   ${SHARK_RED}❌  $*${SHARK_RESET}"; }
_step() { echo -e "\n${SHARK_CYAN}📦 $*${SHARK_RESET}"; }

# =============================================================================
# 🦈 PROMPT SHARKOS
# =============================================================================
prompt_sharkos_logo() {
  echo -n "%F{cyan}🦈%f "
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
# 🪟 ALIASES WINDOWS → LINUX
# =============================================================================
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

alias ipconfig='ip a'
alias ipconfig_all='echo "=== Interfaces ===" && ip a && echo "" && echo "=== Routes ===" && ip route && echo "" && echo "=== DNS ===" && cat /etc/resolv.conf'
alias tracert='traceroute'
alias netstat='ss -tulnp'
alias ping='ping -c 4'
alias arp='arp -a'
alias route='ip route'

alias tasklist='ps aux'
alias taskkill='kill -9'
alias systeminfo='inxi -Fxz 2>/dev/null || uname -a && lsb_release -a'
alias ver='cat /etc/os-release'
alias shutdown='sudo shutdown -h now'
alias restart='sudo reboot'
alias mem='free -h'
alias cpu='lscpu'
alias disk='df -h'

alias notepad='mousepad 2>/dev/null || nano'
alias edit='mousepad 2>/dev/null || nano'
alias explorer='thunar . 2>/dev/null || xdg-open .'

# =============================================================================
# 🦈 ALIASES SHARKOS
# =============================================================================
alias shark='echo "🦈 SharkOS — Rapide. Furtif. Létal."'
alias sharkinfo='neofetch --config /etc/sharkos/neofetch.conf 2>/dev/null || neofetch'

alias sharkscan='sudo nmap -sV -O --open'
alias sharksniff='sudo wireshark &>/dev/null &'
alias sharksniff-cli='sudo tcpdump -i any -n'
alias sharkmac='sudo /usr/local/bin/sharkos-mac-randomize'
alias sharkip='echo -n "IP publique : " && curl -s https://ipinfo.io/ip && echo ""'
alias sharkdns='cat /etc/resolv.conf'

alias sharkfw='sudo ufw status verbose'
alias sharkfw-on='sudo ufw enable && echo "🦈 Pare-feu activé."'
alias sharkfw-off='sudo ufw disable && echo "⚠️  Pare-feu désactivé."'
alias sharkfw-add='sudo ufw allow'
alias sharkfw-del='sudo ufw delete allow'

alias sharkav='echo "🦈 Scan ClamAV..." && sudo clamscan -r --bell -i'
alias sharkav-update='sudo freshclam && echo "🦈 Définitions mises à jour."'
alias sharkav-home='sudo clamscan -r --bell -i $HOME'

alias sharkrun='/usr/local/bin/sharkrun'
alias wine-prefix='WINEPREFIX="$HOME/.wine-sharkos" wine'

# Aide rapide
sharkhelp() {
  echo ""
  echo -e "${SHARK_CYAN}╔══════════════════════════════════════════════════════════╗${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_BOLD}  🦈 SharkOS — Commandes disponibles                     ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}╠══════════════════════════════════════════════════════════╣${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_RESET}  ${SHARK_BLUE}update-system${SHARK_RESET} / ${SHARK_BLUE}up${SHARK_RESET} / ${SHARK_BLUE}maj${SHARK_RESET}  → MAJ complète du système   ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_RESET}  ${SHARK_BLUE}sharkscan <ip>${SHARK_RESET}            → Scan nmap                 ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_RESET}  ${SHARK_BLUE}sharkfw${SHARK_RESET}                   → Statut pare-feu UFW       ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_RESET}  ${SHARK_BLUE}sharkav <dossier>${SHARK_RESET}         → Scan antivirus ClamAV    ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_RESET}  ${SHARK_BLUE}sharkmac${SHARK_RESET}                  → Randomise les MACs       ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_RESET}  ${SHARK_BLUE}sharkip${SHARK_RESET}                   → Affiche ton IP publique   ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_RESET}  ${SHARK_BLUE}sharkrun <file.exe>${SHARK_RESET}       → Lance un .exe via Wine   ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_RESET}  ${SHARK_BLUE}sharkinfo${SHARK_RESET}                 → neofetch SharkOS         ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}╚══════════════════════════════════════════════════════════╝${SHARK_RESET}"
  echo ""
}
alias help='sharkhelp'

# =============================================================================
# 🔄 UPDATE-SYSTEM
# =============================================================================
update-system() {
  echo ""
  echo -e "${SHARK_CYAN}╔══════════════════════════════════════════════════════════╗${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_BOLD}  🦈 SharkOS — Mise à jour complète                      ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}╚══════════════════════════════════════════════════════════╝${SHARK_RESET}"

  _step "[1/6] APT — paquets Debian"
  if sudo apt-get update -qq && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y \
      && sudo apt-get autoremove -y --purge && sudo apt-get autoclean -y; then
    _ok "APT à jour."
  else
    _err "APT : erreur lors de la mise à jour."
  fi

  _step "[2/6] Snap"
  if command -v snap &>/dev/null; then
    sudo snap refresh 2>/dev/null && _ok "Snap à jour." || _warn "Snap : aucune mise à jour."
  else
    _warn "Snap non installé, ignoré."
  fi

  _step "[3/6] Flatpak"
  if command -v flatpak &>/dev/null; then
    flatpak update -y 2>/dev/null && _ok "Flatpak à jour." || _warn "Flatpak : aucune mise à jour."
  else
    _warn "Flatpak non installé, ignoré."
  fi

  _step "[4/6] ClamAV — définitions"
  if command -v freshclam &>/dev/null; then
    sudo freshclam 2>/dev/null && _ok "ClamAV à jour." || _warn "ClamAV : déjà à jour ou hors ligne."
  else
    _warn "ClamAV non installé, ignoré."
  fi

  _step "[5/6] Oh My Zsh"
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ( cd "$HOME/.oh-my-zsh" && git pull --quiet origin master 2>/dev/null ) \
      && _ok "Oh My Zsh à jour." || _warn "Oh My Zsh : erreur."
  else
    _warn "Oh My Zsh non installé."
  fi

  _step "[6/6] Winetricks"
  if command -v winetricks &>/dev/null; then
    sudo winetricks --self-update 2>/dev/null && _ok "Winetricks à jour." || _warn "Winetricks : déjà à jour."
  else
    _warn "Winetricks non installé."
  fi

  echo ""
  echo -e "${SHARK_CYAN}╔══════════════════════════════════════════════════════════╗${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_GREEN}${SHARK_BOLD}  ✅ SharkOS entièrement mis à jour ! Système propre. 🦈  ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}╚══════════════════════════════════════════════════════════╝${SHARK_RESET}"
  echo ""
}

alias update='update-system'
alias up='update-system'
alias maj='update-system'

# =============================================================================
# 📦 GESTION PAQUETS RAPIDE
# =============================================================================
alias install='sudo apt install -y'
alias remove='sudo apt purge -y'
alias search='apt search'
alias pkg-info='apt show'
alias list-installed='dpkg -l | grep "^ii"'

alias snap-install='sudo snap install'
alias snap-remove='sudo snap remove'
alias snap-list='snap list'

alias flat-install='flatpak install flathub -y'
alias flat-remove='flatpak uninstall -y'
alias flat-list='flatpak list'

# =============================================================================
# 🌍 ENVIRONNEMENT
# =============================================================================
export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8
export EDITOR="mousepad"
export VISUAL="mousepad"
export TERM=xterm-256color
export OS_NAME="SharkOS"
export GTK_THEME="WhiteSur-Dark"
export PATH="$HOME/.local/bin:/usr/local/bin:/snap/bin:$PATH"

# =============================================================================
# 🦈 ÉCRAN DE BIENVENUE (une fois par session)
# =============================================================================
if [[ -z "$SHARKOS_GREETED" ]]; then
  export SHARKOS_GREETED=1
  neofetch --config /etc/sharkos/neofetch.conf 2>/dev/null || neofetch
  echo ""
  echo -e "${SHARK_CYAN}╔══════════════════════════════════════════════════════════╗${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_BOLD}  🦈  Bienvenue dans SharkOS — Rapide. Furtif. Létal.    ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}╠══════════════════════════════════════════════════════════╣${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_RESET}  ${SHARK_BLUE}up${SHARK_RESET}  → Mettre à jour tout le système                  ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}║${SHARK_RESET}  ${SHARK_BLUE}sharkhelp${SHARK_RESET}  → Afficher toutes les commandes SharkOS   ${SHARK_CYAN}║${SHARK_RESET}"
  echo -e "${SHARK_CYAN}╚══════════════════════════════════════════════════════════╝${SHARK_RESET}"
  echo ""
fi
