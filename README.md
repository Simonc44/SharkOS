<div align="center">
  <h1>🦈 SharkOS</h1>
  <p><b>Le système ultime : design Apple, ergonomie Windows, arsenal Kali.</b></p>

  <!-- Badges -->
  <a href="https://github.com/Simonc44/SharkOS/releases/latest">
    <img src="https://img.shields.io/github/v/release/Simonc44/SharkOS?label=Dernier%20ISO%20g%C3%A9n%C3%A9r%C3%A9&color=007ec6&style=for-the-badge" alt="Dernier ISO généré">
  </a>
  <img src="https://img.shields.io/badge/Base-Debian_12_Bookworm-A80030?style=for-the-badge&logo=debian" alt="Base Debian">
  <img src="https://img.shields.io/badge/Desktop-XFCE_4-2284F2?style=for-the-badge&logo=xfce" alt="Desktop XFCE">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License MIT">
</div>

---

**SharkOS** est une distribution Live Linux sur mesure. Elle fusionne l'élégance de macOS, les raccourcis familiers de Windows et la puissance des outils de cybersécurité de Kali Linux, le tout fonctionnant de manière fluide sur une base Debian 12 minimaliste.

## ✨ Fonctionnalités clés

*   🍎 **Design Apple** : Thème WhiteSur-Dark, dock Plank translucide et barre supérieure façon macOS pour une esthétique moderne et épurée.
*   🪟 **Ergonomie Windows** : Alias ZSH intégrés pour retrouver vos réflexes Windows (`dir`, `cls`, `ipconfig`, etc.) directement dans le terminal.
*   🐉 **Arsenal Kali** : Outils de sécurité et de réseau pré-installés (Nmap, Wireshark, UFW) pour être opérationnel immédiatement.

---

## 🛠️ Identité du Système

| Paramètre | Valeur |
| :--- | :--- |
| **Base** | Debian 12 (Bookworm) minimal |
| **Environnement** | XFCE 4 |
| **Dock** | Plank |
| **Thème GTK** | WhiteSur-Dark |
| **Icônes** | WhiteSur |
| **Shell** | ZSH + Oh My Zsh (thème `agnoster`) |
| **Prompt** | `SharkOS 🦈 ~` |
| **Outils de sécurité** | `nmap`, `wireshark`, `ufw`, `gufw` |

---

## 🚀 Démarrage rapide

### 1. Prérequis
L'environnement de build nécessite un hôte sous **Debian** ou **Ubuntu**. Installez les dépendances suivantes :

```bash
sudo apt update
sudo apt install -y live-build squashfs-tools xorriso isolinux syslinux-utils git curl

```

### 2. Construction de l'ISO

Clonez ce dépôt et lancez les scripts de build séquentiellement :

```bash
# 0. Simuler et valider la configuration (Fortement recommandé)
bash scripts/simulate-build.sh

# 1. Préparer l'environnement
bash scripts/00-bootstrap.sh

# 2. Construire l'ISO (peut prendre un certain temps selon votre connexion)
sudo bash scripts/01-build-iso.sh

```

> ✅ **Succès :** L'ISO finale sera générée dans le dossier `iso-build/SharkOS.iso`.

### 3. Flasher sur USB (Optionnel)

Pour créer une clé USB bootable avec votre nouvelle ISO :

```bash
# ATTENTION : Remplacez /dev/sdX par l'identifiant réel de votre clé USB (ex: /dev/sdb)
# Utilisez la commande 'lsblk' pour identifier votre clé.
sudo bash scripts/02-flash-usb.sh /dev/sdX

```

---

## 🗂️ Structure du projet

Une architecture claire et modulaire basée sur `live-build` :

```text
SharkOS/
├── README.md                  ← Documentation du projet
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
│   └── sharkos-wall.svg       ← Fond d'écran officiel SharkOS
└── iso-build/
    └── auto/
        ├── config             ← Config principale live-build
        └── clean              ← Script de nettoyage
