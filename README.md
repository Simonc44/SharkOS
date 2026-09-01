<div align="center">

# 🦈 SharkOS — Dragon Edition

### Live OS Debian/XPCE **au design HyperOS 6.0**

*La même philosophie visuelle que **Xiaomi HyperOS** — glassmorphism, police MiSans, coins ultra-arrondis, widgets vivants, animations fluides — appliquée à un système Linux durci & performant.*

[![Version](https://img.shields.io/badge/Version-3.0_Dragon-2563eb?style=for-the-badge)](https://github.com/Simonc44/SharkOS/releases/latest)
[![Base](https://img.shields.io/badge/Base-Debian_12_Bookworm-A80030?style=for-the-badge&logo=debian)](https://www.debian.org)
[![Kernel](https://img.shields.io/badge/Kernel-XanMod_LTS-7B2FBE?style=for-the-badge&logo=linux)](https://xanmod.org)
[![Desktop](https://img.shields.io/badge/Desktop-XFCE_4-22A7F0?style=for-the-badge&logo=xfce)](https://xfce.org)
[![Design](https://img.shields.io/badge/Design-HyperOS_6.0-2563eb?style=for-the-badge)](https://hyperos.mi.com)
[![Tests](https://img.shields.io/badge/Tests-10_suites-passing?style=for-the-badge&color=22C55E)](https://github.com/Simonc44/SharkOS/actions)
[![ISO](https://img.shields.io/badge/ISO-%3C_2_Go-22C55E?style=for-the-badge)](https://github.com/Simonc44/SharkOS/releases)

**Live ISO bootable · autologin `shark`/`shark` · sécurité durcie · ISO < 2 Go**

</div>

---

## 📋 Table des matières

1. [À propos](#-à-propos)
2. [🎨 Design HyperOS 6.0 — le cœur du projet](#-design-hyperos-60--le-cœur-du-projet)
3. [Fonctionnalités](#-fonctionnalités)
4. [Commandes exclusives `shark-*`](#-commandes-exclusives-shark-)
5. [Architecture du projet](#-architecture-du-projet)
6. [Tests automatisés](#-tests-automatisés)
7. [Build complet](#-build-complet)
8. [Installation sur disque](#-installation-sur-disque)
9. [CI / CD](#-ci--cd)
10. [Roadmap](#-roadmap)
11. [Sécurité & éthique](#-sécurité--éthique)
12. [Crédits & inspirations](#-crédits--inspirations)

---

## 🦈 À propos

**SharkOS Dragon Edition** est une distribution Linux **Live** qui réunit trois ambitions dans une seule ISO :

1. **🎨 L'esthétique HyperOS de Xiaomi** — le système reprend le language de design d'HyperOS 6.0 : glassmorphism, police officielle MiSans, coins très arrondis, dégradés vibrants, widgets vivants sur le bureau et animations fluides (voir la section dédiée ci-dessous).
2. **⚡ La performance** — kernel **XanMod LTS** (réduit la latence, gaming), ZRAM compressé zstd, BBR congestion control, mode CPU turbo instantané.
3. **🛡️ La sécurité** — pare-feu UFW actif par défaut, AppArmor, kernel durci, sysctl anti-exploitation, Firefox privatisé.

Le projet est **100 % scripté** : aucun binaire précompilé dans le repo. L'ISO est assemblée à la volée par `live-build` à partir de Debian 12 Bookworm, avec 6 hooks chroot (10→60) qui installent, configurent et polissent le système.

---

## 🎨 Design HyperOS 6.0 — le cœur du projet

> **Le choix de conception central de SharkOS : reproduire l'expérience visuelle d'HyperOS (le système de Xiaomi) sur un desktop Linux.**

SharkOS ne se contente pas d'appliquer un thème : il réplique les **principes de design signatures d'HyperOS 6.0**, éléments par élément.

### Le comparatif — SharkOS vs HyperOS 6.0

| Élément HyperOS 6.0 | Équivalent SharkOS | Détail |
|---|---|---|
| 🔤 **Police MiSans** (celle d'HyperOS) | ✅ **MiSans** (Regular / Medium / Bold) | Police officielle Xiaomi, téléchargée au build, appliquée partout : GTK, xsettings, fenêtres, GRUB |
| 🪟 **Glassmorphism** (verre dépoli) | ✅ **Blur `dual_kawase` renforcé** | Flou d'arrière-plan + panneaux translucides → effet verre dépoli sur windows/panels/dock |
| ⭕ **Coins très arrondis** | ✅ **20 px** (picom) | La signature visuelle d'HyperOS : panneaux et fenêtres aux angles généreux |
| 🌈 **Dégradés vibrants** | ✅ **Fond pastel bleu→violet + halos lumineux** | Dégradé `#e0eaff → #e9d5ff` avec halos cyan/rose composés en *Screen* — profondeur lumineuse type MIUI |
| 🎛️ **Interface lumineuse & claire** | ✅ **Thème clair** | WhiteSur-Light + icônes Papirus-Light + curseurs Catppuccin-Latte (opposé du dark Dracula, gardé en fallback) |
| 📱 **Barre de notification translucide en haut** | ✅ **Panel XFCE blanc translucide** | rgba blanc 42 %, arrondi 14 px |
| 🖱️ **Dock avec magnification** | ✅ **Plank glass clair, zoom 150 %** | Icônes qui grossissent au survol, dock en verre blanc |
| 🗂️ **Drawer d'apps au toucher (Super)** | ✅ **Launcher instantané sur la touche Super** | rofi en verre blanc, coins 16 px, sélection bleue `#2563eb`, recherche fuzzy |
| 🕒 **Widgets vivants** (horloge, météo, stats) | ✅ **Widgets conky glassmorphism** | Horloge géante MiSans, CPU/RAM avec processus, disque avec barre, réseau (↓/↑ + IP), batterie |
| 🎬 **Animations fluides** | ✅ **XFWM4 animé + Compiz optionnel** | Aperçu Alt+Tab, zoom desktop, transitions de workspace — et `shark-anim on` pour le **cube 3D / scale / wobble** |
| 🖥️ **Boot animé** | ✅ **Plymouth + GRUB pastel** | Splash au démarrage, menu GRUB sur fond dégradé clair avec panneau de sélection glass arrondi en police MiSans |
| ⚡ **Mode performance** | ✅ **`shark-turbo on`** | Bascule instantanée du CPU en mode *performance* pour un ressenti « tout est fluide, tout est rapide » |

### Pourquoi ce choix ?

HyperOS a popularisé une identité visuelle qui se caractérise par la **douceur** : des transitions soyeuses, un verre dépoli omniprésent, des formes très arrondies et une police claire et moderne (MiSans). SharkOS transpose ces principes sur XFCE — un environnement léger et rapide — pour obtenir un bureau qui *se sent* fluide et premium au quotidien, exactement dans l'esprit d'un téléphone Xiaomi haut de gamme.

---

## ✨ Fonctionnalités

### Boot & session

* 🦈 **Plymouth « Shark Dragon »** — splash au démarrage
* 🌫️ **GRUB theme clair HyperOS** — dégradé pastel, panneau glass arrondi, police MiSans
* 🔓 **LightDM autologin `shark`** — bureau direct, aucune saisie de mot de passe
* 🎉 **Wizard de premier boot** — assistant graphique (clavier, création de compte) au style liquid glass

### 📦 ISO légère (< 2 Go)

* ⚖️ **ISO ≈ 1,3–1,5 Go** (squashfs zstd) — la cible des 2 Go est respectée
* 🎮 **Gaming (Wine + Lutris ≈ 1,8 Go) en option** → `shark-extras gaming`
* 📄 **LibreOffice ≈ 800 Mo en option** → `shark-extras office` · ✉️ **Thunderbird** → `shark-extras mail`
* 💡 Tout s'installe à la demande en 1 commande, sans rebuild

### ⚡ Performance

* 🐉 **Kernel XanMod LTS** — gaming / low-latency (BBRv3, MGLRU, sched_ext)
* 💾 **ZRAM zstd 50 % RAM**, `vm.swappiness=10`
* 🚀 **Governor `schedutil`** au boot + **`shark-turbo`** pour basculer en performance instantanée
* 🖥️ **Picom GLX** + `unredir-if-possible` → +FPS en plein écran
* ⚙️ `sched_autogroup` + dirty writeback → moins d'à-coups multi-applications
* 🛡️ ananicy-cpp, nohang, irqbalance, thermald actifs au boot

### 🛡️ Sécurité

* 🔥 **UFW actif par défaut** — deny entrant, allow sortant, profils `open`/`balanced`/`paranoid`
* 🛡️ **AppArmor** — confinement applicatif + profils Debian enforce
* 🧠 **Boot durci** : `mitigations=on`, `page_poison=1`, `slab_nomerge`, `audit=1`
* 🔒 **Sysctl anti-exploitation** : `dmesg_restrict`, `kptr_restrict=2`, `ptrace_scope=2`, `tcp_syncookies`, anti-spoof martians
* 🚫 Core dumps bloqués, services risqués désactivés (avahi, cups, rpcbind, modemmanager…)
* 🌐 **Firefox durci** : anti-tracking/fingerprinting, DoH, télémétrie off, HTTPS-only
* 🛠️ **Outils Kali-grade** : nmap, aircrack-ng, hydra, john, hashcat, sqlmap, gobuster, nikto, binwalk…
* 📸 **BTRFS + snapper** — snapshots avant mise à jour · 🦠 **ClamAV** antivirus résident

---

## 🦈 Commandes exclusives `shark-*`

> **20 commandes** introuvables ailleurs — installées dans `/usr/local/bin/` et aliasées dans `.zshrc` pour tous les utilisateurs.

| Commande | Description |
|---|---|
| `shark-turbo on/off` | Mode CPU **performance instantané** (ressenti HyperOS) |
| `shark-anim on/off` | Bascule animations **Compiz** (cube 3D, scale, wobble) ↔ picom léger |
| `shark-extras <gaming\|office\|mail\|all>` | Installe les gros paquets optionnels (ISO < 2 Go) |
| `shark-pulse` | Monitoring live CPU/RAM/DISK/NET avec sparklines |
| `shark-share` | Serveur HTTPS + QR code pour partager un fichier |
| `shark-encrypt` / `shark-decrypt` | Chiffrement **AES-256-CBC + PBKDF2 200k itérations** |
| `shark-tooth` | Shredder sécurisé (3 passes random + zero-fill) |
| `shark-eye` | `tcpdump` colorisé |
| `shark-quiz` | Quiz cybersécurité (10 questions) |
| `shark-link` | Envoi de fichier LAN via `nc` + barre `pv` |
| `shark-radar` | Scan Wi-Fi (ESSID, qualité, chiffrement) |
| `shark-vpn` | Générateur de profils WireGuard |
| `shark-rec` | Capture de session (asciinema) |
| `shark-tor` | Toggle / status Tor |
| `shark-doctor` | Diagnostic complet (kernel, ZRAM, BBR, services…) |
| `shark-firewall` | Switch de profils UFW |
| `shark-clip` | Presse-papiers chiffré AES-256 (historique 32 items) |
| `shark-restore` | Rollback des configs |
| `shark-arc` | Archiveur intelligent (zstd → xz → gz) |
| `shark-fortune` | Citation aléatoire au lancement du shell |

---

## 🗂️ Architecture du projet

```
SharkOS/
├── scripts/
│   ├── 00-bootstrap.sh        ← Configure live-build + copie hooks & kit install
│   ├── 01-build-iso.sh        ← Construit l'ISO (lb build, log /tmp/sharkos-build.log)
│   ├── 02-flash-usb.sh        ← Flash USB (dd, double confirmation OUI)
│   ├── 03-verify-iso.sh       ← Vérifie l'ISO (SHA256, MBR, El Torito, squashfs)
│   ├── simulate-build.sh      ← Validateur statique des configs
│   └── sharkos-installer      ← Installateur sur disque (GPT, debootstrap, hooks)
├── chroot-hooks/              ← Exécutés dans le chroot lors du build
│   ├── 10-install-tools.sh    ← XanMod, ZRAM, governor, sécu, outils, MiSans
│   ├── 20-apply-theme.sh      ← Thème clair HyperOS, fond pastel, icônes
│   ├── 30-configure-shell.sh  ← Picom/UI, panel, dock, rofi, widgets, login
│   ├── 40-cleanup.sh          ← Nettoyage, UFW, AppArmor, MOTD, services
│   ├── 50-sharkos-finalize.sh ← Identifiants, autologin, GRUB, shark-* (x6)
│   └── 60-sharkos-polish.sh   ← shark-* restants, Calamares bundle
├── config/                    ← Configs embarquées (polices, panels, sysctl…)
├── tests/                     ← 10 suites de tests automatisés
├── wallpapers/                ← PNG uniquement
└── iso-build/                 ← Sortie live-build (l'ISO finale vit ici)
```

**Ordre des hooks** : `10 → 20 → 30 → 40 → 50 → 60` — chaque étape prépare la suivante, de l'installation brute jusqu'au polish final.

---

## 🧪 Tests automatisés

```bash
# Suite complète (tests statiques rapides)
bash tests/run-all.sh
```

| Test | Vérifie |
|---|---|
| `test-syntax.sh` | `bash -n` sur tous les scripts |
| `test-assets.sh` | Fichiers critiques + bits exécutables |
| `test-configs.sh` | Configs XML/plank/.zshrc + design HyperOS + sécurité |
| `test-hooks.sh` | Cohérence hooks ↔ bootstrap ↔ simulate |
| `test-aliases.sh` | Couverture des 20 alias `shark-*` |
| `test-installer.sh` | Kit d'installation + bundle Calamares |
| `test-live-usb.sh` | ISO hybride + script de flash + vérification |
| `test-login.sh` | Chaîne login : `shark`/`shark`, PAM, autologin |
| `test-wizard.sh` | Wizard Python (syntaxe, autologin, validation) |
| `test-boot.sh` 🖥️ | **Test sur système réel** — voir ci-dessous |

### 🖥️ Test sur système réel (`test-boot.sh`)

Le seul test qui valide le **vrai artefact** : il boote l'ISO construite dans **QEMU** et vérifie réellement le kernel, `Reached target Graphical Interface`, LightDM, **l'autologin `shark`**, NetworkManager, puis inspecte le contenu du squashfs (bundle Calamares, installer, firmware Wi-Fi, UFW, AppArmor, MiSans). Lancé **automatiquement en CI après chaque build**.

```bash
sudo bash tests/test-boot.sh iso-build/SharkOS-Dragon-Edition.iso
# prérequis : qemu-system-x86 e2fsprogs squashfs-tools xorriso
```

Sans ISO → statut `SKIP` (la suite reste verte).

---

## 🛠️ Build complet

### Prérequis (Debian 12 / Ubuntu 22.04+)

```bash
sudo apt install -y live-build squashfs-tools xorriso isolinux \
  syslinux-utils syslinux-common genisoimage debootstrap \
  git curl wget ca-certificates rsync imagemagick zstd
```

### Étapes

```bash
# 1. Valider
bash tests/run-all.sh

# 2. Bootstrap (prépare iso-build/) — ~1 min
sudo bash scripts/00-bootstrap.sh

# 3. Build ISO — 20-60 min selon le réseau
sudo bash scripts/01-build-iso.sh
# → iso-build/SharkOS-Dragon-Edition.iso (+ .sha256)

# 4. Tester en VM
qemu-system-x86_64 -m 2048 -cdrom iso-build/SharkOS-Dragon-Edition.iso -boot d

# 5. Vérifier puis flasher
sudo bash scripts/03-verify-iso.sh
sudo bash scripts/02-flash-usb.sh /dev/sdX   # ⚠ vérifier /dev/sdX avec lsblk
```

---

## 📀 Installation sur disque

Depuis la session Live, le menu Welcome ou un terminal :

```bash
# Assistant graphique (recommandé) — clavier, compte, autologin
sudo sharkos-setup-wizard

# Installateur CLI avancé
sudo sharkos-installer /dev/sda                          # interactif
sudo sharkos-installer /dev/nvme0n1 --yes --filesystem btrfs --reboot
```

**Phases** : validation disque → partitionnement GPT (EFI 260 MiB + root) → formatage → `debootstrap` bookworm → cycle des hooks 10→60 dans le chroot → GRUB UEFI+BIOS → identifiants `shark`/`shark` → reboot.

---

## ⚙️ CI / CD

| Workflow | Trigger | Rôle |
|---|---|---|
| `ci.yml` | push / PR sur `main` | Lint ShellCheck, structure, features, hooks Debian, configs |
| `build-iso.yml` | push tag `v*` | Build complet + **test QEMU réel** + upload ISO/SHA256 + GitHub Release |

```bash
git tag v3.0.5 && git push origin v3.0.5   # déclenche le build
```

---

## 🧭 Roadmap

| Statut | Étape | Détail |
|---|---|---|
| ✅ | v3.0 | Design HyperOS 6.0, ISO < 2 Go, sécurité durcie, test QEMU réel |
| 🚧 | v3.1 | iwd + gestionnaire réseau graphique custom |
| 🚧 | v4.0 | Wayland (Wayfire + wf-panel-pi), Calamares dans l'ISO |
| 💭 | — | Flatpak Steam/Discord automatisé au premier boot |

---

## 🔐 Sécurité & éthique

SharkOS embarque des outils offensifs (`aircrack-ng`, `hydra`, `john`…) **à but éducatif** uniquement — l'utilisateur reste responsable du respect des lois locales. En production, activez systématiquement les profils UFW via `shark-firewall paranoid`.

---

## 🛡️ Crédits & inspirations

* 🎨 **[Xiaomi HyperOS](https://hyperos.mi.com)** — design system : glassmorphism, MiSans, coins arrondis, widgets, animations
* [Garuda Linux](https://garudalinux.org) — performance & tuning sysctl
* [Xubuntu](https://xubuntu.org) — fondations XFCE
* [Dracula Theme](https://draculatheme.com) — palette (fallback) · [Catppuccin](https://catppuccin.com) — curseurs
* [Vinceliuice](https://github.com/vinceliuice) — WhiteSur-Light GTK & icônes
* [live-build](https://wiki.debian.org/DebianLive) — le socle Debian

> ℹ️ *HyperOS et MiSans sont des marques de Xiaomi. SharkOS est un projet indépendant, non affilié à Xiaomi : il s'inspire du language de design public d'HyperOS.*

## 📜 Licence

MIT — voir `LICENSE`.