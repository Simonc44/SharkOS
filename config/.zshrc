# =============================================================================
# 🦈 SharkOS — .zshrc
# Shell ZSH : Oh My Zsh, thème agnoster, aliases Windows, prompt SharkOS
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
)

source $ZSH/oh-my-zsh.sh

# =============================================================================
# PROMPT SHARKOS 🦈
# =============================================================================
# Surcharge du prompt Oh My Zsh pour afficher "SharkOS 🦈"
SHARKOS_PROMPT_PREFIX="%F{cyan}SharkOS 🦈%f "

# Injection du préfixe dans le segment agnoster build_prompt
build_prompt() {
  RETVAL=$?
  echo -n "$SHARKOS_PROMPT_PREFIX"
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  prompt_end
}

PROMPT='$(build_prompt) '

# =============================================================================
# ALIASES WINDOWS → LINUX (ADN Windows)
# =============================================================================

# Navigation & listing
alias dir='ls -la --color=auto'
alias cls='clear'
alias md='mkdir -p'
alias rd='rmdir'
alias move='mv'
alias copy='cp'
alias del='rm -i'
alias ren='mv'

# Réseau
alias ipconfig='ip a'
alias ipconfig_all='ip a && ip route && cat /etc/resolv.conf'
alias tracert='traceroute'
alias nslookup='nslookup'
alias netstat='ss -tulnp'
alias ping='ping -c 4'

# Système
alias tasklist='ps aux'
alias taskkill='kill -9'
alias systeminfo='inxi -Fxz'
alias ver='lsb_release -a'
alias hostname='hostname -f'
alias shutdown='sudo shutdown -h now'
alias restart='sudo reboot'

# Editeur
alias notepad='mousepad'
alias edit='mousepad'

# =============================================================================
# ALIASES SHARKOS CUSTOM 🦈
# =============================================================================
alias shark='echo "🦈 SharkOS — Prêt à attaquer !"'
alias sharkinfo='neofetch'
alias sharkscan='nmap -sV -O'
alias sharksniff='sudo wireshark &'
alias sharkfw='sudo ufw status verbose'
alias sharkfw-on='sudo ufw enable'
alias sharkfw-off='sudo ufw disable'
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
alias remove='sudo apt remove -y'
alias search='apt search'

# =============================================================================
# VARIABLES D'ENVIRONNEMENT
# =============================================================================
export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8
export EDITOR=mousepad
export TERM=xterm-256color
export OS_NAME="SharkOS"

# =============================================================================
# NEOFETCH AU DÉMARRAGE
# =============================================================================
# Affiche les infos système à l'ouverture du terminal
if command -v neofetch &>/dev/null; then
  neofetch --ascii_distro Debian
fi

# Message de bienvenue SharkOS
echo ""
echo "  🦈 Bienvenue dans SharkOS — Rapide, Furtif, Létal."
echo "  Tape 'shark' pour un message de motivation."
echo ""
