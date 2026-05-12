# Spec 36: Exonomy Deployment Standard

[ 🏠 Back to Exosystem Root ](../../README.md)

> [!IMPORTANT]
> This specification has been superseded by the **[Enterprise FHS Installer Specification](../releases/fhs_installer_specification.md)**. All new deployments MUST target the FHS paths (`/opt/exo/`, `/etc/exo/`, `/var/lib/exo/`, `/var/log/exo/`) defined in that document.

## Current Standard

The Exonomy node deployment architecture follows the **Enterprise FHS Installer Specification**:

- **Binaries**: `/opt/exo/` — immutable application artifacts.
- **Configuration**: `/etc/exo/` — systemd `.env` files and node identity.
- **State**: `/var/lib/exo/` — persistent identity keys, Willow data, capabilities.
- **Logs**: `/var/log/exo/` — centralized, logrotated diagnostics.
- **Service User**: `exo-sys` — headless, non-login system user for backend service isolation.
- **Systemd Units**: `/etc/systemd/system/exo-*.service` — system-level orchestration.
- **Installer**: A modular inquire-based interactive installer (Tier 2 per Spec 07) for guided, idempotent provisioning.

For the complete directory mapping, systemd unit templates, security model, and installer flow, refer to the **[FHS Installer Specification](../releases/fhs_installer_specification.md)**.

## Legacy Reference

The previous user-space deployment layout (`~/deployments/`) is documented in the [walkthrough history](../walkthroughs/72_enterprise_fhs_migration_pivot.md). Existing nodes running the legacy layout can migrate using the TUI installer's built-in migration path.
