# Walkthrough 77: FHS Modular Installer

This walkthrough documents the implementation of the **FHS Modular Installer**, fulfilling the deployment milestone. The Exosystem node has transitioned from manual scripts to a standard Linux distribution configuration.

## Key Accomplishments

### 1. Signaling Integration
Standalone Python signaling server functionality was absorbed into the **Conscia** Rust daemon.
- **Native Routes**: Added `/api/signaling` (POST) and `/api/signaling/:target` (GET) to the Axum router.
- **Zero-Dependency**: Removed the Python runtime requirement on the node.
- **Result**: The deployment surface consists of 2 core components (Conscia + ConSoul) and 1 optional component (Zrok).

### 2. Installer Crate
Created a Rust crate (`exo-installer/`) to manage the FHS provisioning lifecycle.
- **Guided Wizard**: Utilizes the `inquire` library for a terminal interface.
- **Idempotency**: Provisions the `exo-sys` system user, directory hierarchy, and permissions.
- **FHS Compliance**: Enforces standard paths (`/opt/exo`, `/etc/exo`, `/var/lib/exo`, `/var/log/exo`).
- **Health Verification**: Queries systemd post-install to verify service status.

### 3. Debian Packaging
Established the foundation for native `.deb` distribution.
- **Debconf Integration**: The `.deb` installation process utilizes `debconf` for configuration.
- **Standardized postinst**: Automates service registration and directory management during installation.

### 4. Build Orchestration
Created a root `Makefile` to unify the build process.
- `make build-all`: Compiles Conscia (Rust), ConSoul (Flutter), and the Installer (Rust).
- `make package`: Stages artifacts into a `dist/` directory.

## Technical Summary

| Feature | Implementation | Path |
|---|---|---|
| **Signaling** | Axum routes in Conscia | [main.rs](../../conscia/src/main.rs) |
| **Installer** | Rust (inquire + indicatif) | [exo-installer/](../../exo-installer/) |
| **Packaging** | Debian control/config/postinst | [debian/](../../exo-installer/debian/) |
| **Systemd** | FHS-units | [templates/](../../exo-installer/templates/) |
| **Makefile** | Multi-language build script | [Makefile](../../Makefile) |

## Verification Results

- **Conscia Build**: Native signaling routes compile and serve successfully.
- **Installer Build**: The `exo-installer` binary compiles and performs root checks.
- **Makefile**: Build targets verified.
- **Documentation**: [FHS Installer Spec](../releases/fhs_installer_specification.md) and [Spec 36](../spec/36_exonomy_deployment_standard.md) updated with ConSoul branding.

---
**Status**: Implementation complete.
