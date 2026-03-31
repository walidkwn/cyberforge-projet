#!/bin/bash
# ================================================================
#  CyberForge - Lab Setup Script
#  Author: KAOUANE WALID
#
#  Run this on the Ubuntu 22.04 Wazuh Manager VM.
#  Installs and configures: Wazuh Manager, Suricata, and applies
#  all CyberForge custom configurations.
#
#  Usage:
#    chmod +x setup-lab.sh
#    sudo ./setup-lab.sh
# ================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

WAZUH_VERSION="4.7.0"
VIRUSTOTAL_API_KEY="${VIRUSTOTAL_API_KEY:-YOUR_API_KEY_HERE}"

log_info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC}   $1"; exit 1; }

# ----------------------------------------------------------------
# Check root
# ----------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (sudo ./setup-lab.sh)"
fi

echo ""
echo "================================================================"
echo "   CyberForge Lab Setup"
echo "   Author: KAOUANE WALID"
echo "================================================================"
echo ""

# ----------------------------------------------------------------
# Step 1: System update
# ----------------------------------------------------------------
log_info "Step 1/6: Updating system packages..."
apt-get update -qq && apt-get upgrade -y -qq
log_success "System updated."

# ----------------------------------------------------------------
# Step 2: Install Wazuh Manager
# ----------------------------------------------------------------
log_info "Step 2/6: Installing Wazuh Manager ${WAZUH_VERSION}..."

if command -v wazuh-manager &>/dev/null; then
    log_warning "Wazuh Manager already installed. Skipping."
else
    curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
    chmod +x wazuh-install.sh
    bash ./wazuh-install.sh -a -i
    log_success "Wazuh Manager installed."
fi

# ----------------------------------------------------------------
# Step 3: Install Suricata
# ----------------------------------------------------------------
log_info "Step 3/6: Installing Suricata IDS..."

if command -v suricata &>/dev/null; then
    log_warning "Suricata already installed. Skipping."
else
    apt-get install -y suricata
    suricata-update
    log_success "Suricata installed and rules updated."
fi

# ----------------------------------------------------------------
# Step 4: Apply CyberForge configurations
# ----------------------------------------------------------------
log_info "Step 4/6: Applying CyberForge configurations..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../configs"
RULES_DIR="${SCRIPT_DIR}/../rules"

# Backup existing configs
cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.bak.$(date +%Y%m%d%H%M%S)
cp /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml.bak.$(date +%Y%m%d%H%M%S)

# Apply Wazuh manager config
cp "${CONFIG_DIR}/wazuh-manager.conf" /var/ossec/etc/ossec.conf

# Apply custom detection rules
cp "${RULES_DIR}/custom_rules.xml" /var/ossec/etc/rules/cyberforge_rules.xml

# Apply Suricata config
cp "${CONFIG_DIR}/suricata.yaml" /etc/suricata/suricata.yaml

log_success "Configurations applied."

# ----------------------------------------------------------------
# Step 5: Configure VirusTotal API key
# ----------------------------------------------------------------
log_info "Step 5/6: Configuring VirusTotal integration..."

if [[ "${VIRUSTOTAL_API_KEY}" == "YOUR_API_KEY_HERE" ]]; then
    log_warning "VirusTotal API key not set. Set VIRUSTOTAL_API_KEY env var before running."
    log_warning "  export VIRUSTOTAL_API_KEY=your_key_here && sudo -E ./setup-lab.sh"
else
    sed -i "s/YOUR_VIRUSTOTAL_API_KEY_HERE/${VIRUSTOTAL_API_KEY}/" /var/ossec/etc/ossec.conf
    log_success "VirusTotal API key configured."
fi

# ----------------------------------------------------------------
# Step 6: Start / restart services
# ----------------------------------------------------------------
log_info "Step 6/6: Starting services..."

systemctl restart wazuh-manager
systemctl enable wazuh-manager
systemctl status wazuh-manager --no-pager

systemctl restart suricata
systemctl enable suricata
systemctl status suricata --no-pager

log_success "All services started."

# ----------------------------------------------------------------
# Summary
# ----------------------------------------------------------------
echo ""
echo "================================================================"
echo -e "${GREEN}  CyberForge lab setup complete!${NC}"
echo ""
echo "  Wazuh Dashboard:  https://$(hostname -I | awk '{print $1}')"
echo "  Default creds:    admin / (set during install)"
echo ""
echo "  Next steps:"
echo "  1. Install Wazuh Agent on your Windows Server VM"
echo "  2. Add KAOUANE_WALID_KEY to wazuh-manager.conf if needed"
echo "  3. Run scenario attack simulations from Kali Linux"
echo "================================================================"
echo ""
