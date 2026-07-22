<div align="center">

# 🦈 SharkOS — Dragon Edition

**Performance Garuda. Arsenal Kali. Élégance Dark.**
**Live ISO bootable, hardened, autologin. Login `shark` / `shark`.**

<a href="https://github.com/Simonc44/SharkOS/releases/latest"><img src="https://img.shields.io/badge/Version-2.0_Dragon-e94560?style=for-the-badge" alt="Version"></a>
<img src="https://img.shields.io/badge/Base-Debian_12_Bookworm-A80030?style=for-the-badge&logo=debian">
<img src="https://img.shields.io/badge/Kernel-Liquorix_(gaming)-7B2FBE?style=for-the-badge&logo=linux">
<img src="https://img.shields.io/badge/Desktop-XFCE_4-2284F2?style=for-the-badge&logo=xfce">
<img src="https://img.shields.io/badge/Theme-Dracula-BD93F9?style=for-the-badge">
<img src="https://img.shields.io/badge/Tests-passing-brightgreen?style=for-the-badge">
<img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge">

</div>

---

## 📋 Table des matières

1. [À propos](#-à-propos)
2. [TL;DR — démarrage express](#-tldr--démarrage-express)
3. [Identifiants & login](#-identifiants--login)
4. [Fonctionnalités Dragon Edition](#-fonctionnalités-dragon-edition)
5. [Commandes exclusives `shark-*`](#-commandes-exclusives-shark-) — **18 inédites**
6. [Architecture du projet](#-architecture-du-projet)
7. [Tests automatisés](#-tests-automatisés)
8. [Build complet](#-build-complet)
9. [Roadmap](#-roadmap)
10. [Crédits & inspirations](#-crédits--inspirations)

---

## 🦈 À propos

**SharkOS Dragon Edition** est une distribution Linux **Live** bootable, bâtie sur **Debian 12 Bookworm** et durcie pour la performance *gaming* et la cybersécurité. C'est un projet **100 % scripté** : aucune image binaire précompilée, tout est assemblé à la volée via `live-build` au moment du build.

* **Garuda** inspire la performance : kernel Liquorix, ZRAM zstd, BBR + FQ, picom dual-kawase.
* **Kali** inspire l'arsenal : nmap, aircrack, hydra, john, sqlmap, hashcat, wireshark…
* **Dracula** inspire l'esthétique : GTK Dracula + Papirus-Dark + Kvantum SharkDragon + Catppuccin curseurs + Powerlevel10k + Picom glassmorphism.

L'ISO générée boote **directement sur le bureau XFCE sans écran de login** (autologin shark), avec un splash Plymouth 🦈 et un menu first-boot graphique.

---

## ⚡ TL;DR — démarrage express

```bash
# 1. Valider le projet (zéro build, ~3 secondes)
bash tests/run-all.sh

# 2. Installer les dépendances host (Debian 12 / Ubuntu 22.04+)
sudo apt update && sudo apt install -y live-build squashfs-tools xorriso zstd

# 3. Bootstrap + Build (20–60 min)
sudo bash scripts/00-bootstrap.sh
sudo bash scripts/01-build-iso.sh

# 4. ISO finale
ls -lh iso-build/SharkOS-Dragon-Edition.iso

# 5. Flash USB (⚠ NE PAS LANCER sans clé cible)
sudo bash scripts/02-flash-usb.sh /dev/sdX
```

> 💡 L'ISO est aussi utilisable dans **QEMU** sans flash :
> `qemu-system-x86_64 -m 2048 -cdrom iso-build/SharkOS-Dragon-Edition.iso -boot d`

---

## 🔑 Identifiants & login

| Compte | Mot de passe | Notes |
|---|---|---|
| `shark` | `shark` | Utilisateur principal, autologin LightDM, sudo NOPASSWD |
| `root` | `shark` | sudoer via `shark`, accessible via `sudo su -` |

Renforcements côté build (hooks 10/30/50) : hash **SHA-512** avec **sel aléatoire** (8 octets), expiration désactivée, mot de passe verrou levé (`passwd -u shark`), `/etc/sudoers.d/shark` à 0440.

---

## ✨ Fonctionnalités Dragon Edition

### Boot & session

* 🦈 **Plymouth "Shark Dragon"** — splash silhouette + œil violet + spinner Dracula
* 🌫️ **GRUB Dragon theme** — fond violet/magenta + menu Dracula typographié
* 🔓 **LightDM autologin shark** — bureau direct sans écran de login
* 🎉 **Welcome wizard first-boot** — menu 8 actions (install, password, Wi-Fi, Steam, Tor…)

### Performance

* 🐉 **Kernel Liquorix** gaming/low-latency
* ⚡ **ZRAM zstd 50 % RAM**, swapiness=10
* 🌐 **BBR + FQ** TCP congestion control
* 🎚️ **Sysctl durci** (vfs_cache_pressure, inotify, rp_filter, fastopen)
* 🛡️ **Ananicy-cpp + nohang + irqbalance + thermald** activés au boot

### Sécurité

* 🛡️ **Arsenal Kali-grade** — nmap, aircrack, hydra, john, hashcat, sqlmap, gobuster, nikto, binwalk, steghide, exiftool, volatility3…
* 🛡️ **MAC randomisation automatique** à chaque boot (`sharkos-mac-randomize.service`)
* 📸 **BTRFS + snapper** — snapshots avant update
* 🦠 **ClamAV + freshclam** antivirus résident

### Gaming

* 🎮 Lutris + Wine + GameMode + MangoHud (`sharkgame <exe>`)
* 🎲 **Multiarch i386** activé pour Wine32 / Proton

### Bureau

* 🎨 **Dracula theme** (GTK + Kvantum + Papirus-Dark + Catppuccin-Mocha cursors)
* 🔵 **Picom dual_kawase** blur agressif (style Garuda Dr460nized)
* 🐚 **Powerlevel10k** prompt ultra-rapide avec icônes Nerd Font
* 🦈 **Plank SharkDragon** dock glassmorphism violet/magenta
* 🖥️ **XFCE 4 panel** custom bas + Dracula colors

### Identité OS

```ini
NAME="SharkOS"
VERSION="2.0 (Dragon Edition)"
PRETTY_NAME="SharkOS 2.0 🦈 Dragon Edition"
HOME_URL="https://github.com/Simonc44/SharkOS"
ANSI_COLOR="1;35"
```

---

## 🦈 Commandes exclusives `shark-*`

> 18 commandes introuvables dans une autre distro. Tapables directement depuis le shell.

| Commande | Description |
|---|---|
| `shark-pulse`   | Monitoring live CPU/RAM/DISK/NET avec sparkline Unicode (refresh 1 s) |
| `shark-share`   | Serveur **HTTPS + QR code** pour partager un fichier en local |
| `shark-encrypt` | Chiffrement **AES-256-CBC + PBKDF2 200k iter** → `*.enc`, original shredé |
| `shark-decrypt` | Déchiffre un `.enc` |
| `shark-tooth`   | **Shredder sécurisé** (3 passes random + zero-fill + unlink) |
| `shark-eye`     | `tcpdump` colorisé **Dracula** (TCP cyan / UDP jaune / ICMP violet) |
| `shark-quiz`    | Quiz cybersécurité interactif **10 questions + score final** |
| `shark-fortune` | Sagesse aléatoire à chaque ouverture de shell |
| `shark-link`    | Envoi fichier LAN via `nc` + **barre de progression `pv`** |
| `shark-radar`   | Boucle de scan Wi-Fi (ESSID + qualité + chiffrement) |
| `shark-vpn`     | Générateur profil **WireGuard** (`init` puis `profile <peer> <ip>`) |
| `shark-rec`     | Capture terminal → **asciinema** cast |
| `shark-tor`     | Toggle / status / check du service **Tor** |
| `shark-doctor`  | Diagnostic complet (kernel Liquorix, ZRAM, BBR, services, paquets cassés) |
| `shark-firewall`| Switch instantané profils UFW : **open** / **balanced** / **paranoid** |
| `shark-clip`    | **Presse-papiers chiffré AES-256** avec historique restreint (32 items) |
| `shark-restore` | Rollback des configs SharkOS depuis `/etc/sharkos/backups` |
| `shark-arc`     | Archiveur intelligent : `zstd > xz > gz` auto-détecté |

Toutes les commandes sont installées dans `/usr/local/bin/` par les hooks 50/60. Les alias `shark-*` sont ajoutés dans `/etc/skel/.zshrc` pour que tout nouvel utilisateur les hérite.

---

## 🗂️ Architecture du projet

```
SharkOS/
├── README.md                  ← ce fichier
├── INSTRUCTIONS.md            ← guide pas-à-pas (legacy v1)
├── scripts/
│   ├── 00-bootstrap.sh        ← Config live-build + copie les hooks (boucle)
│   ├── 01-build-iso.sh        ← Construit l'ISO (live-build + lb build)
│   ├── 02-flash-usb.sh        ← dd sur /dev/sdX (MANUEL uniquement)
│   └── simulate-build.sh      ← Validateur principal (legacy v1)

├── chroot-hooks/              ← installateurs utilisateur embarqués dans l'ISO
│   ├── 10-install-tools.sh    ← Liquorix, ZRAM, gaming, sécu, flatpak, clamav
│   ├── 20-apply-theme.sh      ← Dracula, Papirus-Dark, Kvantum, Catp
│   ├── 30-configure-shell.sh  ← Powerlevel10k, Picom, Plank, XFCE, .zshrc
│   ├── 40-cleanup.sh          ← APT cleanup, ananicy, nohang, MOTD
│   ├── 50-sharkos-finalize.sh ← 🦈 shark/shark durci, autologin, Plymouth,
│   │                             GRUB theme, welcome wizard, 13 shark-*
│   └── 60-sharkos-polish.sh   ← 🦈 5 shark-* supplémentaires + Plymouth/GRUB polish

├── config/
│   ├── .zshrc                 ← shell Powerlevel10k + alias shark-* + fortune
│   ├── plank.dconf            ← dock Plank config (Position=3, Zoom, SharkDragon)
│   ├── xfce4-panel.xml        ← panel XFCE custom bas + Dracula
│   ├── garuda-packages.list   ← mapping Garuda → SharkOS packages
│   ├── performance-tweaks.conf← sysctl/kernel tuning complet
│   ├── sharkos-setup-wizard   ← assistant first-boot graphique
│   ├── sharkos-autostart-setup← lanceur wizard
│   └── install-sharkos.desktop, sharkos-setup-wizard.desktop

├── tests/                     ← 🆕 suite de tests automatisés
│   ├── run-all.sh             ← orchestrateur principal
│   ├── test-syntax.sh         ← bash -n sur tous les .sh
│   ├── test-assets.sh         ← structure, fichiers critiques, exe bits
│   ├── test-configs.sh        ← XML, plank, .zshrc completeness
│   ├── test-hooks.sh          ← cohérence chroot ↔ bootstrap ↔ simulate
│   └── test-aliases.sh        ← couverture alias shark-* canoniques

├── wallpapers/                ← PNG uniquement (SVG interdit)
└── iso-build/                 ← sortie live-build (ISO finale ici)
```

**Ordre d'exécution des hooks** (par 00-bootstrap.sh) :
`10-install-tools.sh → 20-apply-theme.sh → 30-configure-shell.sh → 40-cleanup.sh → 50-sharkos-finalize.sh → 60-sharkos-polish.sh`

---

## 🧪 Tests automatisés

```bash
# Suite complète : 5 tests en moins de 5 secondes
bash tests/run-all.sh
```

| Test | Vérifie | Sortie illustrative |
|---|---|---|
| `test-syntax.sh`  | `bash -n` sur tous les `.sh`         | `OK: chroot-hooks/60-sharkos-polish.sh ✓` |
| `test-assets.sh`  | présence fichiers critiques, exe bit | `✓ file config/.zshrc` |
| `test-configs.sh` | XML XFCE + plank.dconf + .zshrc keys | `✓ Position=3, ✓ zoom`, 13 alias shark-* |
| `test-hooks.sh`   | chaque hook est référencé par bootstrap ET simulate | cohérence disque ↔ scripts |
| `test-aliases.sh` | couverture des 18 alias canoniques    | `Coverage : 18/18` |

Les tests ne **construisent pas** l'ISO — ils vérifient la cohérence statique du repo. Idéal comme hook pre-commit ou check CI.

---

## 🛠️ Build complet

### Prérequis host (Debian 12 / Ubuntu 22.04+)

```bash
sudo apt update
sudo apt install -y live-build squashfs-tools xorriso isolinux \
                   syslinux-utils syslinux-common genisoimage \
                   git curl wget ca-certificates debootstrap rsync \
                   dconf-cli imagemagick zstd
```

### Étapes

```bash
# 1. Valider
bash tests/run-all.sh
bash scripts/simulate-build.sh

# 2. Bootstrap (prépare iso-build/)
sudo bash scripts/00-bootstrap.sh

# 3. Build ISO (20–60 min selon réseau)
sudo bash scripts/01-build-iso.sh
# → produit : iso-build/SharkOS-Dragon-Edition.iso (+ .sha256)

# 4. Logs en cours
tail -f /tmp/sharkos-build.log

# 5. Tester en VM
qemu-system-x86_64 -m 2048 -cdrom iso-build/SharkOS-Dragon-Edition.iso -boot d

# 6. Flasher (⚠ MANUEL — vérifier /dev/sdX avec `lsblk`)
sudo bash scripts/02-flash-usb.sh /dev/sdX
```

---

## 🧭 Roadmap

| Statut | Étape | Détail |
|---|---|---|
| ✅ | **v2.0 Dragon** | Liquorix + ZRAM + BBR + Dracula + 18 shark-* |
| ✅ | Tests automatisés | `tests/run-all.sh` |
| ✅ | LightDM autologin  | bureau direct |
| ✅ | Plymouth + GRUB     | branding utilisateur |
| 🚧 | v2.1 Hydra          | iwd + NetworkManager GUI custom + multi-langue à l'install |
| 🚧 | v3.0 Apex           | Wayland (Wayfire + wf-panel-pi) + Calamares installer dans l'ISO |
| 💭 | À étudie           | intégration Flatpak Steam/Discord automatisée au first-boot |

---



## 🛠️ Installation depuis la session Live (Calamares + sharkos-installer)

Depuis le menu Welcome au premier boot (ou depuis un terminal) :
- **Calamares** (si inclus) : `sudo shark-thin` ou clic sur "Installer sur disque" → interface graphique 13 modules Debian.
- **sharkos-installer** (inclus en permanence : `/usr/local/bin/sharkos-installer`) :
  ```bash
  sudo sharkos-installer /dev/sda            # interactive (root ou nom utilisateur shark)
  sudo sharkos-installer /dev/nvme0n1 --yes --filesystem btrfs --reboot
  sudo sharkos-installer /dev/sdc --hostname shark-lab --username shark --password shark
  ```

Phases :
1. **Validation disque** (affichage taille/modèle, double confirmation "OUI")
2. **Partitionnement GPT** (EFI 260 MiB + root ext4 ou btrfs)
3. **Formatage** (vfat + ext4/btrfs selon choix)
4. **debootstrap bookworm** (base Debian minimale)
5. **Bind-mounts + rsync du repo** dans /tmp/sharkos-build
6. **Cycle des hooks 10→60** dans le chroot (`sharkos-install-cycle.sh`)
7. **GRUB install UEFI + BIOS** (fallback legacy)
8. **Identifiants shark/shark** + `sudo NOPASSWD`
9. **fstab UUID** + reboot optionnel

## ⚙️ CI/CD (`.github/workflows/`)

| Workflow | Trigger | Durée | Sortie |
|---|---|---|---|
| `ci.yml` | push/PR main | ~3 min | status ✅/❌ — lint, structure, hooks Debian, configs |
| `build-iso.yml` *(nouveau)* | push tag `v*` | ~40 min | ISO `SharkOS-Dragon-Edition.iso` + `.sha256` artifact, GitHub Release |

Déclencher un build ISO depuis l'UI GitHub Actions : onglet Actions → "Run workflow" → cocher `full_build`.

## 📝 `tests/run-all.sh`

```
🦈 Test syntax — bash -n sur tous les scripts .sh
🦈 Test assets — fichiers critiques du projet
🦈 Test configs — XML, plank, .zshrc
🦈 Test hooks — cohérence chroot ↔ bootstrap ↔ simulate
🦈 Test aliases — couverture shark-* canoniques
🦈 Test installer — présence scripts/sharkos-installer + cycle + intégration Calamares
```

Chaque test rapporte PASS/FAIL avec code couleur. La suite complète tourne en <5 s sans sudo.

## 🔐 Sécurité & éthique

SharkOS embarque des outils offensifs `aircrack-ng`, `hydra`, `john`, etc. **à but éducatif** uniquement. L'utilisateur est responsable du respect des lois locales. Activez les profils UFW systématiquement avec `shark-firewall paranoid` sur les machines de production.

## 🛡️ Crédits & inspirations

* [Garuda Linux](https://garudalinux.org) — performance & sysctl tuning
* [Xubuntu](https://xubuntu.org) — XFCE defaults
* [Dracula Theme](https://draculatheme.com) — palette
* [Vinceliuice](https://github.com/vinceliuice) — WhiteSur-Dark GTK & icons
* [Catppuccin](https://github.com/catppuccin/cursors) — curseurs
* [live-build](https://wiki.debian.org/DebianLive) — le socle Debian

## 📜 Licence

MIT — voir [LICENSE](LICENSE) (à ajouter au repo).

---

<div align="center">

**

## 🛡️ Live USB — Verified bootable

L'ISO SharkOS est générée avec `--binary-images iso-hybrid` (live-build) +
compression zstd + El Torito BIOS/EFI catalog, ce qui la rend immédiatement
flashable en USB bootable (MBR pour BIOS legacy, GPT pour UEFI).

### ✅ Verify yourself
```bash
# Après le build (en local sur host Debian/Ubuntu)
bash scripts/03-verify-iso.sh                          # 4 checks indépendants
# Sortie typique (toutes vertes) :
#  ✓ SHA256 vérifié
#  ✓ Hybrid MBR détecté (USB-flashable)
#  ✓ El Torito catalog présent (2 boot images : BIOS+EFI)
#  ✓ kernel / initrd / squashfs trouvés
#  🦈 ISO OK pour Live USB
```

### 🚀 Flash sur USB
```bash
# 1. Identifier la clé (NE PAS SE TROMPER — /dev/sda peut être le disque système!)
lsblk
# 2. Démonter toutes les partitions de la clé
sudo umount /dev/sdX* 2>/dev/null
# 3. Flasher (double-confirmation "OUI" demandée par le script)
sudo bash scripts/02-flash-usb.sh /dev/sdX
# 4. Synchroniser
sync
# 5. Retirer la clé, brancher sur la machine cible, booter, sélectionner la clé dans le BIOS
```

### 🧪 Tester sans flash via QEMU
```bash
# KVM accéléré (Linux host avec virtualisation activée)
qemu-system-x86_64 -m 4096 -smp 4 -enable-kvm \
  -cdrom iso-build/SharkOS-Dragon-Edition.iso -boot d

# Sans KVM (cross-platform, plus lent)
qemu-system-x86_64 -m 2048 \
  -cdrom iso-build/SharkOS-Dragon-Edition.iso -boot d
```

> 💡 Tu peux QEMU-boot *avant* de flasher pour vérifier que l'ISO démarre
> proprement (boot logo, autologin shark sur XFCE Dragon Edition).



## 🏷️ CI déclenchée par tag (`build-iso.yml`)

Pour déclencher une build ISO complète en GitHub Actions et publier un
release public :

```bash
git tag -a v2.0.1 -m "SharkOS Dragon Edition v2.0.1"
git push origin v2.0.1
# → onglet Actions : "Build SharkOS Dragon Edition ISO" tourne ~40 min
# → artifact téléchargeable : SharkOS-Dragon-Edition.iso + .sha256
# → GitHub Release créé automatiquement avec l'ISO attaché
```

> Le trigger est `tags: ['v*.*', 'v*']`. Le workflow passe d'abord
> `bash tests/run-all.sh` puis build via Docker Debian Bookworm, puis
> publie ISO + SHA256 sur la release.



## 🦈 Calamares UI (Dracula polish)

L'installateur graphique Calamares est livré avec un branding Dracula
complet : palette `#0d0221` / `#e94560` / `#bd93f9` sur **tous** les
widgets Qt, intro HTML, sidebar dynamique, logo multi-tailles (16/32/64/128/256/512).

Fichiers livrés (dans `config/calamares/`) :
- `settings.conf` — séquence des 13 modules Debian Calamares
- `branding/sharkos.qss` — stylesheet Dracula (~150 lignes)
- `branding/sharkos.desc` — métadonnées du branding
- `branding/intro.html` — splash de bienvenue
- `branding/sidebar.html` — panneau latéral live avec step counter
- `branding/sharkos-logo-{16,32,64,128,256,512}.png` — logos multi-tailles
- `branding/calamares-splash.png` — image 1920×1080
- `modules/sharkos-install-cycle.conf` — module custom qui relance hooks 10→60

Ces fichiers sont installés par `chroot-hooks/60-sharkos-polish.sh` dans
`/etc/calamares/sharkos/` lors du build ISO, puis actifs quand l'utilisateur
lance `calamares-sharkos-thick` depuis le menu Welcome ou `shark-thin` depuis
n'importe quel terminal.

🦈 Rapide. Furtif. Létal.**
*i* Performance Garuda. Stabilité Debian. Arsenal Kali. Élégance Dark.

</div>
