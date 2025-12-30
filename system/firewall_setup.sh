#!/bin/bash
# UFW (Uncomplicated Firewall) Configuration Script
# Policy: Default Deny Incoming / Allow Outgoing

# 1. Reset previous configuration
ufw --force reset

# 2. Set default policies
ufw default deny incoming
ufw default allow outgoing
ufw default deny routed  # Block routing by default (enabled later for VPN)

# 3. Public Services (WAN)
# SSH (Rate limited to prevent brute force attacks)
ufw limit 22/tcp comment 'SSH'
# HTTP/HTTPS (Nginx Reverse Proxy)
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
# WireGuard VPN (UDP Port)
ufw allow 51820/udp comment 'WireGuard VPN'

# 4. Internal Services (LAN Only - 192.168.1.0/24)
# DNS (TCP/UDP) for Pi-hole
ufw allow from 192.168.1.0/24 to any port 53 proto udp comment 'DNS UDP LAN'
ufw allow from 192.168.1.0/24 to any port 53 proto tcp comment 'DNS TCP LAN'
# DHCP (If Pi-hole acts as DHCP server)
ufw allow from 192.168.1.0/24 to any port 67 proto udp comment 'DHCP Server'

# 5. VPN Client Rules (WireGuard Subnet - 10.8.0.0/24)
# Allow VPN clients to access Pi-hole DNS
ufw allow from 10.8.0.0/24 to any port 53 proto udp comment 'DNS UDP VPN'
ufw allow from 10.8.0.0/24 to any port 53 proto tcp comment 'DNS TCP VPN'
# Allow VPN clients to SSH into the server
ufw allow from 10.8.0.0/24 to any port 22 proto tcp comment 'SSH VPN'

# 6. NAT / Routing Reminder
echo "IMPORTANT: Ensure NAT is configured in /etc/ufw/before.rules to allow VPN traffic egress."

# 7. Enable Firewall
ufw enable
