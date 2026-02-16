# Self-Hosted Infrastructure and Private Cloud

[![Status](https://img.shields.io/badge/status-stable-green?style=flat-square)](https://github.com/iago-fernandez/homelab/releases)
[![Language](https://img.shields.io/badge/language-Shell-blue?style=flat-square)](system/install.sh)
[![Platform](https://img.shields.io/badge/platform-Docker-yellow.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/license-MIT-orange?style=flat-square)](LICENSE)

A secure, modular, and automated infrastructure implementation designed for Debian environments. This project integrates containerized services, a hardened network stack via WireGuard VPN, and automated system management scripts.

## Architecture Overview

The system is built on a microservices architecture using Docker Compose, focusing on strict network isolation and data sovereignty. Unlike traditional setups that expose services to the public internet, this infrastructure relies entirely on a secure VPN tunnel for remote access.

* Orchestration: Docker Compose with a modular directory structure.
* Networking: WireGuard VPN for private remote access using Cloudflare DNS for enhanced privacy.
* Security: Uncomplicated Firewall (UFW) with a default deny policy, restricting service access to local and VPN subnets.
* Routing: Nginx Proxy Manager for internal reverse proxying and SSL termination.
* Monitoring: Homepage dashboard for centralized service visualization.

## Quick Start

### Prerequisites

* Debian-based system (Raspberry Pi OS / Ubuntu).
* Root privileges.

### Installation

The repository includes an automated bootstrap script to provision dependencies, security policies, and the directory structure.

```bash
sudo bash system/install.sh

```

### Post-Installation

1. Navigate to the workspace:
```bash
cd ~/homelab/docker

```


2. Configure environment variables:
```bash
cp .env.example .env

```


3. Launch the stack:
```bash
docker compose up -d

```


4. Generate VPN clients:
```bash
sudo wg-add-client <client-name>

```



## Documentation Modules

Detailed technical documentation is available for each core component:

* [System and Security](https://www.google.com/search?q=system/README.md): Installation logic, firewall rules, and host hardening.
* [Network and VPN](https://www.google.com/search?q=network/wireguard/README.md): WireGuard server configuration, DNS privacy, and client management.
* [Container Stack](https://www.google.com/search?q=docker/README.md): Service definitions, ports, and environment configuration.
* [Configuration and Persistence](https://www.google.com/search?q=config/README.md): Volume mapping strategies and directory hierarchy.

## Contributing

Contributions are welcome. Please ensure that any pull requests follow the existing code style, utilize conventional commits, and include appropriate updates to the documentation.

## License

This project is licensed under the MIT License. See the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.