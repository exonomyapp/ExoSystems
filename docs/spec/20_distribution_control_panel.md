# Distribution & Acquisition Control Panel

This document is the master authority for all public-facing identifiers and acquisition methods. It defines how we address our components in a way that links them to the **exotalk.tech** technology brand.

## 1. Addressing & Infrastructure Conventions

### A. Reverse DNS Strategy (`tech.exotalk.*`)
We use the **exotalk.tech** domain as our global namespace.
- **Foundation**: `tech.exotalk`
- **ExoTalk App**: `tech.exotalk.ExoTalk`
- **ExoTalk CLI**: `tech.exotalk.ExoTalkCLI`
- **Republet App**: `tech.exotalk.Republet`
- **Exonomy App**: `tech.exotalk.Exonomy`
- **Conscia Beacon**: `tech.exotalk.Conscia`

### B. Docker Distribution (GHCR.io)
Official images are hosted at `ghcr.io/exotalk/`. We use a tagging strategy (e.g., `:latest`, `:headless`) to manage build flavors.

### C. The `exotalk.tech` Beacon Node
We maintain a permanent, high-availability **Conscia Beacon** at `conscia.exotalk.tech`. This node serves as a primary bootstrapper for the mesh and provides a reliable point of entry for new identities.

---

## 2. App Identifier Matrix (Designations)

| Component | Role | App ID (Flatpak/Android) | Docker Image Name |
| :--- | :--- | :--- | :--- |
| **ExoTalk** | Flagship Messaging App | `tech.exotalk.ExoTalk` | `ghcr.io/exotalk/exotalk` |
| **ExoTalk CLI** | Headless Automation | `tech.exotalk.ExoTalkCLI` | `ghcr.io/exotalk/exotalk:headless` |
| **Republet** | Independent Content App | `tech.exotalk.Republet` | `ghcr.io/exotalk/republet` |
| **Exonomy** | Independent Economic App | `tech.exotalk.Exonomy` | `ghcr.io/exotalk/exonomy` |
| **Conscia** | Network Beacon | `tech.exotalk.Conscia` | `ghcr.io/exotalk/conscia` |

---

## 3. Curated Installation Methods

To ensure maximum accessibility, we provide curated acquisition paths for all user types.

| Platform | Method | Target Audience |
| :--- | :--- | :--- |
| **Linux** | **Flatpak** | General Desktop Users (Sandboxed/Secure). |
| **Linux** | **AppImage** | Portable/One-click users (No install needed). |
| **Linux** | **Docker** | Server/Headless and Enterprise Simulation. |
| **macOS** | **Homebrew** | Developers and Power Users (`brew install exotalk`). |
| **Windows** | **Winget** | Modern Windows users (`winget install exotalk`). |
| **Universal** | **NPM / Bun** | Web developers and automated bot operators. |
| **Universal** | **Binary (sh)** | Direct scriptable install (`curl ... | sh`). |

---

## 4. The ExoTalk CLI (Headless Automation)

The **ExoTalk CLI** is a first-class headless client designed for the terminal. It is built directly from the underlying Rust engine to provide a powerful interface for automation and mesh management.

### 4.1 Developer Ecosystem (NPM / Cargo)
We provide automated binary delivery for developer toolchains:
- **NPM (`@exotalk/conscia`)**:
    - Wrapper package with a `postinstall` script.
    - Script detects OS/Arch and fetches the matching binary from GitHub Releases.
    - Ensures `conscia` is globally available without manual PATH configuration.
- **Cargo**:
    - Source-based installation via `cargo install conscia`.

### Primary Use Cases:
1.  **"Conscierge" Bots**: Organizations can deploy headless chat clients to provide automated support, notifications, or "Concierge" services to members.
2.  **Automated Mesh Auditing**: Scripted clients can periodically "ping" the mesh to verify connectivity and sync latency from the perspective of an end-user.
3.  **Encrypted Logging Relay**: A headless client can act as a secure sink for logs or telemetry, synchronizing them across the mesh to a private storage node.
4.  **Power User Scripting**: Allowing users to send messages or manage group memberships directly from their own local terminal scripts.

---

## 5. The "Cold Start" UI Protocol

### The Requirement
When a user first installs any of our apps, they have zero local data. The application must detect this state to ensure the user isn't presented with a blank screen or a confusing generic login.

### The Guide (Manual Process)
As defined in **Spec 17 (Solid Front Door)**, we do not perform "automatic" registration. Instead:
- The app detects an uninitialized identity.
- It immediately presents the **ExoAuth "Welcome" UI**.
- A prominent guide button leads the user **manually** through the process of "Identity Synthesis" (choosing a handle, anchoring to a provider, or generating a raw P2P ID).

---

## 6. Final Status
- **Domain Baseline**: Standardized on **`tech.exotalk.*`**.
- **Registry**: Standardized on **`ghcr.io/exotalk/`**.
- **Installation Methods**: Curated for all primary platforms.
