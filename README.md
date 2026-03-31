# CyberForge : Laboratoire de Cybersécurité

**Auteur :** KAOUANE WALID
**Durée :** 10 jours
**Thème :** Simulation Red Team / Blue Team en environnement Windows/Active Directory isolé

---

## Présentation du projet

CyberForge est un laboratoire virtuel personnel conçu pour simuler des scénarios d'intrusion et de réponse réalistes dans un environnement Windows/Active Directory isolé. Le projet démontre des capacités de cybersécurité offensives (Red Team) et défensives (Blue Team).

Ce laboratoire a été réalisé en 10 jours dans le but d'acquérir une expérience pratique avec des outils SOC (Security Operations Center) standards de l'industrie, couvrant la détection des menaces, la réponse automatisée aux incidents et la remédiation des logiciels malveillants.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│               Réseau du laboratoire CyberForge          │
│                                                         │
│  ┌──────────────┐        ┌──────────────────────────┐  │
│  │  Kali Linux  │──────▶ │  Windows Server (AD)     │  │
│  │  (Attaquant) │        │  + Agent Wazuh           │  │
│  └──────────────┘        └──────────────┬───────────┘  │
│                                          │              │
│  ┌──────────────┐        ┌──────────────▼───────────┐  │
│  │   Suricata   │◀───────│  Trafic réseau           │  │
│  │   (IDS)      │        └──────────────────────────┘  │
│  └──────┬───────┘                                       │
│         │                                               │
│  ┌──────▼───────────────────────────────────────────┐  │
│  │         Gestionnaire Wazuh (SIEM/EDR)            │  │
│  │   - Agrégation et corrélation des alertes        │  │
│  │   - Réponse active automatisée                   │  │
│  │   - Intégration VirusTotal                       │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Outils utilisés

| Outil | Rôle | Description |
|-------|------|-------------|
| **Wazuh** | SIEM / EDR | Plateforme open-source de détection des menaces, surveillance d'intégrité et réponse aux incidents |
| **Suricata** | IDS Réseau | Analyse du trafic réseau en temps réel et détection d'intrusions |
| **VirusTotal** | Analyse de malwares | Analyse cloud intégrée à Wazuh FIM |
| **Kali Linux** | Simulation d'attaques | Outils offensifs (Nmap, Hydra) pour les scénarios Red Team |
| **Windows AD** | Infrastructure cible | Contrôleur de domaine Active Directory surveillé |

---

## Les trois scénarios

### Scénario 1 — Détection de la reconnaissance réseau

**Objectif :** Détecter et alerter sur les activités de balayage réseau
**Outil d'attaque :** Nmap (depuis Kali Linux)
**Détection :** Suricata IDS + Wazuh

**Déroulement :**
1. L'attaquant lance un scan SYN Nmap depuis Kali Linux vers le réseau cible
2. Suricata analyse le trafic en temps réel et identifie les signatures de scan (règles ET SCAN)
3. Suricata génère une alerte et l'écrit dans `eve.json`
4. Wazuh ingère le fichier et corrèle les alertes
5. Le tableau de bord Wazuh affiche l'alerte avec les métadonnées complètes des paquets

**Résultat :** Scans SYN/ACK et phases de cartographie réseau détectés en **moins de 5 secondes**.
**MITRE ATT&CK :** T1046 — Network Service Discovery

---

### Scénario 2 — Défense contre le brute force RDP

**Objectif :** Bloquer automatiquement les IP effectuant des attaques par force brute sur RDP
**Outil d'attaque :** Hydra (depuis Kali Linux)
**Détection & Réponse :** Règle Wazuh 60204 → Réponse active → Blocage netsh

**Déroulement :**
1. L'attaquant lance Hydra depuis Kali Linux pour effectuer un brute force RDP
2. Windows enregistre les échecs d'authentification (Event ID 4625, LogonType 10)
3. L'agent Wazuh transmet les événements au gestionnaire
4. La règle 60204 se déclenche après plusieurs échecs consécutifs
5. Wazuh exécute le script `block-ip.cmd`
6. La commande `netsh` bloque l'IP source pendant 600 secondes
7. La règle est automatiquement supprimée après expiration

**Commande de blocage :**
```batch
netsh advfirewall firewall add rule name="WAZUH_BLOCK_[IP]" ^
    protocol=any dir=in action=block remoteip=[IP_ATTAQUANT]
```

**Résultat :** IP bloquée automatiquement en **moins de 3 secondes** pendant 10 minutes.
**MITRE ATT&CK :** T1110.001 — Password Guessing

---

### Scénario 3 — Détection et suppression de malware

**Objectif :** Détecter, analyser et supprimer automatiquement les fichiers malveillants
**Fichier de test :** Fichier de test antivirus standard EICAR
**Détection :** Wazuh FIM + API VirusTotal + Exécutable Windows personnalisé

**Déroulement :**
1. Un fichier EICAR est déposé dans un répertoire surveillé (`C:\Users\Public\Downloads`)
2. Wazuh FIM détecte le nouveau fichier en temps réel
3. Le hash SHA256 est soumis automatiquement à l'API VirusTotal
4. VirusTotal retourne un verdict malveillant (60+/72 moteurs)
5. Wazuh déclenche la réponse active avec `delete_malware.exe`
6. L'exécutable supprime le fichier et journalise l'action

**Résultat :** Détecté par plus de 60 moteurs antivirus sur 72. Suppression automatique en **moins de 10 secondes**.
**MITRE ATT&CK :** T1204 — User Execution: Malicious File

---

## Récapitulatif des résultats

| Scénario | Attaque détectée | Réponse automatisée | Temps de réponse |
|----------|------------------|---------------------|-----------------|
| Reconnaissance réseau | ✅ Oui | Alerte générée | < 5 secondes |
| Brute force RDP | ✅ Oui | IP bloquée (600 s) | < 3 secondes |
| Dépôt de malware EICAR | ✅ Oui | Fichier supprimé | < 10 secondes |

---

## Structure du dépôt

```
CyberForge/
├── README.md
├── configs/
│   ├── ossec.conf              # Configuration agent Wazuh (Windows Server)
│   ├── wazuh-manager.conf      # Configuration gestionnaire Wazuh + VirusTotal
│   └── suricata.yaml           # Configuration Suricata IDS
├── active-response/
│   ├── block-ip.cmd            # Script de blocage IP (Scénario 2)
│   └── delete_malware.cpp      # Exécutable de suppression malware (Scénario 3)
├── rules/
│   └── custom_rules.xml        # Règles de détection Wazuh personnalisées
└── scripts/
    ├── setup-lab.sh            # Installation automatique du laboratoire
    └── simulate-attacks.sh     # Simulation des 3 attaques (Kali Linux)
```

---

## Enseignements clés

- La **corrélation SIEM** est indispensable : les logs isolés signifient peu, ce sont les patterns qui révèlent les attaques
- La **réponse active** comble le fossé entre détection et remédiation sans intervention humaine
- **FIM + VirusTotal** crée un pipeline d'analyse et de remédiation entièrement automatisé
- La détection **réseau** (Suricata) complète la surveillance **hôte** (agents Wazuh)

---

## Documentation

Documentation technique complète disponible dans `CyberForge_Documentation.docx`

---

**KAOUANE WALID** — Passionné de cybersécurité | Red Team / Blue Team
