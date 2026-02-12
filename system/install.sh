#!/bin/bash
# HomeLab Infrastructure Installer
# Deploys Nginx, WireGuard, Docker services, and Systemd automations.
# Run this script with sudo.

set -e  # Exit immediately if a command exits with a non-zero status.

# --- Colors for output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting HomeLab Installation...${NC}"

# 1. Check for Root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./install.sh)"
  exit 1
fi

# 2. System Update & Dependencies
echo -e "${YELLOW}[1/6] Installing dependencies...${NC}"
apt update && apt upgrade -y
apt install -y nginx wireguard unbound curl git jq bc ufw tar

# Install Docker (simplified for Debian/Raspbian)
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker $SUDO_USER
fi

# 3. Setup Directories
echo -e "${YELLOW}[2/6] Creating directory structure...${NC}"
# Web Dashboard
mkdir -p /var/www/html/assets
mkdir -p /var/www/html/pages
# System Scripts
mkdir -p /usr/local/bin

# 4. Deploy Nginx
echo -e "${YELLOW}[3/6] Configuring Nginx...${NC}"
cp nginx/sites-available/* /etc/nginx/sites-available/
# Remove default nginx config
rm -f /etc/nginx/sites-enabled/default
# Create symlinks
for file in /etc/nginx/sites-available/*; do
    filename=$(basename "$file")
    ln -sf "$file" "/etc/nginx/sites-enabled/$filename"
done
# Deploy Dashboard static files
cp -r nginx/html_dashboard/* /var/www/html/
chown -R www-data:www-data /var/www/html

# 5. Deploy System Scripts & Services
echo -e "${YELLOW}[4/6] Configuring System Services...${NC}"
# Copy stats generator
cp system/scripts/generate_stats.sh /usr/local/bin/
chmod +x /usr/local/bin/generate_stats.sh

# Copy Systemd units
cp system/systemd/* /etc/systemd/system/
cp system/filebrowser.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now dashboard-stats.timer

# Copy Firewall script
cp system/firewall_setup.sh /usr/local/bin/setup-firewall.sh
chmod +x /usr/local/bin/setup-firewall.sh

# 6. Deploy Docker Services
echo -e "${YELLOW}[5/6] Setting up Docker containers...${NC}"
# We copy the docker folder to the user's home (assuming execution via sudo from repo root)
TARGET_DIR="/home/$SUDO_USER/homelab/docker"
mkdir -p "$TARGET_DIR"
cp docker/docker-compose.yml "$TARGET_DIR/"
# Note: .env is not copied automatically for security, user must create it.

echo -e "${YELLOW}NOTE:${NC} Please create a .env file in $TARGET_DIR based on your needs."

# 7. Unbound & Pi-hole prep
echo -e "${YELLOW}[6/6] Configuring DNS (Unbound)...${NC}"
if [ -d "/etc/unbound/unbound.conf.d" ]; then
    cp unbound/pi-hole.conf /etc/unbound/unbound.conf.d/
    service unbound restart
fi
echo -e "${GREEN}Installation Complete!${NC}"
echo "Next steps:"
echo "1. Create .env file in /home/$SUDO_USER/homelab/docker/"
echo "2. Run 'docker compose up -d' in that directory."
echo "3. Run '/usr/local/bin/setup-firewall.sh' to enable security."
echo "4. Configure WireGuard keys in /etc/wireguard/."
