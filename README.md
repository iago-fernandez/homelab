# Self-Hosted Infrastructure and Private Cloud

A secure, modular, and automated infrastructure implementation designed for Debian environments. This project integrates containerized services, a hardened network stack via WireGuard VPN, and automated system management scripts.

[![Status](https://img.shields.io/badge/status-stable-green?style=flat-square)](https://github.com/iago-fernandez/homelab/releases)
[![Language](https://img.shields.io/badge/language-Shell-blue?style=flat-square)](system/install.sh)
[![Platform](https://img.shields.io/badge/platform-Docker-yellow.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/license-MIT-orange?style=flat-square)](LICENSE)

> **Disclaimer:** This repository contains a sanitized snapshot of a production environment. All private domains, IP addresses, passwords, and cryptographic keys have been strictly redacted for security purposes. The repository utilizes generic placeholders (e.g., `<REDACTED>`) and `.env.example` templates to illustrate the configuration structure without leaking operational secrets. These must be duplicated and populated with valid, secure credentials before initialization.

## Architecture Overview

The system is built on a microservices architecture using Docker Compose, focusing on strict network isolation and data sovereignty. Unlike traditional setups that expose services to the public internet, this infrastructure relies entirely on a secure VPN tunnel for remote access.

* Orchestration: Docker Compose with a modular directory structure.
* Networking: WireGuard VPN for private remote access.
* Security: Uncomplicated Firewall (UFW) with a default deny policy, restricting service access to local and VPN subnets exclusively.
* Routing: Nginx Proxy Manager for internal reverse proxying and SSL termination.
* Monitoring: Homepage dashboard for centralized service visualization.

## Deployment Environment and High Availability

This infrastructure is optimized for resource-constrained edge computing while maintaining enterprise-grade reliability.

* Hardware: The production environment currently operates on a Raspberry Pi 4 Model B (4GB RAM) utilizing an ARM64 architecture.
* Network: Backed by a residential symmetrical gigabit fiber connection.
* Power Management: The host is connected to an Uninterruptible Power Supply (UPS). Telemetry is actively monitored, and an automated policy executes a graceful system shutdown when the battery capacity drops to 20% during an outage. The system is configured for automatic recovery upon power restoration.

## Architectural Evolution

The infrastructure has been iteratively refined to adopt a strict Zero-Trust model, prioritizing hermetic security and low resource overhead.

* Attack Surface Reduction: Previous iterations exposed public ports for external access. The architecture has been migrated to a VPN-exclusive model, closing all public ingress except the encrypted WireGuard UDP endpoint, neutralizing external scanning and brute-force attempts.
* DNS Delegation: Local DNS resolution and ad-blocking responsibilities have been delegated to a third-party provider (NordVPN/Cloudflare). This offloads compute overhead from the local host and enhances systemic privacy.

## Infrastructure Roadmap

The project is continuously evolving. The following upgrades are planned for the upcoming deployment cycles:

* Hardware Migration: Transition the compute layer from the ARM-based Raspberry Pi to an x86 MiniPC architecture to increase compute density and service scalability.
* Storage Array: Implement a high-capacity Hard Disk Drive (HDD) array utilizing RAID configuration for robust NAS capabilities, pending favorable hardware market stabilization.
* Automated Telemetry: Integrate Telegram API hooks to deliver automated alerts regarding system health, UPS status, and container stability directly to a dedicated administrative channel.
* Web Hosting: Deploy and expose a containerized, public-facing portfolio website directly from the new edge compute node.

## Quick Start

### Prerequisites

* Debian-based system.
* Root privileges.

### Installation

The repository includes an automated bootstrap script to provision dependencies, security policies, and the directory structure.

```bash
sudo bash system/install.sh
```

### Post-Installation

Navigate to the workspace:

```bash
cd ~/homelab/docker
```

Configure environment variables (populate with secure values):

```bash
cp .env.example .env
nano .env # or use any editor
```

Launch the stack:

```bash
docker compose up -d
```

Configure physical routing and internal services:

* Router Configuration: Forward UDP port 51820 on your physical ISP router to the host machine to allow external WireGuard VPN handshakes.

* Service Initialization: Access the internal web interfaces via the local network to complete the initial application setup (e.g., initialize the Seafile administrator account, configure Nginx Proxy Manager internal routes, and set up Homepage widgets).

You can finally generate and configure VPN clients (further info for the VPN configuration and usage under the [Network and VPN]() section).

## Documentation Modules

Detailed technical documentation is available for each core component:

* [System and Security](system/README.md): Installation logic, firewall rules, and host hardening.
* [Network and VPN](network/wireguard/README.md): WireGuard server configuration and client management.
* [Container Stack](docker/README.md): Service definitions, ports, and environment configuration.
* [Configuration and Persistence](config/README.md): Volume mapping strategies and directory hierarchy.

## Contributing

Contributions are welcome. Please read the [CONTRIBUTING]() file for details on our code of conduct, engineering standards, and the process for submitting pull requests.

## License

This project is licensed under the MIT License. See the [LICENSE]() file for details.