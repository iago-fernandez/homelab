# Container Orchestration

This directory contains the service definitions and environment configurations managed by Docker Compose. The architecture is designed to be stateless at the container level, with all persistence delegated to the configuration directory.

## Service Stack

The infrastructure is composed of the following microservices:

* Nginx Proxy Manager: Acts as the internal ingress gateway, handling reverse proxying and hostname resolution for local services within the VPN boundary.
* Homepage: Provides a centralized dashboard for service monitoring and navigation.
* Home Assistant: Operates in host network mode to manage local automation and hardware discovery.
* Seafile: File storage and synchronization, and sharing platform.
* MariaDB: Dedicated database backend strictly allocated for the Seafile application layer.
* PostgreSQL: Relational database backend explicitly provisioned to support the future development and deployment of a custom multi-platform application.

## Network Architecture

* Internal Bridge: An isolated bridge network that connects the reverse proxy to the backend services. This prevents direct external access to the databases and isolates inter-container traffic.
* Host Network: Used exclusively by Home Assistant to ensure direct access to local network protocols for hardware discovery.

## Environment Configuration

The stack relies on an environment file to inject sensitive credentials and system paths.

* Configuration: See `.env.example` for the required variable schema.
* Persistence: All data volumes are mapped relative to the `config/` directory to ensure data sovereignty.

## Usage

To deploy or update the stack:

```bash
# Start all services in detached mode
docker compose up -d

# View logs for a specific service
docker compose logs -f seafile # service names are defined in docker-compose.yml file

# View usage stats
docker stats
```