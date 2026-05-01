# Conscia Distribution & Interaction Specification

This document defines the strategy for distributing the Conscia binary across various ecosystems and the design of its interactive terminal experiences.

## 1. Philosophical Identity & Licensing
Conscia and the broader ExoTalk project are **Open Source**. While permissive licenses (MIT/Apache 2.0) are common, the **AGPL-3.0** (GNU Affero General Public License) may be more "philosophically correct" for this project.

- **Why AGPL-3.0?**: It ensures that if a service provider hosts Conscia to provide "Lifeline-as-a-Service," they must contribute any improvements back to the community. This prevents the "centralization by stealth" that permissive licenses can sometimes facilitate in P2P ecosystems.
- **Transparency**: All packages (Apt, Snap, NPM) must be built from verifiable CI/CD pipelines.

## 2. Interaction Design: CLI vs. TUI
To provide a "rich interactive experience," Conscia will employ a tiered terminal strategy:

| Tier | Technology | Purpose |
| :--- | :--- | :--- |
| **CLI** | `clap` | Non-interactive automation, piping, and quick commands (e.g., `conscia status`). |
| **Interactive** | `inquire` / `dialoguer` | Guided onboarding, configuration wizards, and "Are you sure?" prompts. |
| **TUI** | `ratatui` | Immersive, full-screen dashboard for real-time monitoring of mesh health and logs. |

---

## 3. Distribution Channels

### A. Linux Native (Apt / Snap / Flatpak)
- **Apt (Repository)**:
  - Hosted via GitHub Pages or a dedicated repository server.
  - Lifecycle: `apt update && apt install conscia`.
  - State: Installs a systemd service (`conscia.service`) that runs as a low-privilege `conscia` user.
- **Snap**:
  - Hosted on Snapcraft.io.
  - Benefit: Strict sandboxing and automatic updates across Ubuntu, Fedora, and Arch.
  - State: Runs in a confined environment with `network` and `mount-observe` interfaces.

### B. Developer Ecosystem (NPM / Cargo)
- **NPM (`@exotalk/conscia`)**:
  - **Step 1**: User runs `npm install -g @exotalk/conscia`.
  - **Step 2**: NPM fetches the wrapper package.
  - **Step 3**: `postinstall` script detects OS (Linux/macOS/Windows) and Arch (x64/arm64).
  - **Step 4**: Script downloads the matching binary from GitHub Releases.
  - **Step 5**: Binary is placed in the global `bin` path.
  - **State**: The `conscia` command is available, but **no background service is started**. This is a purely automated "Delivery" phase.
- **Cargo**:
  - `cargo install conscia`.
  - Compiles from source. Ideal for developers.

### C. Containerized (Docker)
- **Image**: `ghcr.io/exonomy/conscia:latest`.
- **Use Case**: Cloud-native beacons and high-availability clusters.
- **State**: Fully isolated. Persists data via volume mounts to `/var/lib/conscia`.

---

## 4. Onboarding & First-Run Lifecycle
Onboarding and node identification do **not** happen during installation. The `apt` or `npm` phase is purely for binary delivery.

1. **First Run**: When the user first executes `conscia` (or when the systemd service first starts), the node checks for an existing `config.toml`.
2. **Interactive Wizard**: If no config exists, the **Interactive Onboarding** (TUI/Wizard) triggers:
   - **Identity Generation**: Creates a new `did:peer`.
   - **Node ID Resolution**: The node announces its presence and displays its ID/QR code.
   - **Initial Association**: Asks the user if they want to link this node to their primary ExoTalk instance immediately.

## 5. Knowledge Gaps & Future Research
- **Windows Distribution**: Should we use MSI via `cargo-wix` or a portable `.exe`?
- **Mobile Conscia**: Is there a use case for a headless Android binary (Termux-style)?
