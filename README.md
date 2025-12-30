# HomeLab Infrastructure Configuration

This repository contains the configuration files, automation scripts, and comprehensive documentation for a self-hosted HomeLab environment running on Raspberry Pi OS (Debian based).

The project implements a production-grade infrastructure focusing on network segmentation, security, and service isolation. It serves as a centralized hub for private cloud storage, secure remote access, and network-wide DNS filtering.

> **Disclaimer:** This repository serves as a portfolio demonstration.
> * **Sensitive Data:** All private domains, IPs, passwords, and keys have been replaced with generic placeholders (e.g., `files.example.com`, `<REDACTED>`). These must be adjusted for a real deployment.
>
> * **Localization:** While the codebase and comments are in **English** (standard practice), the user-facing Dashboard interface is localized to **Spanish** to suit the end-users of this specific LAN.

## 1. Infrastructure Prerequisites & Network Topology

Before the software deployment, specific networking configurations were applied to the physical infrastructure to ensure connectivity and addressability.

### 1.1. WAN Configuration
* **Public IP Addressing:** Requested removal from Carrier-Grade NAT (CGNAT) to obtain a public, routable IPv4 address. This is a strict requirement for the WireGuard VPN handshake and external HTTPS access.

    > *Note:* Removal from CGNAT implies obtaining a non-shared public IP. In this deployment, it was achieved by contacting the ISP technical support and justifying the need for VPN implementation. Certain ISPs may require a payment for this purpose, or CGNAT removal may be unavailable at all.

* **Dynamic DNS (DDNS):** Implemented via **FreeDNS**. Since the ISP provides a dynamic public IP, a background daemon monitors the WAN IP and updates the `A` record of the domain automatically, ensuring high availability for remote access without a static WAN IP.

### 1.2. Router Configuration
* **DHCP Reservation:** A static IPv4 lease (`192.168.1.200`) was configured on the main router for the Raspberry Pi MAC address. This ensures that Port Forwarding rules and DNS pointers remain valid after reboots.
* **Port Forwarding (Hardening):** To minimize the attack surface, **only** encrypted traffic ports are forwarded.

    * **TCP 443 (HTTPS) → 192.168.1.200:** Forwarded to Nginx. Allows secure public access to **Filebrowser**.

    * **UDP 51820 (VPN) → 192.168.1.200:** Forwarded to WireGuard. Allows secure tunnel creation.
    
    * *Note:* Port 80 (HTTP) is deliberately **closed** on the WAN side to prevent unencrypted access.
* **DNS Settings:** The router's primary DNS server points to the Pi-hole instance (`192.168.1.200`). This forces all LAN devices to filter traffic through the local ad-blocker automatically.


## 2. Architecture Overview

The system follows a tiered architecture designed to minimize the attack surface while maintaining ease of access.

### 2.1. Split-DNS Architecture
The network employs a Split-DNS strategy to optimize traffic flow:
* **External Access (WAN):** Requests to the domain resolve via public DNS to the ISP Public IP. Traffic enters via the router (Port 443) and is handled by Nginx.

* **Internal Access (LAN):** Requests to the same domain resolve directly to the Local IP (`192.168.1.200`) via Pi-hole. This prevents "hairpinning" (NAT loopback), improving transfer speeds and latency for local devices.

### 2.2. Service Layers
1.  **Edge Layer:** UFW Firewall and Nginx Reverse Proxy (SSL termination, Rate Limiting).

2.  **Application Layer (Hybrid):**
    * **Docker:** Used for complex stacks (Seafile, Database).

    * **Bare Metal (Systemd):** Used for performance-critical or simple services (Filebrowser, Unbound).

3.  **Network Services Layer:** Pi-hole (DNS Sinkhole), Unbound (Recursive Resolver), and WireGuard (VPN).

4.  **Monitoring Layer:** Custom Bash-based metric collection and HTML/JS dashboard.

## 3. Repository Structure

```text
.
├── docker
│   └── docker-compose.yml                     # Seafile, MariaDB & Memcached orchestration
├── nginx
│   ├── html_dashboard                         # Custom vanilla JS Dashboard
│   │   ├── assets
│   │   │   ├── app.js                         # Main navigation logic
│   │   │   ├── status.json                    # Metric data structure example
│   │   │   ├── status-page.js                 # Async status fetch logic
│   │   │   └── styles.css                     # Dark/Light mode styles
│   │   ├── index.html                         # Landing page
│   │   └── pages
│   │       ├── estado.html                    # System status page
│   │       └── guia.html                      # Documentation page
│   └── sites-available                        # Nginx Virtual Hosts
│       ├── 00-default.conf                    # Dashboard & Base redirects
│       ├── 10-pihole.conf                     # Pi-hole Admin Panel Proxy
│       ├── 20-seafile.conf                    # Seafile Private Access (LAN/VPN)
│       ├── 30-filebrowser-lan.conf            # Internal Filebrowser Access
│       └── 40-external-https.conf             # Public Filebrowser Access (SSL)
├── pihole
│   └── pihole.toml                            # Pi-hole v6 configuration
├── system
│   ├── certbot
│   │   └── renewal-example.conf               # Let's Encrypt renewal template
│   ├── crontab_jobs.txt                       # Scheduled maintenance tasks
│   ├── filebrowser.service                    # Filebrowser Systemd unit
│   ├── firewall_setup.sh                      # UFW Security Policies script
│   ├── scripts
│   │   └── generate_stats.sh                  # Bash logic (Metrics Generator)
│   └── systemd
│       ├── dashboard-stats.service            # Metric Service definition
│       └── dashboard-stats.timer              # Metric Timer definition
├── unbound
│   ├── pi-hole.conf                           # Localhost-only resolver config
│   ├── remote-control.conf                    # Unbound control config
│   └── root-auto-trust-anchor-file.conf       # DNSSEC Trust anchor
└── wireguard
    ├── scripts                                # Client management scripts
    │   ├── wg-add-client
    │   ├── wg-del-client
    │   └── wg-show-qr
    └── wg0.conf.example                       # VPN Server Interface template
```

## 4. Component Details & Configuration

### 4.1. Nginx Reverse Proxy & Security
Nginx acts as the **Secure Gateway** for the infrastructure. It listens on port 443, terminates SSL/TLS, and routes traffic based on a strict exposure policy:

* **Exposure Policy:**

    * **Public (WAN):** Only **Filebrowser** is exposed via HTTPS to allow temporary file access.

    * **Private (LAN/VPN):** The Dashboard and other critical services like **Seafile** or **Pi-Hole** are not exposed to the WAN. Nginx only serves these from internal requests.
* **DDoS & Brute Force Protection (Rate Limiting):**
    Nginx is configured with the `limit_req` module (`zone=perip burst=20 nodelay`). This protects login forms by restricting the number of requests a single IP can make per second. If a bot attempts a dictionary attack to guess passwords, Nginx drops the connections (HTTP 503) before they impact the application backend.
* **Security Headers:**
    The configuration enforces industry-standard security headers:

    * `Strict-Transport-Security` (HSTS): Enforces HTTPS.

    * `X-Frame-Options`: Blocks Clickjacking.

    * `X-Content-Type-Options`: Prevents MIME-type sniffing.

### 4.2. WireGuard VPN
WireGuard provides secure remote access to the home network. The implementation includes helper scripts to manage clients easily.

* **Client Profiles (Split vs. Full):**
    The setup supports two tunneling modes per client:

    1.  **Split-Tunnel:** Routes only LAN traffic (`192.168.1.x`) and DNS through the VPN. Ideal for accessing home services without slowing down regular internet usage.

    2.  **Full-Tunnel:** Routes ALL traffic (`0.0.0.0/0`) through the home connection. Ideal for using untrusted public WiFi networks securely.
* **Onboarding via QR:**
    The server includes scripts to generate configuration QR codes directly in the terminal (`qrencode`). This allows mobile clients to onboard instantly by scanning the screen, avoiding the security risk of transferring private key files.

### 4.3. DNS Stack (Pi-hole + Unbound)
* **Pi-hole:** Primary DNS. Blocks ads/trackers and maps internal hostnames (`seafile.lan`) to the server IP.

* **Unbound:** Recursive Resolver listening on `127.0.0.1:5335`. Instead of forwarding queries to Google/Cloudflare, it contacts Root DNS servers directly. This ensures complete privacy and validation (DNSSEC) without third-party tracking.

### 4.4. Hybrid Application Hosting
The system uses a hybrid approach to balance isolation and performance:

* **Dockerized Services (Seafile - Private):**
    Seafile (Enterprise-class file sync) runs in Docker to manage its complex dependencies (MariaDB, Memcached, Seahub).

    * *Internal Ports:* Seafile listens on `127.0.0.1:8083` (Web) and `8084` (Data). Nginx handles the traffic internally (LAN/VPN), ensuring **no public exposure** of the main NAS data.
* **Bare Metal Services (Filebrowser - Public):**
    Filebrowser runs as a native `systemd` service. This provides direct, high-performance access to the underlying filesystem structure without the overhead of container volume mapping.
    * *Hardening:* Since this service is exposed to the WAN, the Systemd unit uses `ProtectSystem=full` and `NoNewPrivileges=true` to sandbox the process.

### 4.5. Automation & Monitoring
* **Metrics Generation:** A custom Bash script (`system/scripts/generate_stats.sh`) is triggered every 2 minutes by a Systemd Timer. It collects low-level kernel data (load averages, memory, disk I/O) and WireGuard peer status.

* **Dashboard:** A custom vanilla HTML/JS frontend consumes the metrics JSON. It is designed to be extremely lightweight and it is localized in Spanish for the household users.

## 5. Security Measures Summary

* **Firewall (UFW):** Implements a "Default Deny" policy.

    * **Incoming:** Denied. Only ports 443 (HTTPS) and 51820 (VPN) are allowed from WAN.
    * **Internal:** LAN devices have access to DNS (53) and HTTP (80) for redirects.
* **SSH Hardening:** Port 22 is rate-limited and typically accessed only via the VPN tunnel, reducing exposure to internet scanners.
* **Sanitization:** This repository is a sanitized snapshot. Real-world deployment requires generating unique keys and passwords.

## 6. Deployment Notes

To replicate this setup:

1.  **Network Setup:** Ensure Static IP and Port Forwarding (443/51820) are active on the router and DDNS is syncing.
2.  **Firewall:** Execute `system/firewall_setup.sh` to lock down the system immediately.
3.  **Services Initialization:**

    * Copy systemd units and enable timers.
    * Symlink Nginx sites and reload.
    * Start the Docker stack: `docker compose up -d`.
4.  **DNS Integration:** Configure Unbound on port 5335 and point Pi-hole upstream to it.

---
*Documentation generated for HomeLab v1.0*
