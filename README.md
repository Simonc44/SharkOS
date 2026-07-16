# 🦈 SharkOS

<div align="center">

**Design Apple · Ergonomie Windows · Arsenal Kali Linux**

[![Build](https://github.com/Simonc44/SharkOS/actions/workflows/ci.yml/badge.svg)](https://github.com/Simonc44/SharkOS/actions/workflows/ci.yml)
[![Base](https://img.shields.io/badge/Base-Debian%2012%20Bookworm-red?logo=debian)](https://www.debian.org/)
[![Desktop](https://img.shields.io/badge/Desktop-XFCE%204-blue?logo=xfce)](https://xfce.org/)
[![Shell](https://img.shields.io/badge/Shell-ZSH%20%2B%20Oh%20My%20Zsh-green?logo=gnu-bash)](https://ohmyz.sh/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![ISO Size](https://img.shields.io/badge/ISO-~1.8%20GB-orange?logo=linux)]()

> Un OS live léger et opérationnel en moins de 2 Go. Interface épurée façon macOS, raccourcis Windows, et l'arsenal offensif de Kali — tout-en-un.

</div>

---

## ✨ Ce que SharkOS apporte

| Pilier | Ce que tu obtiens |
|--------|-------------------|
| 🍎 **Design Apple** | Thème WhiteSur-Dark, dock Plank, barre supérieure façon macOS, icônes WhiteSur |
| 🪟 **Ergonomie Windows** | `dir`, `cls`, `ipconfig`, `tracert`, `md`, `tasklist` — tes réflexes fonctionnent |
| 🐉 **Arsenal Kali** | nmap, wireshark, aircrack-ng, metasploit-framework, hydra, john, sqlmap, burpsuite, nikto, gobuster + 30 autres |
| 🔒 **Furtivité** | Randomisation MAC automatique à chaque boot et reconnexion Wi-Fi (macchanger) |
| 🍷 **Compatibilité .exe** | Wine + Winetricks + Lutris + Proton-GE + `sharkrun fichier.exe` |
| 📦 **Apps modernes** | Snap + Flatpak pré-configurés (Discord, Spotify, VSCode en 1 commande) |
| 🛡️ **Antivirus** | ClamAV (scan à la demande, léger, non-bloquant) |

---

## 📸 Aperçu

```
🦈 SharkOS   rapide · furtif · létal
─────────────────────────────────────
OS     : SharkOS 1.0 (Debian 12)
Kernel : Linux 6.1 x86_64
Shell  : zsh + oh-my-zsh (agnoster)
DE     : XFCE 4.18 + Plank
Thème  : WhiteSur-Dark
Icônes : WhiteSur
RAM    : 512 MB / 8192 MB
Disk   : Live USB (persistance optionnelle)
```

---

## 🗂️ Structure du projet

```
SharkOS/
├── README.md                   ← Ce fichier
├── INSTRUCTIONS.md             ← Guide de build complet étape par étape
├── KALI-TOOLS.md               ← Inventaire de tous les outils de sécurité inclus
├── scripts/
│   ├── 00-bootstrap.sh         ← Prépare l'environnement live-build
│   ├── 01-build-iso.sh         ← Lance la construction de l'ISO (~1.8 GB)
│   ├── 02-flash-usb.sh         ← Flash l'ISO sur une clé USB
│   └── simulate-build.sh       ← Valide la config avant build (recommandé)
├── chroot-hooks/
│   ├── 10-install-tools.sh     ← Kali tools, ZSH, Wine, Snap, ClamAV, macchanger
│   ├── 20-apply-theme.sh       ← WhiteSur GTK + icônes (look Apple)
│   ├── 30-configure-shell.sh   ← XFCE, Plank, LightDM, identité OS
│   └── 40-cleanup.sh           ← Nettoyage agressif → ISO légère
├── config/
│   ├── .zshrc                  ← ZSH complet : aliases Windows + prompt SharkOS
│   ├── plank.dconf             ← Dock Plank façon macOS
│   └── xfce4-panel.xml         ← Barre supérieure XFCE style menubar Apple
├── wallpapers/
│   ├── wallpaper.png           ← Fond d'écran principal (1920×1080)
│   └── logo.png                ← Logo SharkOS (512×512, fond transparent)
└── .github/
    └── workflows/
        └── ci.yml              ← CI : validation de la config live-build
```

---

## ⚡ Démarrage rapide

### Prérequis

> Machine hôte : **Debian 12** ou **Ubuntu 22.04+** (physique ou VM).

```bash
sudo apt update && sudo apt install -y \
  live-build squashfs-tools xorriso isolinux \
  syslinux-utils syslinux-common genisoimage \
  git curl wget ca-certificates debootstrap rsync dconf-cli
```

### Build en 3 commandes

```bash
# 1. Valider la configuration (fortement recommandé)
bash scripts/simulate-build.sh

# 2. Préparer l'environnement
sudo bash scripts/00-bootstrap.sh

# 3. Builder l'ISO (~20-45 min selon connexion)
sudo bash scripts/01-build-iso.sh

# ✅ L'ISO est dans : SharkOS.iso
```

### Tester sans clé USB

```bash
qemu-system-x86_64 -m 2048 -cdrom SharkOS.iso -boot d -vga std
```

### Flasher sur USB

```bash
# Vérifie d'abord ta clé avec : lsblk
sudo bash scripts/02-flash-usb.sh /dev/sdX
```

---

## 🐚 Commandes SharkOS

### 🔴 Sécurité & Réseau

```zsh
sharkscan <ip>         # Scan nmap complet (-sV -O -A)
sharkfw                # Statut UFW + règles actives
sharkav <dossier>      # Scan ClamAV
sharkmac               # Randomise toutes les MACs maintenant
sharkip                # IP publique + infos GeoIP
```

### 🍷 Compatibilité Windows

```zsh
sharkrun fichier.exe   # Lance un .exe avec Wine
dir                    # → ls -la
cls                    # → clear
ipconfig               # → ip a
tracert <host>         # → traceroute
tasklist               # → ps aux
md <dossier>           # → mkdir -p
```

### 🛠️ Système

```zsh
update-system          # MAJ complète : APT + Snap + Flatpak + ClamAV + OMZ
sharkinfo              # neofetch SharkOS
```

---

## 🐉 Outils de sécurité inclus

Voir **[KALI-TOOLS.md](KALI-TOOLS.md)** pour l'inventaire complet.

| Catégorie | Outils |
|-----------|--------|
| Reconnaissance | nmap, masscan, dnsenum, theHarvester, recon-ng, whois, dnsutils |
| Web | sqlmap, nikto, gobuster, dirb, wfuzz, whatweb, curl, httpie |
| Réseau | wireshark, tcpdump, netcat, hping3, arpwatch, bettercap, ettercap |
| Exploitation | metasploit-framework, exploitdb, searchsploit |
| Passwords | hydra, john, hashcat, crunch, cewl, medusa |
| Wi-Fi | aircrack-ng, airmon-ng, aireplay-ng, wifite, reaver |
| Forensics | binwalk, foremost, volatility3, bulk-extractor, exiftool |
| Anonymat | macchanger, tor, proxychains4, i2p |
| Reverse | gdb, radare2, ltrace, strace, strings |

---

## 🖥️ Identité système

| Paramètre | Valeur |
|-----------|--------|
| Base | Debian 12 Bookworm (minimal) |
| Taille ISO | ~1.8 GB |
| Desktop | XFCE 4 + Plank dock |
| Thème GTK | WhiteSur-Dark (look macOS) |
| Icônes | WhiteSur |
| Shell | ZSH + Oh My Zsh (agnoster) |
| Prompt | `SharkOS 🦈 ~` |
| Utilisateur live | `shark` / mdp : `shark` |
| Compatibilité | x86_64 — BIOS & UEFI |
| Persistance | Optionnelle (clé USB avec partition data) |

---

## 🚧 Roadmap

- [ ] **Persistance USB** automatique à la création
- [ ] **Installateur graphique** (Calamares) pour installation sur disque
- [ ] **Mode stealth** (services réduits, pas de NetworkManager — Wi-Fi manuel)
- [ ] **GUI Kali-like** pour lancer les outils sécu sans terminal
- [ ] **Build GitHub Actions** qui produit l'ISO en artifact téléchargeable
- [ ] **Dark mode** complet XFCE (panel, gestionnaire de fichiers)
- [ ] **arm64** support (Raspberry Pi 4/5)

---

## 🤝 Contribuer

Les PR sont les bienvenues ! Quelques idées :

- Ajouter des outils Kali dans `10-install-tools.sh`
- Améliorer le thème ou le dock dans `20-apply-theme.sh`
- Créer des wallpapers SharkOS dans `wallpapers/`
- Tester la build et reporter les bugs

---

## 📄 Licence

MIT — Simon © 2025

---

<div align="center">

**🦈 Rapide. Furtif. Létal.**

</div>
