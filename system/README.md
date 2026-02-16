# System Provisioning and Security

This module contains the foundational shell scripts responsible for bootstrapping the host environment, resolving dependencies, enforcing strict network security policies, and managing hardware power states. The scripts are designed to ensure consistency across deployments and require root privileges for execution.

## Core Components

### Automated Installer (`install.sh`)

The installation script serves as the primary entry point for infrastructure deployment. It automates the environment preparation process to eliminate manual configuration errors.

* System Update: Synchronizes package repositories and upgrades existing packages to patch known vulnerabilities before deployment.
* Dependency Resolution: Installs essential system utilities and networking tools, including curl, git, jq, bc, ufw, tar, wireguard, and qrencode.
* Docker Provisioning: Detects the presence of the Docker runtime. If absent, it fetches and executes the official Docker provisioning script, automatically appending the deployment user to the Docker group for socket access.
* Directory Initialization: Scaffolds the persistent directory structure required by Docker volumes to ensure stateful data is correctly mapped and protected.
* Service Deployment: Transfers the orchestration manifests to the target execution directory and stages the firewall configuration binary in the system path.

### Network Security (`firewall_setup.sh`)

The firewall script implements a hardened network perimeter utilizing Uncomplicated Firewall (UFW). It operates on a strict zero-trust baseline for external traffic.

* Default Policies: All inbound traffic is dropped by default. Outbound traffic is permitted to allow the host to fetch system updates and container images.
* VPN Gateway: Port 51820/UDP is explicitly opened to the public internet. This is the only exposed port and serves solely to facilitate WireGuard VPN handshakes and encrypted tunneling.
* Hardware Discovery: UDP ports 5353 (mDNS) and 1900 (SSDP) are opened exclusively on the local physical interface to allow orchestration services like Home Assistant to discover physical IoT devices.
* Trusted Subnets Access: A loop-based configuration explicitly whitelists the Local Area Network (192.168.1.0/24) and the Virtual Private Network (10.8.0.0/24) subnets. Only clients originating from these mathematically defined trusted networks can access SSH (22/TCP) and internal container APIs.
* Docker Bridge Routing: Explicit routing rules permit the internal Docker subnet (172.18.0.0/16) to communicate with specific container endpoints, ensuring inter-service functionality without exposing the endpoints to the host network.

### Power Management (UPS)

To ensure data integrity during power outages, the system utilizes Network UPS Tools (NUT) for hardware telemetry and automated state management.

* Hardware Interface: The UPS is continuously polled via the NUT daemon to monitor input voltage, load, and battery capacity.
* Shutdown Policy: The `upsmon` service is configured to trigger a graceful system shutdown when the battery capacity reaches the critical threshold of 20 percent.
* Service Port: Port 3493/TCP is permitted within the local subnet to allow potential secondary systems to read telemetry data from the primary UPS daemon.

## Execution Protocol

These scripts are designed to be executed sequentially during the initial host setup.

* Navigate to the root directory of the repository.
* Execute the installer with elevated privileges: `sudo bash system/install.sh`
* The installer automatically stages the firewall script at `/usr/local/bin/setup-firewall.sh`. This script must be executed manually to lock down the system after verifying that the initial Docker containers are successfully provisioned.
* Configure and enable the NUT services (`nut-server` and `nut-client`) to enforce the power management policies.