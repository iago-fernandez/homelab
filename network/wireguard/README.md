# Network and VPN Infrastructure

This directory contains the core WireGuard server configuration and the automated Bash utilities responsible for VPN client lifecycle management. The infrastructure prioritizes privacy, strict access control, and seamless remote connectivity to the internal homelab network.

## VPN Architecture and Privacy

The network stack is engineered to avoid exposing any internal services to the public internet. All remote administration and service consumption must occur through the encrypted WireGuard tunnel.

* DNS Resolution: The VPN tunnel routes client DNS queries through the host gateway. The physical network relies on the upstream router, which is explicitly configured to use Cloudflare DNS (1.1.1.1) to ensure privacy and prevent ISP tracking.

* Dynamic Routing: The server configuration utilizes dynamic NAT traversal rules to automatically identify the default physical interface and masquerade outbound client traffic.

* Dual-Mode Tunneling: Client configurations are generated in two variants to accommodate different use cases:

  * Full Tunnel: Routes all internet and local traffic through the VPN server, ensuring encrypted communication on untrusted public networks.
  * Split Tunnel: Routes only the traffic destined for the internal homelab subnets through the VPN, allowing standard internet traffic to bypass the server to conserve bandwidth.

## Client Management Utilities

The provided scripts automate the complex process of key generation, IP allocation, and interface updating. These scripts require root privileges and implement robust error checking to prevent configuration corruption.

### `wg-add-client`

Provisions a new client profile, generates asymmetric cryptographic keys, and safely allocates the next available IP address from the configuration pool.

```bash
sudo wg-add-client <client-name> [endpoint]
```

* The script automatically updates the live WireGuard interface without requiring a service restart.
* Generates both Full and Split tunnel configuration files in the client's dedicated directory, and shows the QRs to easily setup the VPN in the client devices (by calling the `wg-show-qr` script below).

### wg-del-client

Safely revokes access for an existing client.

```bash
sudo wg-del-client <client-name>
```

* Unregisters the peer's public key from the active interface.
* Purges the client's configuration directory, including all cryptographic material.

### wg-show-qr

Renders the generated WireGuard configuration files as ANSI text QR codes directly in the terminal, facilitating rapid provisioning of mobile devices (by camera scanning).

```bash
sudo wg-show-qr <client-name> [full|split|both]
```