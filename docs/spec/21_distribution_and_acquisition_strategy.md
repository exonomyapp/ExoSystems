# Distribution & Acquisition Strategy

This document defines the multi-platform distribution and acquisition strategy for the Exosystem. It outlines how we deliver binaries to users and organizations while maintaining the "Solid Identity" standard and ensuring architectural autonomy.

## 1. Open Source Identity & Trust

The Exosystem is **Open Source (AGPL-3.0)**. We prioritize cryptographic transparency and user safety across all delivery channels.

- **Philosophical Alignment (AGPL-3.0)**: We use the AGPL-3.0 to ensure that service providers hosting Exosystem components (like Conscia Lifelines) must contribute improvements back to the community, preventing "centralization by stealth."
- **Code Signing**: All official binaries (Windows, macOS, Android) must be cryptographically signed by the ExoSystems Governance key.
- **Reproducible Builds**: We aim for bit-for-bit reproducible builds to allow the community to verify that official binaries match the public source code.

## 2. Platform Distribution Matrix

| Platform | Format | Channel | Delivery / Update Strategy |
| :--- | :--- | :--- | :--- |
| **Linux** | **Flatpak** | Flathub | Preferred for desktop. Sandboxed and cross-distro. |
| **Linux** | **AppImage** | Direct | Portable "one-click" execution for all distributions. |
| **macOS** | **DMG / App** | Direct / Brew | Signed `.dmg` with Sparkle for auto-updates. |
| **Windows** | **MSIX / EXE** | Direct / Winget | Signed installer with background update polling. |
| **Android** | **APK / AAB** | F-Droid / Play | F-Droid is priority for FOSS purity. |
| **iOS** | **IPA** | App Store | Standard path via TestFlight and Store. |
| **Server** | **Docker** | GHCR | Optimized for headless nodes and HA clusters. |

---

## 3. The "Binary to Identity" Journey

Installation is only the first step. The transition from binary acquisition to **Identity Synthesis** must be frictionless and high-fidelity.

### A. The "Solid Front Door" (Spec 17)
The first run experience utilizes a high-fidelity animated splash screen reflecting the node's heartbeat. If no identity is detected, the app presents the **ExoAuth** manual guide.

### B. Identity Synthesis
- **ExoTalk Onboarding**: Users choose their handle and anchor their identity via the manual UI guide.
- **Conscia Pairing**: New installs are encouraged to link the **`conscia.exotalk.tech`** beacon node (or a private Lifeline) for persistent data storage.

---

## 4. Enterprise & Automated Acquisition (KDVV)

For organizations and automated testing, we provide specialized delivery methods:

### A. ExoTalk CLI & Headless Nodes
- **Image**: `ghcr.io/exotalk/exotalk:headless`
- **Purpose**: High-availability relays, "Conscierge" bots, and automated mesh auditing.
- **Telemetry**: These nodes are managed and verified via the **Verification Telemetry API (Spec 19)**.

### B. Developer Toolchains (NPM / Bun)
We distribute CLI tools (Conscia CLI, ExoTalk CLI) via standard developer registries:
- **NPM**: `@exotalk/conscia` for infrastructure management.
- **Cargo**: `cargo install conscia` for source-based compilation.

---

## 5. Independent Update Infrastructure

To maintain autonomy, the Exosystem does not rely solely on centralized stores:
- **Manifest Polling**: Non-store installs check a public JSON manifest on **`exotalk.tech`** for updates.
- **P2P Update Sharing**: (Experimental) Allowing nodes to share update binaries directly over the mesh to bypass censorship or connectivity outages.

## 6. Technical Requirements & Sandbox Constraints

- **Flatpak FFI**: We must ensure Rust FFI layers are correctly bundled within the Flatpak sandbox.
- **Socket Permissions**: Desktop apps require network and session-bus access to maintain P2P connectivity.
- **Telemetry Exposure**: The Telemetry API (Port 11434) is used to verify "Scorched Earth" installs during the Phase 6 Audit.
