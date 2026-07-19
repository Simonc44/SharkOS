<div align="center">
  <h1>🦈 SharkOS — Dragon Edition</h1>
  <p><b>Performance Garuda. Arsenal Kali. Élégance Dark.</b></p>

  <a href="https://github.com/Simonc44/SharkOS/releases/latest">
    <img src="https://img.shields.io/badge/Version-2.0_Dragon-e94560?style=for-the-badge" alt="Version">
  </a>
  <img src="https://img.shields.io/badge/Base-Debian_12_Bookworm-A80030?style=for-the-badge&logo=debian">
  <img src="https://img.shields.io/badge/Kernel-Liquorix_(gaming)-7B2FBE?style=for-the-badge&logo=linux">
  <img src="https://img.shields.io/badge/Desktop-XFCE_4-2284F2?style=for-the-badge&logo=xfce">
  <img src="https://img.shields.io/badge/Theme-Dracula-BD93F9?style=for-the-badge">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge">
</div>

---

**SharkOS Dragon Edition** est une distribution Linux Live inspirée de [Garuda Linux](https://garudalinux.org), construite sur Debian 12. Elle pousse la performance gaming, l'esthétique dark glassmorphism, et l'arsenal cybersécurité à leur maximum.

## ⚡ Ce qui change vs v1 : le shift Garuda

| Composant | v1 (macOS-style) | v2 Dragon Edition (Garuda-style) |
| :--- | :--- | :--- |
| **Kernel** | linux-amd64 (standard) | **linux-liquorix** (gaming/low-latency) |
| **RAM** | Swap classique | **Zram zstd** 50% RAM |
| **Thème** | WhiteSur-Dark (macOS) | **Dracula** + Papirus-Dark |
| **Shell** | ZSH + agnoster | **ZSH + Powerlevel10k** |
| **Dock** | Plank blanc | **Plank SharkDragon** (glassmorphism violet) |
| **Curseurs** | Défaut | **Catppuccin-Mocha** |
| **Compositor** | Picom léger | **Picom dual_kawase** (blur agressif) |
| **Qt** | GTK pur | **Kvantum engine** (Qt transparent) |
| **Gaming** | Wine basique | **Lutris + GameMode + MangoHud** |
| **Sécurité** | nmap, wireshark | **+ aircrack, john, hydra, sqlmap, hashcat...** |
| **Snapshots** | ✗ | **Btrfs + snapper** |
| **Compression ISO** | gzip | **zstd max** |
| **Réseau** | Standard | **BBR + FQ + sysctl tuné** |

## ✨ Fonctionnalités Dragon Edition

- 🐉 **Kernel Liquorix** : optimisé gaming/low-latency (équivalent linux-zen d'Arch)
- ⚡ **Zram zstd** : 50% de la RAM en swap compressé, swappiness=10
- 🎨 **Dracula Theme** : GTK + Kvantum + Papirus-Dark + Catppuccin curseurs
- 🎮 **Gaming Stack** : Lutris + Wine + GameMode + MangoHud (`sharkgame <jeu>`)
- 🛡️ **Arsenal Kali-grade** : 15+ outils sécu (aircrack, hydra, hashcat, sqlmap...)
- 🔵 **Picom dual_kawase** : blur glassmorphism niveau Garuda
- 📦 **Flatpak + Flathub** : apps modernes sans Snap
- 🐚 **Powerlevel10k** : prompt ultra-rapide avec icônes Nerd Font
- 📸 **Btrfs + Snapper** : snapshots auto avant chaque update
- 🌐 **BBR + FQ** : TCP congestion control dernière génération

---

## 🛠️ Identité du Système

| Paramètre | Valeur |
| :--- | :--- |
| **Base** | Debian 12 (Bookworm) |
| **Kernel** | Liquorix (gaming) / linux-amd64 (fallback) |
| **Desktop** | XFCE 4 |
| **Dock** | Plank (thème SharkDragon glassmorphism) |
| **Thème GTK** | Dracula |
| **Icônes** | Papirus-Dark |
| **Curseurs** | Catppuccin-Mocha-Dark |
| **Qt Engine** | Kvantum |
| **Shell** | ZSH + Oh My Zsh + Powerlevel10k |
| **Terminal** | XFCE4-Terminal (couleurs Dracula) |
| **RAM Swap** | Zram zstd 50% |
| **Snapshots** | Btrfs + Snapper |
| **Outils sécu** | nmap, wireshark, aircrack, john, hydra, sqlmap, hashcat... |
| **Gaming** | Lutris, Wine, GameMode, MangoHud |
| **Login** | `shark` / `shark` |

---

## 🚀 Démarrage rapide

### 1. Prérequis (hôte Debian/Ubuntu)

```bash
sudo apt update
sudo apt install -y live-build squashfs-tools xorriso isolinux \
                   syslinux-utils git curl zstd imagemagick
```

### 2. Build de l'ISO

```bash
# Simulation (recommandé avant)
bash scripts/simulate-build.sh

# Bootstrap
bash scripts/00-bootstrap.sh

# Build ISO (30-60 min)
sudo bash scripts/01-build-iso.sh
```

> ✅ ISO générée dans `iso-build/SharkOS-Dragon-Edition.iso`

### 3. Flash USB

```bash
sudo bash scripts/02-flash-usb.sh /dev/sdX
```

---

## 🎮 Gaming

```bash
# Lancer un jeu avec GameMode + MangoHud
sharkgame lutris
sharkgame wine MonJeu.exe

# Overlay FPS (MangoHud)
MANGOHUD=1 monJeu

# Installer des jeux via Flatpak
flatpak install flathub com.heroicgameslauncher.hgl
```

## 🛡️ Sécurité

```bash
# Scan réseau
shark-scan 192.168.1.0/24

# Renifler le trafic
shark-sniff

# Randomiser les MACs
shark-mac

# Snapshot Btrfs
shark-snap

# Update tout (apt + flatpak)
shark-update
```

---

## 🗂️ Structure du projet

```text
SharkOS/
├── README.md
├── scripts/
│   ├── 00-bootstrap.sh          ← Config live-build (zstd, non-free, firmware)
│   ├── 01-build-iso.sh          ← Build ISO Dragon Edition
│   ├── 02-flash-usb.sh          ← Flash USB
│   └── simulate-build.sh        ← Validation sans build réel
├── config/
│   ├── garuda-packages.list     ← Mapping Garuda → SharkOS packages
│   └── performance-tweaks.conf  ← Toutes les optimisations sysctl/kernel
├── chroot-hooks/
│   ├── 10-install-tools.sh      ← Liquorix, Zram, gaming, sécu, flatpak
│   ├── 20-apply-theme.sh        ← Dracula, Papirus-Dark, Kvantum, Catppuccin
│   ├── 30-configure-shell.sh    ← Powerlevel10k, Picom blur, Plank Dragon
│   └── 40-cleanup.sh            ← Nettoyage + services perf (ananicy, nohang)
└── wallpapers/
    └── sharkos-wall.svg         ← Fond d'écran Dragon Edition
```

---

## 📊 Comparaison Garuda vs SharkOS Dragon

| Feature | Garuda Dr460nized | SharkOS Dragon |
| :--- | :--- | :--- |
| Base | Arch Linux | Debian 12 (stable) |
| Kernel | linux-zen | Liquorix |
| Desktop | KDE Plasma | XFCE 4 |
| Dock | Latte Dock | Plank glassmorphism |
| Thème | Dracula/Catppuccin | Dracula + Kvantum |
| Shell | fish/zsh+starship | zsh+powerlevel10k |
| Compositor | KWin | Picom dual_kawase |
| Gaming | Oui | Oui |
| **Cybersécurité** | ✗ | ✅ 15+ outils |
| **ISO live** | ✗ | ✅ bootable direct |
| Stabilité | Rolling | LTS Debian |

<div align="center">
  <b>🦈 Rapide. Furtif. Létal.</b><br>
  <i>SharkOS Dragon Edition — La puissance de Garuda, la stabilité de Debian, l'arsenal de Kali.</i>
</div>
