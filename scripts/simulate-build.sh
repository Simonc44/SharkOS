#!/usr/bin/env bash
# =============================================================================
# 🦈 SharkOS — simulate-build.sh (SIMULATEUR & VALIDATEUR)
# Ce script simule la préparation de la build et valide l'intégralité
# de tes configurations pour détecter et prévenir les erreurs avant la vraie build.
# =============================================================================
set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0;m' # No Color

# Initialisation des compteurs
ERRORS=0
WARNINGS=0

echo -e "${BLUE}🦈 ========================================================${NC}"
echo -e "${BLUE}   SharkOS — Simulateur & Validateur de Build${NC}"
echo -e "${BLUE}======================================================== 🦈${NC}"
echo -e "Ce simulateur va vérifier tes fichiers pour s'assurer que"
echo -e "la création de l'ISO SharkOS se passera sans aucune erreur !"
echo ""

# Répertoire du projet
SHARK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SHARK_DIR"

# Fonction utilitaire pour afficher un statut
show_success() {
  echo -e "  ${GREEN}✅ $1${NC}"
}

show_warning() {
  echo -e "  ${YELLOW}⚠️  $1${NC}"
  WARNINGS=$((WARNINGS + 1))
}

show_error() {
  echo -e "  ${RED}❌ $1${NC}"
  ERRORS=$((ERRORS + 1))
}

# =============================================================================
# ÉTAPE 1 — Structure du Projet
# =============================================================================
echo -e "${CYAN}📁 1. Vérification de la structure du projet...${NC}"

# Liste des fichiers critiques
CRITICAL_FILES=(
  "scripts/00-bootstrap.sh"
  "scripts/01-build-iso.sh"
  "scripts/02-flash-usb.sh"
  "chroot-hooks/10-install-tools.sh"
  "chroot-hooks/20-apply-theme.sh"
  "chroot-hooks/30-configure-shell.sh"
  "chroot-hooks/40-cleanup.sh"
  "config/.zshrc"
  "config/plank.dconf"
  "config/xfce4-panel.xml"
  "README.md"
  "INSTRUCTIONS.md"
)

for FILE in "${CRITICAL_FILES[@]}"; do
  if [[ -f "$FILE" ]]; then
    show_success "Fichier trouvé : $FILE"
  else
    show_error "Fichier CRITIQUE manquant : $FILE"
  fi
done

# Dossiers requis
CRITICAL_DIRS=(
  "wallpapers"
  ".github/workflows"
)

for DIR in "${CRITICAL_DIRS[@]}"; do
  if [[ -d "$DIR" ]]; then
    show_success "Dossier trouvé : $DIR"
  else
    show_error "Dossier CRITIQUE manquant : $DIR"
  fi
done

# =============================================================================
# ÉTAPE 2 — Validation des Assets Wallpapers/Logo
# =============================================================================
echo ""
echo -e "${CYAN}🖼️  2. Validation des Assets (Fond d'écran et Logo)...${NC}"

# Vérifier aucun SVG dans wallpapers/
SVG_FILES=$(find wallpapers/ -name "*.svg" 2>/dev/null || true)
if [[ -n "$SVG_FILES" ]]; then
  show_error "Fichier .svg trouvé dans wallpapers/ : $SVG_FILES (SharkOS n'accepte que des PNG !)"
else
  show_success "Aucun fichier SVG indésirable dans wallpapers/"
fi

# Validation de wallpaper.png
if [[ -f "wallpapers/wallpaper.png" ]]; then
  if command -v file &>/dev/null; then
    MIME=$(file --mime-type -b "wallpapers/wallpaper.png")
    if [[ "$MIME" == "image/png" ]]; then
      show_success "wallpaper.png est un fichier PNG valide."
    else
      show_error "wallpaper.png existe mais n'est pas un vrai PNG ! (détecté : $MIME)"
    fi
  else
    show_success "wallpaper.png trouvé (l'utilitaire 'file' n'est pas installé pour valider son format)."
  fi
else
  show_warning "wallpapers/wallpaper.png absent — il sera généré automatiquement avec ImageMagick pendant la build."
fi

# Validation de logo.png
if [[ -f "wallpapers/logo.png" ]]; then
  if command -v file &>/dev/null; then
    MIME=$(file --mime-type -b "wallpapers/logo.png")
    if [[ "$MIME" == "image/png" ]]; then
      show_success "logo.png est un fichier PNG valide."
    else
      show_error "logo.png existe mais n'est pas un vrai PNG ! (détecté : $MIME)"
    fi
  else
    show_success "logo.png trouvé (l'utilitaire 'file' n'est pas installé pour valider son format)."
  fi
else
  show_warning "wallpapers/logo.png absent — il sera généré automatiquement avec ImageMagick pendant la build."
fi

# =============================================================================
# ÉTAPE 3 — Validation de la configuration XFCE & Plank
# =============================================================================
echo ""
echo -e "${CYAN}⚙️  3. Validation des configurations XML et Plank...${NC}"

# Validation xfce4-panel.xml
if [[ -f "config/xfce4-panel.xml" ]]; then
  if command -v xmllint &>/dev/null; then
    if xmllint --noout "config/xfce4-panel.xml" 2>/dev/null; then
      show_success "config/xfce4-panel.xml est un XML valide."
    else
      show_error "config/xfce4-panel.xml contient des erreurs de syntaxe XML !"
    fi
  else
    # Simple vérification naïve
    if grep -q "<?xml" "config/xfce4-panel.xml" && grep -q "</channel>" "config/xfce4-panel.xml"; then
      show_success "config/xfce4-panel.xml semble structurellement valide (xmllint absent)."
    else
      show_error "config/xfce4-panel.xml semble mal formé (balises XML de base manquantes)."
    fi
  fi
fi

# Validation plank.dconf
if [[ -f "config/plank.dconf" ]]; then
  if grep -q "Position=3" "config/plank.dconf"; then
    show_success "config/plank.dconf positionne correctement Plank en bas (Position=3)."
  else
    show_warning "config/plank.dconf ne spécifie pas Position=3 (Plank pourrait ne pas être en bas par défaut)."
  fi
  if grep -qi "zoom" "config/plank.dconf"; then
    show_success "config/plank.dconf active bien les effets de Zoom."
  else
    show_warning "config/plank.dconf ne spécifie pas l'effet Zoom de Plank."
  fi
fi

# =============================================================================
# ÉTAPE 4 — Validation de la cohérence du .zshrc
# =============================================================================
echo ""
echo -e "${CYAN}🐚 4. Validation de la cohérence du .zshrc...${NC}"

ZSHRC="config/.zshrc"
if [[ -f "$ZSHRC" ]]; then
  REQUIRED_ZSHRC_KEYS=(
    "update-system"
    "ZSH_THEME="
    "SharkOS"
    "alias dir="
    "alias cls="
    "alias ipconfig="
    "alias sharkscan="
    "alias sharkfw="
    "alias sharkav="
  )

  for KEY in "${REQUIRED_ZSHRC_KEYS[@]}"; do
    if grep -q "$KEY" "$ZSHRC"; then
      show_success "Élément trouvé dans .zshrc : $KEY"
    else
      show_error "Élément MANQUANT dans .zshrc : $KEY"
    fi
  done
else
  show_error ".zshrc introuvable dans le dossier config/"
fi

# =============================================================================
# ÉTAPE 5 — Validation de la syntaxe des Scripts et Hooks
# =============================================================================
echo ""
echo -e "${CYAN}🐧 5. Analyse de syntaxe des scripts shell...${NC}"

SHELL_FILES=(
  "scripts/00-bootstrap.sh"
  "scripts/01-build-iso.sh"
  "scripts/02-flash-usb.sh"
  "chroot-hooks/10-install-tools.sh"
  "chroot-hooks/20-apply-theme.sh"
  "chroot-hooks/30-configure-shell.sh"
  "chroot-hooks/40-cleanup.sh"
)

for FILE in "${SHELL_FILES[@]}"; do
  if [[ -f "$FILE" ]]; then
    # Analyse de syntaxe avec bash -n
    if bash -n "$FILE" 2>/dev/null; then
      # Vérification shebang
      SHEBANG=$(head -n 1 "$FILE")
      if [[ "$SHEBANG" == "#!/usr/bin/env bash" || "$SHEBANG" == "#!"*"/bash" ]]; then
        show_success "$FILE — Syntaxe et Shebang OK"
      else
        show_warning "$FILE — Shebang non standard ou inattendu : $SHEBANG"
      fi
    else
      # Récupération de l'erreur
      ERR=$(bash -n "$FILE" 2>&1)
      show_error "$FILE — Erreur de syntaxe détectée :\n      $ERR"
    fi
  fi
done

# =============================================================================
# ÉTAPE 6 — Détection des Conflits de Packages (Anti-Bug de wine32)
# =============================================================================
echo ""
echo -e "${CYAN}🔍 6. Analyse des listes de paquets (Prévention des conflits d'architecture)...${NC}"

# Liste de paquets suspects qui requièrent i386 (multiarch)
BLACK_LIST=(
  "wine32"
  "wine32:i386"
  "libc6:i386"
  "libwine:i386"
)

# On vérifie si de tels paquets se sont glissés directement dans scripts/01-build-iso.sh
# à l'intérieur du bloc de génération de package-lists (PACKAGES).
# On extrait les lignes entre le heredoc 'PACKAGES' et 'PACKAGES'
BUILD_SCRIPT="scripts/01-build-iso.sh"
if [[ -f "$BUILD_SCRIPT" ]]; then
  # Extraction simplifiée : on vérifie si la ligne contient le paquet de manière non commentée
  # On exclut les lignes de commentaires commençant par #
  for PKG in "${BLACK_LIST[@]}"; do
    if grep -E "^[[:space:]]*${PKG}([[:space:]]|$)" "$BUILD_SCRIPT" &>/dev/null; then
      show_error "Le paquet multi-architecture '$PKG' est répertorié directement dans la package-list de $BUILD_SCRIPT."
      echo -e "      ${RED}👉 Erreur critique : Cela bloque l'installation au début de la build car l'architecture i386 n'est pas encore activée !${NC}"
      echo -e "      ${RED}👉 Solution : Installe-le proprement dans chroot-hooks/10-install-tools.sh après 'dpkg --add-architecture i386' et 'apt update'.${NC}"
    else
      show_success "Pas de référence directe non commentée à '$PKG' dans la package-list (OK)."
    fi
  done
fi

# =============================================================================
# RAPPORT FINAL
# =============================================================================
echo ""
echo -e "${BLUE}📊 ========================================================${NC}"
echo -e "${BLUE}   RAPPORT FINAL DU SIMULATEUR${NC}"
echo -e "${BLUE}======================================================== 🦈${NC}"
echo -e "  Nombre d'erreur(s) critique(s) : ${RED}${ERRORS}${NC}"
echo -e "  Nombre d'avertissement(s)      : ${YELLOW}${WARNINGS}${NC}"
echo ""

if [[ $ERRORS -gt 0 ]]; then
  echo -e "  ${RED}🔴 CORRECTION REQUISE : Certaines erreurs bloqueront la création de l'ISO.${NC}"
  echo -e "     Consulte les lignes ci-dessus avec la croix rouge (❌) pour les résoudre."
  exit 1
else
  echo -e "  ${GREEN}🟢 PRÊT À BUILDER : Toutes les configurations de base sont valides !${NC}"
  if [[ $WARNINGS -gt 0 ]]; then
    echo -e "     ${YELLOW}Note : Il y a des avertissements mineurs (⚠️). Tu peux les ignorer ou les résoudre si souhaité.${NC}"
  fi
  echo ""
  echo -e "  Pour créer ton ISO maintenant :"
  echo -e "    1. Prépare l'environnement de build :"
  echo -e "       ${CYAN}sudo bash scripts/00-bootstrap.sh${NC}"
  echo -e "    2. Lance la construction de l'ISO :"
  echo -e "       ${CYAN}sudo bash scripts/01-build-iso.sh${NC}"
  echo ""
fi
