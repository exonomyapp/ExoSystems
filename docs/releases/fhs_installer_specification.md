# Enterprise FHS Installer Specification

[ 🏠 Back to Exosystem Root ](../../README.md)



## 1. Objective & Philosophy

The **Process IS The Product** mandate demands that the software itself automates its own installation, configuration, and service registration.

This specification defines a **Modular TUI Installer** that provisions Exosystem nodes into a production-grade Linux Filesystem Hierarchy Standard (FHS) architecture. The installer treats each node as a composite of independently selectable components, providing an interactive configuration experience before writing a single byte to the filesystem.

## 2. Component Architecture

The Exosystem node is composed of three selectable components:

| # | Component | Type | Description |
|---|-----------|------|-------------|
| 1 | **Conscia** | Rust daemon | Core API, Willow relay, and native Signaling relay |
| 2 | **Zrok** | External binary | Secure overlay network tunneling (Optional) |
| 3 | **ConSoul** | Flutter desktop app | Administrative console for the node |

Components 1 and 2 are **headless backend services** managed by systemd under the `exo-sys` user. Component 3 is a **GUI application** that runs under the human operator's session and communicates with the backend strictly via API.

## 3. Filesystem Hierarchy Mapping

All components adhere to the following FHS directory structure:

### 3.1 Immutable Binaries (`/opt/exo/`)
```
/opt/exo/
├── conscia/          # Conscia daemon binary (includes signaling)
├── zrok/             # Zrok binary (optional)
└── ui/               # ConSoul Flutter bundle
    ├── consoul       # Main executable
    └── data/         # Flutter assets, fonts, ICU data
```

All binaries under `/opt/exo/` are treated as immutable artifacts. Updates replace the entire component directory atomically.

### 3.2 Configuration (`/etc/exo/`)
```
/etc/exo/
├── conscia.env       # Conscia daemon environment variables
├── zrok.env          # Zrok tunnel configuration
└── node.conf         # Node identity and mesh topology settings
```

Each `.env` file is consumed by the corresponding systemd unit via `EnvironmentFile=`. The `node.conf` file contains shared identity parameters (DID seed path, mesh namespace, etc.) read by all components at startup.

### 3.3 Persistent State (`/var/lib/exo/`)
```
/var/lib/exo/
├── identity/         # Ed25519 keypair and DID documents
├── willow/           # Willow data store and namespace state
├── capabilities/     # Meadowcap capability tokens
└── zrok/             # Zrok reserved share state
```

This directory survives package upgrades. Identity keys are generated once during initial installation and never overwritten by subsequent updates.

### 3.4 Logs (`/var/log/exo/`)
```
/var/log/exo/
├── conscia.log
└── zrok.log
```

All log files are managed by `logrotate`. A configuration file at `/etc/logrotate.d/exo` is installed by the installer to enforce rotation policies (e.g., daily, 7-day retention, compress).

## 4. Security & Process Isolation

### 4.1 The `exo-sys` Service User
```bash
useradd -r -s /usr/sbin/nologin -d /var/lib/exo -m exo-sys
```

- **Non-login**: Cannot be used for interactive SSH sessions.
- **Home directory**: `/var/lib/exo/` — all persistent state is owned by this user.
- **Purpose**: Owns and executes all headless backend services (Conscia, Zrok). Prevents horizontal privilege escalation by isolating service processes from the human operator's session.

### 4.2 Ownership & Permissions

| Path | Owner | Mode | Rationale |
|------|-------|------|-----------|
| `/opt/exo/` | `root:root` | `0755` | Immutable binaries; only root can modify |
| `/opt/exo/ui/` | `root:root` | `0755` | GUI binary; readable/executable by all users |
| `/etc/exo/` | `root:exo-sys` | `0750` | Config readable by service user, not world |
| `/etc/exo/*.env` | `root:exo-sys` | `0640` | Env files may contain secrets |
| `/var/lib/exo/` | `exo-sys:exo-sys` | `0700` | State is private to the service user |
| `/var/log/exo/` | `exo-sys:exo-sys` | `0755` | Logs readable for diagnostics |

### 4.3 ConSoul UI Separation
The ConSoul desktop application does NOT execute as `exo-sys`. It is:
- **Installed** globally at `/opt/exo/ui/` (owned by root).
- **Launched** via a `.desktop` file at `/usr/share/applications/consoul.desktop` under the human operator's session.
- **Connected** to the backend exclusively via the Conscia HTTP/WebSocket API — never via shared filesystem state.

## 5. Systemd Orchestration Standard

All services transition from user-level units to **system-level units** at `/etc/systemd/system/`.

### 5.1 Unit Template: `exo-conscia.service`
```ini
[Unit]
Description=Conscia - Lifeline Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=exo-sys
Group=exo-sys
EnvironmentFile=/etc/exo/conscia.env
ExecStart=/opt/exo/conscia/conscia
WorkingDirectory=/var/lib/exo
Restart=on-failure
RestartSec=5
StandardOutput=append:/var/log/exo/conscia.log
StandardError=append:/var/log/exo/conscia.log

# Hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/exo /var/log/exo

[Install]
WantedBy=multi-user.target
```

# Signaling relay is absorbed into the Conscia daemon.
# exo-signaling.service is deprecated.

### 5.3 Unit Template: `exo-zrok.service`
```ini
[Unit]
Description=Zrok Overlay Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=exo-sys
Group=exo-sys
EnvironmentFile=/etc/exo/zrok.env
ExecStart=/opt/exo/zrok/zrok share reserved --headless
WorkingDirectory=/var/lib/exo/zrok
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/exo/zrok.log
StandardError=append:/var/log/exo/zrok.log

NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/exo/zrok /var/log/exo

[Install]
WantedBy=multi-user.target
```

### 5.4 Dependency Ordering
Services that depend on Docker (e.g., Minikube) must declare explicit dependencies:
```ini
Requires=docker.service docker.socket
After=docker.service
```

## 6. The Modular TUI Installer

### 6.1 Technology
The installer is built as a Rust binary using **inquire** (Tier 2: Interactive per Spec 07 §7.7) for guided configuration. This aligns with the existing Rust toolchain in the monorepo and produces a single, portable, statically-linked binary.

### 6.2 Interactive Dashboard Flow
The installer does NOT execute on raw CLI flags. It presents an interactive configuration dashboard:

1. **Component Selection**: Checkboxes for Conscia (always on), Zrok (optional), and ConSoul. The operator toggles each component on or off.
2. **Configuration Input**: For each selected component, the TUI prompts for necessary parameters:
   - Conscia: Mesh namespace, DID seed generation or import, API/Signaling bind port.
   - Zrok: Reserved share token and backend URL.
3. **Credential Capture**: Secure input fields (masked) for sensitive values like zrok environment tokens.
4. **Topology Preview**: A summary panel showing the exact FHS paths, systemd units, and permissions that will be applied.
5. **Confirmation & Execution**: The operator reviews the full configuration and triggers installation with a final "Install" action. No bytes are written until this explicit confirmation.

### 6.3 Installer Actions
Upon confirmation, the installer executes the following sequence:
1. Create the `exo-sys` user if it does not exist.
2. Create all FHS directories with correct ownership and permissions.
3. Copy component binaries to `/opt/exo/`.
4. Write `.env` configuration files to `/etc/exo/`.
5. Install systemd unit files to `/etc/systemd/system/`.
6. Install logrotate configuration to `/etc/logrotate.d/exo`.
7. Install the ConSoul `.desktop` launcher to `/usr/share/applications/` (if selected).
8. Execute `systemctl daemon-reload`.
9. Enable and start selected services.
10. Run a post-install health check, verifying each service reaches `active (running)`.

### 6.4 Idempotency
The installer is fully idempotent. Running it again on an existing installation will:
- Skip user creation if `exo-sys` already exists.
- Replace binaries atomically (stop service → replace → start service).
- Merge configuration changes without overwriting operator customizations (diffing `.env` files).
- Never overwrite identity keys in `/var/lib/exo/identity/`.

## 7. Packaging & Delivery

### 7.1 Makefile Build Orchestration
The monorepo root provides a `Makefile` that orchestrates cross-compilation of all components and stages them into a local FHS-mirrored directory for the installer to consume:

```makefile
.PHONY: build-conscia build-consoul package

build-conscia:
	cd conscia && cargo build --release

build-consoul:
	cd conscia_flutter && flutter build linux --release

package: build-conscia build-consoul
	mkdir -p dist/opt/exo/conscia dist/opt/exo/ui
	cp conscia/target/release/conscia dist/opt/exo/conscia/
	cp -r conscia_flutter/build/linux/x64/release/bundle/* dist/opt/exo/ui/
```

### 7.2 Debian Package (`.deb`) & AOTA Strategy
In adherence to the **"All Of The Above" (AOTA)** philosophy, the codebase outputs multiple standardized payload types. Native Debian (`.deb`) packages are provided as a fully supported installation option alongside the TUI. 

**Native Configuration via `debconf`**:
To achieve the exact same interactive configuration experience as the Rust TUI, the Debian package leverages `debconf`.
- **Interactive**: During `apt install`, the `DEBIAN/config` script triggers `debconf` to present native terminal prompts (using `dialog` or `readline`) to capture required parameters (e.g., mesh namespace, DID seed, Zrok token).
- **Headless**: For automated deployments (Ansible, Terraform, OpenTofu), administrators can pre-seed these answers using `debconf-set-selections` prior to installation.
- **Execution**: The `DEBIAN/postinst` script consumes these securely captured parameters and replicates the core installer's action sequence (§6.3) for a fully configured deployment without the TUI.


