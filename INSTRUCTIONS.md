# 🦈 SharkOS — Guide de construction complet

## Ce fichier explique comment construire ton ISO SharkOS sur une machine Linux.
## ⚠️ Tu as besoin d'un PC ou VM sous Debian 12 / Ubuntu 22.04+ pour builder.

---

## ÉTAPE 0 — Préparer tes assets (à faire sur Windows AVANT de transférer)

Place ces fichiers dans le dossier `wallpapers/` :

```
wallpapers/
├── wallpaper.png   ← Fond d'écran principal (recommandé : 1920x1080)
└── logo.png        ← Logo SharkOS (recommandé : 512x512, fond transparent)
```

> ❌ Ne pas utiliser de fichiers .svg — SharkOS n'en a pas besoin.
> ✅ PNG uniquement pour compatibilité maximale avec LightDM, XFCE, GRUB.

---

## ÉTAPE 1 — Transférer le projet sur Linux

Copie le dossier `SharkOS/` sur ta machine Linux (USB, SCP, etc.) :

```bash
# Exemple depuis Windows via WSL ou SCP :
scp -r "C:\Users\admin\Documents\SharkOS" user@linux-machine:/home/user/SharkOS
```

---

## ÉTAPE 2 — Installer les dépendances (sur Linux)

```bash
sudo apt update
sudo apt install -y \
  live-build squashfs-tools xorriso isolinux \
  syslinux-utils syslinux-common genisoimage \
  git curl wget ca-certificates debootstrap rsync dconf-cli
```

---

## ÉTAPE 2.5 — Valider ta configuration (Recommandé)

Avant de lancer la build, tu peux simuler et valider l'intégrité de tes fichiers de configuration :

```bash
cd ~/SharkOS
bash scripts/simulate-build.sh
```

## ÉTAPE 3 — Lancer le bootstrap

```bash
cd ~/SharkOS
sudo bash scripts/00-bootstrap.sh
```

Ce script :
- Vérifie les dépendances
- Crée la structure `iso-build/`
- Copie les hooks, configs, wallpapers PNG

---

## ÉTAPE 4 — Construire l'ISO

```bash
sudo bash scripts/01-build-iso.sh
```

Durée estimée : **20 à 45 minutes** selon ta connexion internet.

Pendant la build, surveille les logs :
```bash
# Dans un autre terminal :
tail -f ~/SharkOS/sharkos-build.log
```

L'ISO finale sera dans : `~/SharkOS/SharkOS.iso`

---

## ÉTAPE 5 — Tester l'ISO (QEMU, sans clé USB)

```bash
# Test rapide avec 2 Go de RAM :
qemu-system-x86_64 -m 2048 -cdrom ~/SharkOS/SharkOS.iso -boot d -vga std

# Ou avec VirtualBox : Fichier → Nouvelle VM → ISO bootable
```

---

## ÉTAPE 6 — Flasher sur clé USB

```bash
# Remplace /dev/sdb par ta clé USB (vérifie avec : lsblk)
sudo bash scripts/02-flash-usb.sh /dev/sdb
```

---

## Ce qui est inclus dans SharkOS

| Composant           | Source officielle                                      |
|---------------------|--------------------------------------------------------|
| Base système        | Debian 12 Bookworm (minimal)                          |
| Desktop             | XFCE 4 + Plank dock                                   |
| Paramètres défaut   | github.com/Xubuntu/xubuntu-default-settings           |
| Thème GTK           | WhiteSur-Dark (github.com/vinceliuice/WhiteSur-gtk-theme) |
| Icônes              | WhiteSur (github.com/vinceliuice/WhiteSur-icon-theme) |
| Shell               | ZSH + Oh My Zsh (thème agnoster) + prompt 🦈          |
| Sécurité            | nmap, wireshark, ufw, gufw, macchanger                |
| Antivirus           | ClamAV (léger, à la demande)                          |
| Snap                | snapcraft.io — Discord, Spotify, VSCode en 1 clic     |
| Flatpak             | Flathub                                               |
| Compat. Windows     | Wine + Winetricks + Lutris + sharkrun                 |
| Anonymat réseau     | Macchanger auto à chaque boot + reconnexion Wi-Fi     |
| Thèmes Snap/Flatpak | WhiteSur propagé dans ~/.themes et ~/.icons            |

---

## Commandes clés dans le terminal SharkOS

```zsh
update-system        # Met à jour TOUT : APT + Snap + Flatpak + ClamAV + ZSH
sharkscan <ip>       # Scan réseau nmap
sharkfw              # Statut pare-feu UFW
sharkav <dossier>    # Scan antivirus ClamAV
sharkmac             # Randomise tes adresses MAC maintenant
sharkrun fichier.exe # Lance un .exe Windows avec Wine
sharkip              # Affiche ton IP publique
sharkinfo            # Affiche les infos système (neofetch)

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
├── INSTRUCTIONS.md          ← Ce fichier
├── SharkOS.iso              ← Généré après la build
├── sharkos-build.log        ← Log de la build
├── wallpapers/
│   ├── wallpaper.png        ← TON fond d'écran (1920x1080 PNG)
│   └── logo.png             ← TON logo (512x512 PNG)
├── config/
│   ├── .zshrc               ← Shell complet avec tous les aliases
│   ├── plank.dconf          ← Config dock Plank
│   └── xfce4-panel.xml      ← Barre supérieure XFCE
├── scripts/
│   ├── 00-bootstrap.sh      ← Prépare l'environnement
│   ├── 01-build-iso.sh      ← Construit l'ISO
│   └── 02-flash-usb.sh      ← Flash sur USB
└── chroot-hooks/
    ├── 10-install-tools.sh  ← ZSH, sécu, Snap, ClamAV, Proton, Macchanger
    ├── 20-apply-theme.sh    ← WhiteSur GTK + Icons + propagation Snap/Flatpak
    ├── 30-configure-shell.sh ← XFCE, Plank, LightDM, identité OS
    └── 40-cleanup.sh        ← Nettoyage post-install (OS léger et propre)
```
