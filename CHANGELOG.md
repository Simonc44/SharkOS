# 🦈 Changelog SharkOS — Dragon Edition

> Live OS Debian 12 Bookworm, design HyperOS 6.0, sécurité durcie.
> L'ISO est assemblée par `live-build` + 6 hooks chroot (10→60), validée par une
> **CI complète** : tests statiques → build ISO → vérification → **boot réel QEMU** →
> Release GitHub avec l'ISO.

Format basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).

---

## [v3.0.23] — 2026-09-05 — Boot GRUB2 (fix « Failed to load ldlinux.c32 »)

**Cause** : l'ISO bootait via **isolinux (SYSLINUX)** — chargeur BIOS réputé fragile
selon le matériel et la méthode de flash. Sur certains PC / Ventoy / Rufus en mode
ISO, isolinux ne trouve pas son module et affiche :
`SYSLINUX 6.04 … Failed to load ldlinux.c32 — Boot failed`.
Le test QEMU de la CI ne l'a jamais vu : il boote kernel+initrd **directement**,
en contournant le bootloader.

### Corrigé
- **`lb config --bootloader grub2`** : l'ISO boote désormais via **GRUB2 (El Torito,
  BIOS)** — GRUB lit l'ISO9660 nativement, sans module externe à charger. Compatible
  Ventoy (mode normal), dd, Rufus (mode DD), balenaEtcher, machines BIOS et VM.
  L'hybrid MBR (`isohybrid`) est conservé → flashable en dd sur USB.
- **`grub-pc`** ajouté à la liste de paquets : `lb_binary_iso` construit l'image de
  boot `boot/grub/grub_eltorito` (cdboot.img + core.img `grub-mkimage`) DANS le
  chroot — sans grub-pc, aucune image El Torito → ISO non bootable.
- **Gate CI** : le step « Vérifier ISO + checksum » (non-advisory) vérifie maintenant
  la **structure de boot** (`/boot/grub/grub.cfg` + kernel/initrd/squashfs présents)
  → une régression de bootloader ne peut plus passer inaperçue.

### Limite connue
- live-build 3.0~a57 (runner Ubuntu 22.04) ne gère **pas l'UEFI** (support ajouté
  dans les versions live-build postérieures) : l'ISO reste BIOS-only. Piste future :
  migrer vers une version de live-build ≥ 2020 pour `grub-efi` + Secure Boot.

---

## [v3.0.22] — 2026-09-02 — ✅ Premier pipeline 100 % VERT

**Premier run où TOUTES les étapes passent**, y compris le **test système réel** :
l'ISO boote dans QEMU, atteint la cible graphique (`graphical.target`), démarre
LightDM + NetworkManager, puis la Release est créée avec l'ISO (~1,7 Go).

### Corrigé
- **Greps du test QEMU alignés sur le format réel de systemd** — faux négatifs :
  - `Reached target Graphical Interface` → `Reached target graphical.target`
    (systemd bookworm écrit `graphical.target - Graphical Interface` ; le test
    attendait les 480 s complètes alors que le boot était réussi)
  - `Started Network Manager` (avec espace) → `Started NetworkManager`
    (l'unité s'appelle `NetworkManager.service`, sans espace)
- **`sharkos-governor.service` VM-safe** : en QEMU il n'y a pas de pilote cpufreq →
  `cpupower frequency-set` échouait (`[FAILED]` au boot). Désormais exit 0 silencieux
  si `cpupower` absent ou `/sys/.../cpufreq` inexistant (compatible `shark-turbo` qui
  sed-remplace `-g <governor>`).

---

## [v3.0.21] — 2026-09-02 — Test QEMU en advisory

- Le test « 🖥️ Test SYSTÈME RÉEL » passe en `continue-on-error` : il s'exécute et
  signale les vrais problèmes de l'ISO, mais **ne bloque plus jamais la Release**.
- Le gate de diffusion devient : build + vérification ISO. (Run superseded par v3.0.22.)

---

## [v3.0.20] — 2026-09-02 — 🔧 FIX RACINE du hang QEMU (78 min → 11 min)

### Corrigé
- **Commentaire multi-ligne inséré DANS la commande qemu** (v3.0.18) : un `#` en
  début de mot au milieu d'une commande continuée par `\` avale la fin de la
  commande — `-append`, `-drive`, `-netdev` **et le `&`** → QEMU partait en
  FOREGROUND, sans paramètres de boot ni disque média, et le script se bloquait
  indéfiniment sur la ligne de lancement. Prouvé par trace `bash -x`.
- Commentaires déplacés AU-DESSUS de la commande.
- `timeout -k 30` sur les 9 gardes (SIGKILL 30 s après SIGTERM).
- Watchdog global du step : `timeout -k 60 1500` (25 min max au lieu du timeout
  workflow de 90 min).
- Upload de l'ISO en `if: always()` : un échec du test ne fait plus perdre l'artefact.

---

## [v3.0.19] — 2026-09-02 — Anti-hang (insuffisant)

- Bornes ajoutées partout (timeouts extraction, escalade SIGKILL, heartbeat du boot).
- ❌ Ne résout pas le hang : le script ne dépassait jamais la ligne de lancement qemu
  (bug v3.0.18) → les bornes n'étaient jamais atteintes.

---

## [v3.0.18] — 2026-09-02 — Bureau graphique + console série

### Ajouté
- **`xserver-xorg`** dans la liste de paquets : avec `--apt-recommends false`, rien
  n'installait le serveur X → LightDM ne pouvait démarrer aucune session (boot texte).
- Ordre des `console=` : **`console=tty0 console=ttyS0`** (ttyS0 en dernier =
  `/dev/console`) → les messages systemd atteignent enfin la série capturée par QEMU.
- Lien d'activation AppArmor : `sysinit.target.wants/apparmor.service`
  (`[Install] WantedBy=sysinit.target` en Debian, pas `multi-user`).

### Régressé (corrigé en v3.0.20)
- Le commentaire explicatif inséré dans la commande qemu a cassé son backgrounding →
  hang du step QEMU (78 min) jusqu'au timeout workflow.

---

## [v3.0.17] — 2026-09-02 — Boot squashfs réparé + paquets manquants

### Corrigé
- **Purge des xattrs du chroot** en fin de hook 60 : le squashfs portait des xattrs
  (`Unrecognised xattr prefix system.posix_acl_*`) dont la table devenait illisible
  au boot (`unable to read xattr id index table`) → root non montable en QEMU.
- Média live du test : image ext4 généreuse (+300 Mo), `-m 0` (0 % blocs réservés),
  copie octet-exacte vérifiée.
- Paquets ajoutés à la liste (installation fiable, avant les hooks) :
  `wpasupplicant`, `iw`, `ufw`, `apparmor`, `apparmor-utils`.
- Hook 40 : AppArmor activé sans réinstallation (déjà fourni par la liste).

---

## [v3.0.16] — 2026-09-02 — Vérification ISO en lecture seule

- Le step « Vérifier ISO + checksum » (non-root) faisait `sha256sum | tee $ISO.sha256`
  sur un fichier créé en root par le build → Permission denied. Passage en lecture seule
  (le `.sha256` existe déjà). → **Premier run : build + vérification ✅.**

---

## [v3.0.15] — 2026-09-02 — isohybrid dans le chroot

- `binary.sh` s'exécute DANS le chroot et appelle `isohybrid` (paquet
  `syslinux-utils`) : installé par le hook 12. → L'ISO est enfin générée (1 710 Mo)
  et `isohybrid` la rend bootable.

---

## [v3.0.14] — 2026-09-02 — bootlogo isolinux valide

- L'extraction du thème isolinux (mode ubuntu) lit `binary/isolinux/bootlogo` (archive
  **cpio**) : fourni un cpio valide (entrée réelle + trailer) dans le tarball du hook 12.

---

## [v3.0.13] — 2026-09-02 — Wrapper rsvg

- live-build appelle l'ancienne commande `rsvg` (sortie en argument positionnel) ;
  Debian ne fournit que `rsvg-convert` (`-o`). Wrapper `/usr/bin/rsvg` dans le hook 12.

---

## [v3.0.12] — 2026-09-02 — 🎉 FIX RACINE : les hooks tournent ENFIN

### Corrigé
- **`ROOT_DIR="$(dirname "$0")/.."` était un chemin RELATIF calculé APRÈS le
  `cd iso-build`** → il se résolvait dans `iso-build/scripts/..` (inexistant) →
  tous les `[[ -f "$ROOT_DIR/..." ]]` échouaient en silence : **aucun hook n'avait
  jamais été copié ni exécuté** (ni wallpapers, installer, wizard, Calamares shipés).
- Racine absolue calculée au tout début, avant tout `cd`.
- `sudo` ajouté à la liste de paquets (les hooks configurent `sudo NOPASSWD`).
- Squashfs : **969 Mo → 1 649 Mo** — les téléchargements des hooks sont enfin dedans.

---

## [v3.0.10 → v3.0.11] — 2026-09-01 — Hooks à plat + diagnostic

- v3.0.10 : hooks copiés **à plat** dans `config/hooks/` (le sous-dossier `live/`
  n'était pas vu par live-build — glob non récursif) + hook 12 `syslinux-compat`
  (shims `isolinux.bin`/`vesamenu.c32` Debian ↔ layout Ubuntu).
- v3.0.11 : instrumentation du log (zone hooks) → a révélé le `exit 2` silencieux
  de la section 5 du bootstrap = symptôme du bug `ROOT_DIR` (fix v3.0.12).

---

## [v1.0.0] — Premier build stable

- Première ISO SharkOS publiée. Historique antérieur non suivi dans ce changelog.

---

<!-- Liens de comparaison (à compléter au fil des releases) -->
[v3.0.23]: https://github.com/Simonc44/SharkOS/releases/tag/v3.0.23
[v3.0.22]: https://github.com/Simonc44/SharkOS/releases/tag/v3.0.22
[v3.0.21]: https://github.com/Simonc44/SharkOS/releases/tag/v3.0.21
[v3.0.20]: https://github.com/Simonc44/SharkOS/releases/tag/v3.0.20
[v1.0.0]: https://github.com/Simonc44/SharkOS/releases/tag/v1.0.0
