# 🦈 SharkOS — Build System

> Le système ultime : design Apple, ergonomie Windows, arsenal Kali.

## Structure du projet

```
SharkOS/
├── README.md                  ← Ce fichier
├── scripts/
│   ├── 00-bootstrap.sh        ← Prépare l'environnement live-build
│   ├── 01-build-iso.sh        ← Lance la construction de l'ISO
│   └── 02-flash-usb.sh        ← Flash l'ISO sur une clé USB
├── config/
│   ├── .zshrc                 ← Shell ZSH avec alias Windows + prompt SharkOS
│   ├── plank.dconf            ← Configuration du dock Plank
│   └── xfce4-panel.xml        ← Barre du haut XFCE style macOS
├── chroot-hooks/
│   ├── 10-install-tools.sh    ← Installe les outils de sécurité + ZSH
│   ├── 20-apply-theme.sh      ← Installe WhiteSur GTK + icons
│   └── 30-configure-shell.sh  ← Configure ZSH, prompt, aliases
├── wallpapers/
│   └── sharkos-wall.svg       ← Fond d'écran SharkOS
└── iso-build/
    └── auto/
        ├── config             ← Config principale live-build
        └── clean              ← Script de nettoyage
```

## Prérequis (sur un hôte Debian/Ubuntu)

```bash
sudo apt update
sudo apt install -y live-build squashfs-tools xorriso isolinux syslinux-utils git curl
```

## Construction de l'ISO

```bash
# 1. Préparer l'environnement
bash scripts/00-bootstrap.sh

# 2. Construire l'ISO
bash scripts/01-build-iso.sh

# L'ISO finale sera dans : iso-build/SharkOS.iso
```

## Flash USB (optionnel)

```bash
# Remplacer /dev/sdX par votre clé USB
bash scripts/02-flash-usb.sh /dev/sdX
```

## Identité du système

| Paramètre      | Valeur                        |
|----------------|-------------------------------|
| Base           | Debian 12 (Bookworm) minimal  |
| Desktop        | XFCE 4                        |
| Dock           | Plank                         |
| Thème GTK      | WhiteSur-Dark                 |
| Icônes         | WhiteSur                      |
| Shell          | ZSH + Oh My Zsh (agnoster)    |
| Prompt         | `SharkOS 🦈 ~`               |
| Outils sécu    | nmap, wireshark, ufw, gufw    |
