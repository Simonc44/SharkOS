# 🦈 SharkOS — Guide de construction complet

## Ce fichier explique comment construire ton ISO SharkOS sur une machine Linux.
## ⚠️ Tu as besoin d'un PC ou VM sous Debian 12 / Ubuntu 22.04+ pour builder.

---

## ÉTAPE 0 — Préparer tes assets (à faire sur Windows AVANT de transférer)

Place ces fichiers dans le dossier `wallpapers/` (les deux conventions de nom sont acceptées) :

```
wallpapers/
├── sharkos-wall.png     ← Fond d'écran principal (recommandé : 1920x1080)
├── sharkos-logo.png     ← Logo SharkOS (recommandé : 512x512, fond transparent)
└── (v1 : wallpaper.png / logo.png — encore acceptés par simulate-build)
```

> ❌ Ne pas utiliser de fichiers .svg — SharkOS n'en a pas besoin.
> ✅ PNG uniquement pour compatibilité maximale avec LightDM, XFCE, GRUB.
>
> Si les assets sont absents, la build génère automatiquement un fond et un
> logo de secours avec ImageMagick (aucun plantage).

---

## ÉTAPE 1 — Valider la configuration (Recommandé)

Avant toute build, lance la suite de tests **et** le validateur de config :

```bash
cd ~/SharkOS
bash tests/run-all.sh          # suite de tests automatisée (10 tests, dont SKIP si pas d'ISO)
bash scripts/simulate-build.sh # valide l'intégrité des configs + assets

# Après avoir construit l'ISO — TEST SUR SYSTÈME RÉEL (boot QEMU, Calamares, Wi-Fi) :
#   prérequis : apt install qemu-system-x86 e2fsprogs squashfs-tools xorriso
sudo bash tests/test-boot.sh iso-build/SharkOS-Dragon-Edition.iso
```

---

## ÉTAPE 2 — Installer les dépendances build (sur Linux)

```bash
sudo apt update
sudo apt install -y \
  live-build squashfs-tools xorriso isolinux \
  syslinux-utils syslinux-common genisoimage \
  git curl wget ca-certificates debootstrap rsync \
  zstd imagemagick python3 rsync
```

---

## ÉTAPE 3 — Lancer le bootstrap

```bash
cd ~/SharkOS
sudo bash scripts/00-bootstrap.sh
```

Ce script :
- Vérifie/installe les dépendances build
- Crée la structure `iso-build/` (live-build)
- Écrit la config live-build (bookworm, zstd, non-free-firmware, fr_FR)
- Génère la liste de paquets (XFCE, LightDM, fonts, firmware, etc.)
- Copie les **6 hooks chroot** + le wallpaper/logo PNG
- Embarque le **kit d'installation réel** dans l'ISO (`includes.chroot`) :
  - `sharkos-installer` + `sharkos-install-cycle.sh` + `sharkos-verify-iso`
  - le bundle **Calamares** complet (`config/calamares/` → `/etc/calamares/sharkos/`)

---

## ÉTAPE 4 — Construire l'ISO

```bash
sudo bash scripts/01-build-iso.sh
```

Durée estimée : **20 à 60 minutes** selon ta connexion internet.

Pendant la build, surveille les logs :
```bash
tail -f /tmp/sharkos-build.log
```

L'ISO finale sera dans : `iso-build/SharkOS-Dragon-Edition.iso` (+ `.sha256`)

---

## ÉTAPE 5 — Vérifier l'ISO construite

```bash
# Contrôles indépendants (ISO, boot UEFI/BIOS, squashfs, kernel) :
sudo bash scripts/03-verify-iso.sh iso-build/SharkOS-Dragon-Edition.iso
```

---

## ÉTAPE 6 — Tester l'ISO (QEMU, sans clé USB)

```bash
# Test rapide avec 2 Go de RAM :
qemu-system-x86_64 -m 2048 -cdrom iso-build/SharkOS-Dragon-Edition.iso -boot d -vga std

# Ou avec VirtualBox : Fichier → Nouvelle VM → ISO bootable
```

> Au premier boot : autologin `shark` / `shark` → bureau XFCE direct + menu Welcome.

---

## ÉTAPE 7 — Flasher sur clé USB

```bash
# Remplace /dev/sdX par ta clé USB (vérifie avec : lsblk)
sudo bash scripts/02-flash-usb.sh /dev/sdX
```

---

## Ce qui est inclus dans SharkOS

| Composant           | Détail                                                       |
|---------------------|--------------------------------------------------------------|
| Base système        | Debian 12 Bookworm (live-build, iso-hybrid, compression zstd)|
| Desktop             | XFCE 4 + Plank dock + LightDM autologin `shark`/`shark`      |
| Thème               | Dracula : WhiteSur-Dark GTK + Papirus icons + Kvantum         |
| Shell               | ZSH + Oh My Zsh + Powerlevel10k + 25 alias `shark-*`         |
| Sécurité            | nmap, wireshark, ufw, gufw, macchanger, ClamAV, john, hydra… |
| Gaming              | Wine + Winetricks + Lutris + GameMode + MangoHud + sharkgame  |
| Paquets apps        | Flatpak + Flathub (pas de Snap par défaut)                   |
| Perf                | Zram (50% RAM zstd), BBR TCP, sysctl tuning, nohang, thermald|
| Installateur        | Calamares (bundle Dracula) + sharkos-installer fallback       |
| Anonymat            | Macchanger auto à chaque boot + shark-tor (Tor on/off)        |
| Apps incluses       | firefox-esr, thunderbird, gimp, vlc, libreoffice, geany…      |

---

## Commandes clés dans le terminal SharkOS (25 alias `shark-*`)

```zsh
shark-update        # Met à jour TOUT : APT + Flatpak + ClamAV
shark-scan <ip>     # Scan réseau nmap
shark-firewall      # Switch UFW open/balanced/paranoid
shark-av            # Scan antivirus ClamAV
shark-mac           # Randomise les adresses MAC maintenant
shark-game <cmd>    # Lance une commande avec GameMode + MangoHud
shark-info          # Infos système (neofetch/fastfetch)
shark-pulse         # Live CPU/RAM/DISK/NET
shark-eye           # tcpdump Dracula-highlighted
shark-tor {on|off}  # Service Tor toggle
shark-encrypt/.shark-decrypt  # chiffrement AES-256 de fichiers
shark-clip          # presse-papiers chiffré
shark-arc           # archiveur zstd/xz/gz auto-détecté
shark-restore       # rollback configs depuis snapshots
shark-doctor        # diagnostic complet du système
shark-turbo         # mode performance instantané type HyperOS (on/off/status)
# + shark-share, shark-link, shark-radar, shark-fortune, shark-quiz,
#   shark-vpn, shark-tooth, shark-sniff, shark-rec, shark-deploy

# Aliases Windows natifs :
dir                  # ls -la
cls                  # clear
ipconfig             # ip a
tracert              # traceroute
tasklist             # ps aux
md dossier           # mkdir -p dossier
```

---

## Structure du projet

```
SharkOS/
├── README.md
├── INSTRUCTIONS.md           ← Ce fichier
├── iso-build/                ← Dossier live-build (créé par 00-bootstrap.sh)
│   └── SharkOS-Dragon-Edition.iso   ← ISO générée par 01-build-iso.sh
├── wallpapers/
│   ├── sharkos-wall.png      ← Fond d'écran (1920x1080 PNG)
│   └── sharkos-logo.png      ← Logo (512x512 PNG)
├── config/
│   ├── .zshrc                ← Shell complet avec 25 alias shark-*
│   ├── plank.dconf           ← Config dock Plank (position bas, zoom)
│   ├── xfce4-panel.xml       ← Barre supérieure XFCE
│   ├── performance-tweaks.conf / garuda-packages.list
│   ├── calamares/            ← Bundle installateur (settings, modules, branding Dracula)
│   └── sharkos-setup-wizard  ← Assistant first-boot (Python/GTK)
├── scripts/
│   ├── 00-bootstrap.sh       ← Prépare l'environnement + embarque le kit
│   ├── 01-build-iso.sh       ← Construit l'ISO
│   ├── 02-flash-usb.sh       ← Flash sur USB (⚠ confirmation OUI)
│   ├── 03-verify-iso.sh      ← Vérifie l'ISO (4 checks indépendants)
│   ├── sharkos-installer     ← Installateur en dur (debootstrap + hooks)
│   ├── sharkos-install-cycle.sh ← Rejoue les hooks 10→60 dans la cible
│   └── simulate-build.sh     ← Validateur de config (0 erreur attendu)
└── chroot-hooks/             ← 6 hooks exécutés dans le chroot, dans l'ordre :
    ├── 10-install-tools.sh   ← ZSH, sécu, gaming, Flatpak, ClamAV, Btrfs
    ├── 20-apply-theme.sh     ← WhiteSur Dracula + Papirus + Kvantum
    ├── 30-configure-shell.sh ← XFCE, Plank, LightDM, compte shark
    ├── 40-cleanup.sh         ← Nettoyage + services perf (irqbalance…)
    ├── 50-sharkos-finalize.sh← Identifiants durcis, autologin, Plymouth, shark-*
    └── 60-sharkos-polish.sh  ← shark-doctor/firewall/clip + Calamares polish

tests/                        ← Suite automatisée (bash tests/run-all.sh)
  test-boot.sh                 ← TEST SYSTÈME RÉEL : boot QEMU + Calamares + Wi-Fi (SKIP sans ISO)
```