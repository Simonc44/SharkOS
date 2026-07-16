# 🐉 SharkOS — Inventaire des outils de sécurité

> Tous les outils installés dans SharkOS, classés par catégorie.
> Inspiré de Kali Linux, allégé pour une ISO live de ~1.8 GB.

---

## 🔍 Reconnaissance & OSINT

| Outil | Description | Commande exemple |
|-------|-------------|------------------|
| `nmap` | Scanner de ports + détection OS/services | `nmap -sV -O -A <ip>` |
| `masscan` | Scanner ultra-rapide (millions de ports/sec) | `masscan -p80,443 <cible>/24` |
| `dnsenum` | Énumération DNS complète | `dnsenum <domaine>` |
| `dnsrecon` | Reconnaissance DNS avancée | `dnsrecon -d <domaine>` |
| `theHarvester` | OSINT emails, sous-domaines, IPs | `theHarvester -d <domaine> -b google` |
| `recon-ng` | Framework OSINT modulaire | `recon-ng` |
| `whois` | Informations WHOIS d'un domaine/IP | `whois <domaine>` |
| `dnsutils` | `nslookup`, `dig`, `host` | `dig <domaine> ANY` |
| `netdiscover` | Découverte d'hôtes sur le réseau local | `netdiscover -r 192.168.1.0/24` |
| `arp-scan` | Scan ARP rapide du réseau local | `arp-scan --localnet` |
| `exiftool` | Extraction de métadonnées de fichiers | `exiftool <fichier>` |
| `maltego` | GUI OSINT graphe de relations (Snap) | `snap install maltego` |

---

## 🌐 Tests Web

| Outil | Description | Commande exemple |
|-------|-------------|------------------|
| `sqlmap` | Injection SQL automatisée | `sqlmap -u "http://cible/?id=1" --dbs` |
| `nikto` | Scanner de vulnérabilités web | `nikto -h http://cible` |
| `gobuster` | Bruteforce de répertoires/sous-domaines | `gobuster dir -u http://cible -w /usr/share/wordlists/dirb/common.txt` |
| `dirb` | Bruteforce de répertoires web | `dirb http://cible` |
| `wfuzz` | Fuzzer web multi-usage | `wfuzz -c -z file,wordlist.txt http://cible/FUZZ` |
| `whatweb` | Détection de technologies web | `whatweb http://cible` |
| `curl` | Client HTTP en ligne de commande | `curl -I http://cible` |
| `httpie` | Client HTTP convivial | `http GET http://cible` |
| `burpsuite` | Proxy/scanner web interactif (Snap) | `snap install burpsuite-community-edition` |
| `zaproxy` | OWASP ZAP — scanner web open source | `snap install zaproxy` |

---

## 📡 Réseau & Interception

| Outil | Description | Commande exemple |
|-------|-------------|------------------|
| `wireshark` | Capture et analyse de paquets (GUI) | `wireshark` |
| `tcpdump` | Capture de paquets en CLI | `tcpdump -i eth0 -w capture.pcap` |
| `netcat` | Le couteau suisse réseau | `nc -lvnp 4444` |
| `hping3` | Génération de paquets TCP/UDP/ICMP | `hping3 -S -p 80 <ip>` |
| `bettercap` | Framework MitM réseau moderne | `bettercap -iface eth0` |
| `ettercap` | Attaques MitM classiques | `ettercap -G` |
| `arpwatch` | Surveillance des changements ARP | `arpwatch -i eth0` |
| `mitmproxy` | Proxy MitM HTTP/HTTPS interactif | `mitmproxy` |
| `ngrep` | Grep sur le trafic réseau | `ngrep -d eth0 'password'` |
| `socat` | Tunnel réseau avancé | `socat TCP-LISTEN:8080,fork TCP:cible:80` |

---

## 💥 Exploitation

| Outil | Description | Commande exemple |
|-------|-------------|------------------|
| `metasploit-framework` | Framework d'exploitation complet | `msfconsole` |
| `exploitdb` | Base locale des exploits (Exploit-DB) | `searchsploit apache 2.4` |
| `searchsploit` | Recherche dans la DB ExploitDB | `searchsploit <CVE>` |
| `beef-xss` | Framework XSS + contrôle de navigateurs | `beef-xss` |

---

## 🔑 Mots de passe & Cracking

| Outil | Description | Commande exemple |
|-------|-------------|------------------|
| `hydra` | Brute-force de services réseau | `hydra -l admin -P wordlist.txt ssh://cible` |
| `john` | John the Ripper — cracking de hashes | `john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt` |
| `hashcat` | Cracking GPU-accéléré | `hashcat -m 0 hash.txt wordlist.txt` |
| `medusa` | Brute-force parallèle | `medusa -h cible -u admin -P pass.txt -M ssh` |
| `crunch` | Générateur de wordlists | `crunch 8 8 abcdef -o wordlist.txt` |
| `cewl` | Génère une wordlist depuis un site web | `cewl http://cible -w wordlist.txt` |
| `hashid` | Identification de type de hash | `hashid <hash>` |
| `ophcrack` | Cracking de hash Windows (LM/NTLM) | `ophcrack` |

---

## 📶 Wi-Fi & Réseau sans fil

| Outil | Description | Commande exemple |
|-------|-------------|------------------|
| `aircrack-ng` | Suite complète d'audit Wi-Fi | `aircrack-ng -w wordlist cap.cap` |
| `airmon-ng` | Activation du mode moniteur | `airmon-ng start wlan0` |
| `airodump-ng` | Capture de paquets Wi-Fi | `airodump-ng wlan0mon` |
| `aireplay-ng` | Injection de paquets Wi-Fi | `aireplay-ng -0 5 -a <BSSID> wlan0mon` |
| `wifite` | Attaque Wi-Fi automatisée | `wifite` |
| `reaver` | Attaque WPS brute-force | `reaver -i wlan0mon -b <BSSID>` |
| `macchanger` | Randomisation adresse MAC | `macchanger -r wlan0` / `sharkmac` |

---

## 🔬 Forensics & Analyse

| Outil | Description | Commande exemple |
|-------|-------------|------------------|
| `binwalk` | Analyse et extraction de firmwares | `binwalk -e firmware.bin` |
| `foremost` | Récupération de fichiers supprimés | `foremost -i disk.img -o output/` |
| `volatility3` | Analyse de mémoire RAM | `vol -f memory.dmp windows.info` |
| `bulk-extractor` | Extraction de données dans fichiers/images | `bulk_extractor -o out/ disk.img` |
| `exiftool` | Métadonnées de tous types de fichiers | `exiftool photo.jpg` |
| `scalpel` | Carving de fichiers | `scalpel disk.img -o output/` |
| `autopsy` | GUI forensics complète | `autopsy` (Flatpak) |
| `dc3dd` | dd forensique avec logging | `dc3dd if=/dev/sdb of=disk.img` |

---

## 🔄 Reverse Engineering

| Outil | Description | Commande exemple |
|-------|-------------|------------------|
| `gdb` | Debugger GNU | `gdb ./binary` |
| `radare2` | Désassembleur/décompilateur | `r2 -A ./binary` |
| `ltrace` | Trace les appels aux bibliothèques | `ltrace ./binary` |
| `strace` | Trace les appels système | `strace ./binary` |
| `strings` | Extrait les chaînes d'un binaire | `strings binary \| grep -i pass` |
| `objdump` | Désassemblage et infos ELF | `objdump -d binary` |
| `file` | Identifie le type de fichier | `file binary` |
| `hexdump` | Vue hexadécimale | `hexdump -C binary \| head` |

---

## 🕵️ Anonymat & Vie privée

| Outil | Description | Commande exemple |
|-------|-------------|------------------|
| `macchanger` | Randomisation MAC (automatique au boot) | `sharkmac` |
| `tor` | Réseau d'anonymisation | `tor` + `proxychains4 curl https://check.torproject.org` |
| `proxychains4` | Redirection du trafic via proxies/tor | `proxychains4 nmap <ip>` |
| `i2p` | Réseau anonyme alternatif | `i2prouter start` |

---

## 🛡️ Défense & Hardening

| Outil | Description | Commande exemple |
|-------|-------------|------------------|
| `ufw` | Pare-feu simplifié | `sharkfw` / `ufw status` |
| `gufw` | Interface graphique UFW | `gufw` |
| `clamav` | Antivirus open source | `sharkav <dossier>` |
| `clamtk` | Interface graphique ClamAV | `clamtk` |
| `fail2ban` | Protection brute-force automatique | `fail2ban-client status` |
| `rkhunter` | Détection de rootkits | `rkhunter --check` |

---

## 📋 Wordlists

```bash
# Rockyou (fourni avec Kali, à télécharger sur SharkOS) :
sudo apt install wordlists
ls /usr/share/wordlists/
# rockyou.txt.gz — à décompresser : gunzip /usr/share/wordlists/rockyou.txt.gz

# SecLists (recommandé) :
git clone --depth 1 https://github.com/danielmiessler/SecLists /usr/share/seclists
```

---

## 🔧 Utilitaires système

| Outil | Description |
|-------|-------------|
| `neofetch` | Infos système jolies (`sharkinfo`) |
| `htop` | Gestionnaire de processus interactif |
| `inxi` | Infos hardware complètes |
| `net-tools` | `ifconfig`, `netstat`, `route` |
| `dconf-cli` | Configuration XFCE/GNOME en CLI |
| `imagemagick` | Manipulation d'images en CLI |
| `gdebi-core` | Installateur de .deb avec dépendances |

---

*Liste maintenue par la communauté SharkOS — PR les bienvenues !*
