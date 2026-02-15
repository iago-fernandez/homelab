#!/bin/bash

# Automates the provisioning of the host infrastructure environment.
# Installs required dependencies, configures the base directory structure,
# and deploys the core security policies.

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting Infrastructure Installation...${NC}"

# Verify execution privileges
if [ "$EUID" -ne 0 ]; then
  echo "Execution requires root privileges. Please run with sudo."
  exit 1
fi

# Update package lists and install core dependencies
echo -e "${YELLOW}[1/4] Installing system dependencies...${NC}"
apt update && apt upgrade -y
apt install -y curl git jq bc ufw tar wireguard qrencode

# Provision Docker runtime if not present
if ! command -v docker &> /dev/null; then
    echo "Provisioning Docker runtime..."
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker "$SUDO_USER"
fi

# Initialize persistent storage and configuration directories
echo -e "${YELLOW}[2/4] Initializing directory structure...${NC}"
mkdir -p /usr/local/bin
TARGET_DIR="/home/$SUDO_USER/homelab/docker"
mkdir -p "$TARGET_DIR"

# Deploy core system scripts and apply network security policies
echo -e "${YELLOW}[3/4] Provisioning scripts and firewall...${NC}"
cp system/firewall_setup.sh /usr/local/bin/setup-firewall.sh
chmod +x /usr/local/bin/setup-firewall.sh

# Transfer orchestration manifests to the target environment
echo -e "${YELLOW}[4/4] Deploying orchestration stack...${NC}"
cp docker/docker-compose.yml "$TARGET_DIR/"

echo -e "${GREEN}Installation Sequence Complete!${NC}"
echo "Required manual steps:"
echo "1. Create '.env' file in $TARGET_DIR using the provided example."
echo "2. Execute 'docker compose up -d' within the target directory."
echo "3. Run '/usr/local/bin/setup-firewall.sh' to enforce security policies."
echo "4. Configure WireGuard cryptographic keys in /etc/wireguard/."