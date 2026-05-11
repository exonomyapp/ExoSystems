# Walkthrough 73: Enterprise FHS Modular Installer (Planning Phase)

**Date**: May 11, 2026

## 1. Objective
This session focused entirely on the architectural planning and specification for the **Enterprise FHS Installer**. We finalized the design required to transition the Exosystem from user-space deployments (`~/deployments/`) to a strict, production-grade Linux Filesystem Hierarchy Standard (FHS) architecture.

## 2. Key Architectural Decisions

### 2.1 The Modular TUI Installer
We rejected both monolithic `.deb` packages and domain-separated `.deb` packages. Instead, the deployment will be orchestrated by a **Sophisticated Terminal User Interface (TUI)** mechanism.
- The TUI acts as an interactive configuration dashboard.
- It allows the operator to selectively deploy any combination of the four core components: **Conscia** (daemon), **Conscia UI** (desktop app), **Zrok**, and **Signaling**.
- The TUI handles complex configurations, including securely capturing credentials and selecting OpenTofu cluster deployment scripts.
- Execution only begins when the operator visually confirms the configuration and triggers the "Install" action.

### 2.2 FHS Directory Mapping
The installer will rigidly adhere to the following enterprise paths:
- **`/opt/exo/`**: Centralized parent directory for all immutable application binaries and the Conscia UI bundle.
- **`/etc/exo/`**: Systemd `.env` files and global configurations.
- **`/var/lib/exo/`**: Persistent storage for state, identity keys, and capability stores.
- **`/var/log/exo/`**: Centralized, log-rotated diagnostic outputs.

### 2.3 Process Isolation & Security
- **`exo-sys`**: A headless, dedicated system user will be generated (`useradd -r -s /usr/sbin/nologin`). This user will own and execute the `conscia`, `zrok`, and `signaling` systemd background services.
- **API-First Configuration**: The `exo-sys` user will initialize all necessary states silently via API calls to the Conscia daemon during installation.
- **GUI Separation**: The **Conscia UI** desktop application will be installed globally (e.g., `/usr/share/applications/`) but will always execute under the human operator's standard session permissions, interfacing with the headless backend strictly via API.

## 3. Hand-off to Next Session
The immediate next action for the subsequent session is to finalize the architectural review and, once approved, begin drafting the formal `docs/releases/fhs_installer_specification.md` and the development of the TUI installer.

---
# 🧠 EDUCATIONAL CONTEXT: Modular Configuration States
# The TUI installer is designed as a state-builder, allowing 
# complex credentials and deployment topologies to be verified 
# visually before a single bit is written to the FHS.

