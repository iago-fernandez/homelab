# Contributing

Thank you for your interest in improving this HomeLab Infrastructure project. This project focuses on secure, modular, and automated system deployment using Docker and Bash. Please review the guidelines below to ensure your contribution aligns with the project's architectural standards.

## Engineering Standards

To maintain stability, security, and portability across deployments, contributions must adhere to the following:

* **Shell Scripting (Bash):**
    * Always use strict error handling (`set -euo pipefail`).
    * Quote all variables to prevent word splitting.
    * Ensure scripts require root privileges (`$EUID -eq 0`) only when strictly necessary.
* **Container Orchestration (Docker):**
    * Maintain stateless containers; map all persistent data exclusively to the `config/` directory.
    * Avoid exposing container ports directly to the host unless required by the reverse proxy or host-network services.
* **Security and Privacy:**
    * Never commit sensitive data, IP addresses, or cryptographic keys. Use generic placeholders (e.g., `<REDACTED>`) or `.env.example` templates.
    * Adhere to the Zero-Trust network model. Do not expose new ports to the public internet. Ensure any internal port changes are reflected in the UFW firewall configuration scripts.
* **Code Style:**
    * **Lists:** Always use asterisks (`*`) for bulleted lists in Markdown files.
    * **Indentation:** 4 spaces for YAML files, 4 spaces consistently for Bash scripts.

## Development Workflow

1. **Fork and Clone** the repository.
2. **Branching Strategy:**
    * `feat/`: New Docker services, deployment scripts, or major architectural changes.
    * `fix/`: Configuration corrections, permission fixes, or script bugs.
    * `refactor/`: Infrastructure optimization or code cleanup.
    * `docs/`: Documentation updates.
3. **Validation:** Validate Docker Compose files using `docker compose config` and test Bash scripts locally before opening a pull request.

## Commit Guidelines

We use **Conventional Commits** to maintain a clean, semantic history. The title of the pull request should be the same as the branch, but in conventional commits format and extended to be clearer.

* `feat(network): implement dynamic NAT traversal for VPN clients`
* `fix(docker): resolve volume permission mismatch for PostgreSQL`
* `refactor(system): optimize automated installation sequence`
* `docs(readme): establish core documentation hierarchy`

## Pull Request Process

* Provide a clear description of the changes. The description must **only be a list of the changes using infinitives** (e.g., "Add support for...", "Optimize loop..."), not past tense.
* Ensure no sensitive data is included in the diff.
* Ensure all new services or scripts are fully documented in their respective `README.md` files.
* Squash intermediate commits to keep the history linear before merging.