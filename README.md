# HomeLab Infrastructure and Private Cloud

A secure, modular, and automated infrastructure implementation designed for Debian environments. This project integrates containerized services, centralized proxy routing, and bare-metal hardware management to provide a robust, production-grade private cloud.

[![Status](https://img.shields.io/badge/status-stable-green?style=flat-square)](https://github.com/iago-fernandez/homelab/releases)
[![Platform](https://img.shields.io/badge/platform-Docker-yellow.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/license-MIT-orange?style=flat-square)](LICENSE)

> **Disclaimer:** This repository contains a sanitized snapshot of a production environment. All private domains, IP addresses, passwords, and cryptographic keys have been strictly redacted. The repository utilizes generic placeholders and `.example` templates to illustrate the configuration structure without leaking operational secrets.

## Architecture Overview

The system is built on a hybrid architecture, combining bare-metal networking daemons for performance with Docker Compose for application orchestration. 

* **Orchestration:** Docker Compose managing isolated application networks.
* **Networking:** WireGuard VPN running on the host kernel for private remote access.
* **Security:** Uncomplicated Firewall (UFW) enforcing a default deny policy, restricting service access strictly to proxy routes and VPN subnets.
* **Routing:** Nginx Proxy Manager handling internal reverse proxying and SSL termination.
* **Hardware Management:** Network UPS Tools (NUT) running on bare metal to monitor power states and orchestrate safe shutdowns.

### Core Services

* **Homepage:** A secure, local dashboard providing centralized access to the infrastructure.
* **Seafile:** A high-performance, private cloud storage solution with data syncing capabilities.
* **PostgreSQL:** The primary relational database, securely isolated from external access.
* **Nginx Proxy Manager:** Handles internal reverse proxy routing and SSL certificate termination.
* **WireGuard:** A bare-metal VPN implementation ensuring secure, encrypted remote access to the homelab.

## Deployment Environment and High Availability

This infrastructure is optimized for resource-constrained edge computing while maintaining enterprise-grade reliability.

* **Hardware:** The production environment operates on a Raspberry Pi 4 Model B (ARM64 architecture) with 4GB of LPDDR4 RAM.
* **Network:** Backed by a residential symmetrical gigabit fiber connection, ensuring high-speed data transfer through the WireGuard tunnel.
* **Power Management:** The host is connected to an Uninterruptible Power Supply (UPS). Telemetry is monitored by the `nut-monitor` daemon. An automated policy executes a graceful system shutdown during critical battery depletion (using `docker compose down` for data integrity). The system is configured for automatic recovery upon power restoration.

## Repository Structure

```text
.
├── baremetal
│   ├── nut                      # Sanitized Network UPS Tools configurations
│   └── wireguard                # VPN interface and automated client scripts
├── docker
│   ├── docker-compose.yml       # Core infrastructure orchestration
│   ├── .env.example             # Environment variable template
│   └── homepage                 # Localized dashboard configuration
├── .gitignore                   # Strict security and volume boundaries
└── README.md                    # Project documentation
````

## Bare-Metal Configuration

To minimize the attack surface and maximize throughput, critical networking and power management services run directly on the host OS. The `baremetal/` directory contains sanitized configuration templates and automated management scripts.

### Firewall Policy (UFW)

The host OS utilizes a strict Uncomplicated Firewall configuration. All external ports are blocked by default, requiring a VPN handshake for service access.

```bash
# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Ingress rules
sudo ufw allow 51820/udp
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
sudo ufw allow from 10.8.0.0/24 to any port 22 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 80,443,81 proto tcp
sudo ufw allow from 10.8.0.0/24 to any port 80,443,81 proto tcp

sudo ufw enable
```

## Quick Start

### Prerequisites

  * Debian-based host system (Raspberry Pi OS / Ubuntu).
  * Docker and Docker Compose installed.
  * WireGuard kernel module support.

### Initialization

1.  Clone the repository and navigate to the docker directory:

    ```bash
    git clone https://github.com/iago-fernandez/homelab.git
    cd homelab/docker
    ```

2.  Configure environment variables using the provided template:

    ```bash
    cp .env.example .env
    nano .env # replace placeholders with custom credentials
    ```

3.  Launch the containerized stack:

    ```bash
    docker compose up -d
    ```

4.  Configure Nginx Proxy Manager to establish internal domain forwarding rules for the running containers.

## Contributing

Contributions regarding infrastructure hardening or automation efficiency are welcome. Please ensure that pull requests maintain the established security boundaries and prioritize minimal resource overhead. Adhere to the current repository structure when proposing changes to the deployment workflow. See the [CONTRIBUTING](CONTRIBUTING.md) file for more information.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
