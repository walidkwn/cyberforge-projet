# CyberForge: A Cybersecurity Lab Project

**Author:** KAOUANE WALID
**Duration:** 10 days
**Focus:** Red Team / Blue Team simulation in an isolated Windows/Active Directory environment

---

## Project Overview

CyberForge is a personal virtual laboratory created to simulate realistic intrusion and response scenarios in an isolated Windows/Active Directory environment. The project demonstrates both offensive (Red Team) and defensive (Blue Team) cybersecurity capabilities.

This lab was built to gain hands-on experience with industry-standard SOC (Security Operations Center) tools, covering threat detection, automated incident response, and malware remediation.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   CyberForge Lab Network                │
│                                                         │
│  ┌──────────────┐        ┌──────────────────────────┐  │
│  │  Kali Linux  │──────▶ │  Windows Server (AD)     │  │
│  │  (Attacker)  │        │  + Wazuh Agent           │  │
│  └──────────────┘        └──────────────┬───────────┘  │
│                                          │              │
│  ┌──────────────┐        ┌──────────────▼───────────┐  │
│  │   Suricata   │◀───────│  Network Traffic         │  │
│  │   (IDS)      │        └──────────────────────────┘  │
│  └──────┬───────┘                                       │
│         │                                               │
│  ┌──────▼───────────────────────────────────────────┐  │
│  │           Wazuh Manager (SIEM/EDR)               │  │
│  │     - Alert aggregation & correlation            │  │
│  │     - Automated active response                  │  │
│  │     - VirusTotal integration                     │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Key Components

### Security Tools Used

| Tool | Role | Description |
|------|------|-------------|
| **Wazuh** | SIEM / EDR | Open-source platform for threat detection, integrity monitoring, and incident response |
| **Suricata** | Network IDS | Real-time network traffic analysis and intrusion detection |
| **VirusTotal** | Malware Analysis | Cloud-based malware analysis integrated with Wazuh FIM |
| **Kali Linux** | Attack Simulation | Offensive security tools (Nmap, Hydra) for Red Team scenarios |
| **Windows AD** | Target Infrastructure | Active Directory domain controller as the monitored environment |

---

## Three Main Scenarios

### Scenario 1 — Network Reconnaissance Detection

**Objective:** Detect and alert on network scanning activity
**Attack Tool:** Nmap (from Kali Linux)
**Detection:** Suricata IDS + Wazuh

**Flow:**
```
Kali Linux                 Suricata                    Wazuh
    │                          │                          │
    │── nmap -sS target ──────▶│                          │
    │                          │ Detects SYN scan         │
    │                          │ signatures               │
    │                          │──── Alert forwarded ────▶│
    │                          │                          │ Dashboard alert
    │                          │                          │ Rule triggered
```

**Outcome:** Suricata successfully identified SYN/ACK scans and network mapping phases. Alerts escalated to Wazuh dashboard with full packet metadata.

---

### Scenario 2 — RDP Brute Force Defense

**Objective:** Automatically block IPs performing RDP brute force attacks
**Attack Tool:** Hydra (from Kali Linux)
**Detection & Response:** Wazuh Rule 60204 → Active Response → netsh firewall block

**Flow:**
```
Kali Linux                 Windows Server              Wazuh Manager
    │                          │                          │
    │── hydra rdp://target ───▶│                          │
    │   (multiple failed        │                          │
    │    login attempts)        │── Auth failure logs ────▶│
    │                          │                          │ Rule 60204 fires
    │                          │◀─── Block command ───────│
    │                          │ netsh advfirewall add    │
    │                          │ rule block IP (600s)     │
    │                    ✗     │                          │
    │── Connection blocked ────│                          │
```

**Wazuh Active Response script (`block-ip.cmd`):**
```batch
@echo off
SET IP=%1
netsh advfirewall firewall add rule name="WAZUH_BLOCK_%IP%" ^
    protocol=any dir=in action=block remoteip=%IP%
timeout /t 600 >nul
netsh advfirewall firewall delete rule name="WAZUH_BLOCK_%IP%"
```

**Outcome:** Wazuh Rule 60204 triggers automatic IP blocking through Windows netsh commands for 600 seconds (10 minutes), effectively neutralizing the brute force attack in real-time.

---

### Scenario 3 — Malware Detection and Removal

**Objective:** Detect, analyze, and automatically remove malicious files
**Test File:** EICAR standard antivirus test file
**Detection:** Wazuh FIM + VirusTotal API + Custom Active Response executable

**Flow:**
```
File Drop                  Wazuh FIM                   VirusTotal
    │                          │                          │
    │── EICAR file created ───▶│                          │
    │                          │ FIM detects new file     │
    │                          │── Hash submitted ───────▶│
    │                          │                          │ 60+/72 engines
    │                          │◀─── Malicious verdict ───│
    │                          │                          │
    │                    Active Response                  │
    │                          │                          │
    │                          │── delete_malware.exe ──▶ │
    │                          │   (removes file)         │
    │                    File deleted ✓                   │
```

**Custom removal executable (`delete_malware.cpp`):**
```cpp
#include <windows.h>
#include <string>

int main(int argc, char* argv[]) {
    if (argc < 2) return 1;
    std::string filePath = argv[1];
    if (DeleteFileA(filePath.c_str())) {
        return 0; // Success
    }
    return 1; // Failed
}
```

**Outcome:** File Integrity Monitoring (FIM) detected the EICAR test file, VirusTotal confirmed it as malicious (60+/72 antivirus engines), and the custom Windows executable automatically deleted the threat, validating the complete detection-to-remediation chain.

---

## Setup Guide

### Prerequisites

- VMware Workstation or VirtualBox
- At least 16 GB RAM (recommended: 32 GB)
- 200 GB free disk space

### Virtual Machines Required

| VM | OS | Role | RAM |
|----|-----|------|-----|
| Wazuh Server | Ubuntu 22.04 | SIEM Manager | 4 GB |
| Windows Server | Windows Server 2019 | AD + Target | 4 GB |
| Kali Linux | Kali 2024 | Attacker | 2 GB |

### Installation Steps

**1. Deploy Wazuh Manager:**
```bash
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
sudo bash ./wazuh-install.sh -a
```

**2. Install Wazuh Agent on Windows Server:**
```powershell
Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.0-1.msi" `
    -OutFile "wazuh-agent.msi"
msiexec.exe /i wazuh-agent.msi WAZUH_MANAGER="<WAZUH_SERVER_IP>"
```

**3. Configure Suricata on Wazuh Server:**
```bash
sudo apt install suricata -y
sudo suricata-update
# Edit /etc/suricata/suricata.yaml to set your network interface
```

**4. Enable VirusTotal Integration in Wazuh:**
```xml
<!-- Add to /var/ossec/etc/ossec.conf -->
<integration>
    <name>virustotal</name>
    <api_key>YOUR_VIRUSTOTAL_API_KEY</api_key>
    <rule_id>550,554</rule_id>
    <alert_format>json</alert_format>
</integration>
```

---

## Wazuh Configuration Snippets

### ossec.conf — File Integrity Monitoring
```xml
<syscheck>
    <frequency>300</frequency>
    <directories check_all="yes" realtime="yes">C:\Users\Public\Downloads</directories>
    <directories check_all="yes" realtime="yes">C:\Temp</directories>
</syscheck>
```

### ossec.conf — Active Response (IP Block)
```xml
<active-response>
    <command>firewall-drop</command>
    <location>local</location>
    <rules_id>60204</rules_id>
    <timeout>600</timeout>
</active-response>
```

---

## Results Summary

| Scenario | Attack Detected | Response Automated | Time to Respond |
|----------|-----------------|-------------------|-----------------|
| Nmap Reconnaissance | ✅ Yes | ✅ Alert Generated | < 5 seconds |
| RDP Brute Force | ✅ Yes | ✅ IP Blocked (600s) | < 3 seconds |
| EICAR Malware Drop | ✅ Yes | ✅ File Deleted | < 10 seconds |

---

## Key Learnings

- **SIEM correlation** is critical: individual logs mean little; patterns reveal attacks
- **Active Response** bridges detection and remediation without human intervention
- **FIM + threat intelligence** (VirusTotal) creates a powerful automated analysis pipeline
- **Network-layer detection** (Suricata) complements host-based monitoring (Wazuh agents)

---

## Author

**KAOUANE WALID**
Cybersecurity enthusiast | Red Team / Blue Team practitioner

*Project completed in 10 days as a personal hands-on cybersecurity lab.*
