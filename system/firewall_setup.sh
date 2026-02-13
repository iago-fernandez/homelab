#!/bin/bash

ufw --force reset

ufw default deny incoming
ufw default allow outgoing

# Core Infrastructure
ufw allow 51820/udp comment 'Wireguard VPN'

# Hardware Discovery
ufw allow in on eth0 to any port 5353 proto udp comment 'mDNS Discovery'
ufw allow in on eth0 to any port 1900 proto udp comment 'SSDP Discovery'

# Trusted Subnets Configuration (LAN & VPN)
SUBNETS=("192.168.1.0/24" "10.8.0.0/24")
for SUBNET in "${SUBNETS[@]}"; do
    # Administration
    ufw allow from "$SUBNET" to any port 22 proto tcp comment 'SSH Access'
    
    # Reverse Proxy
    ufw allow from "$SUBNET" to any port 80 proto tcp comment 'NPM HTTP'
    ufw allow from "$SUBNET" to any port 81 proto tcp comment 'NPM Admin'
    ufw allow from "$SUBNET" to any port 443 proto tcp comment 'NPM HTTPS'
    
    # Dashboard
    ufw allow from "$SUBNET" to any port 3000 proto tcp comment 'Homepage'
    
    # Hardware Monitoring
    ufw allow from "$SUBNET" to any port 3493 proto tcp comment 'NUT Service'
    
    # Databases
    ufw allow from "$SUBNET" to any port 5432 proto tcp comment 'PostgreSQL'
    
    # Cloud Storage
    ufw allow from "$SUBNET" to any port 8082 proto tcp comment 'Seafile'
    
    # Home Automation
    ufw allow from "$SUBNET" to any port 8123 proto tcp comment 'Home Assistant'
done

# Docker Bridge Inter-communication
DOCKER_SUBNET="172.18.0.0/16"
ufw allow from "$DOCKER_SUBNET" to any port 3000 proto tcp comment 'Homepage Docker Bridge'
ufw allow from "$DOCKER_SUBNET" to any port 8123 proto tcp comment 'Home Assistant Docker Bridge'

ufw --force enable
ufw reload