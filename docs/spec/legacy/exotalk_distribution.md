# ExoTalk Distribution & User Experience Specification

This document outlines the multi-platform distribution strategy for the ExoTalk chat application, focusing on "Solid Identity," high-fidelity installation experiences, and sovereign updates.

## 1. Open Source Identity & Trust
ExoTalk is **Open Source (AGPL-3.0)**.
- **Code Signing**: To ensure user safety, all official binaries for Windows, macOS, and Android must be cryptographically signed by the ExoSystems Governance key.
- **Reproducible Builds**: We aim for bit-for-bit reproducible builds to allow the community to verify that the binaries in the stores match the public source code.

## 2. Platform Distribution Matrix

### A. Desktop (Linux, macOS, Windows)
| Platform | Format | Channel | Delivery / Update Strategy |
| :--- | :--- | :--- | :--- |
| **Linux** | **Flatpak** | Flathub | Preferred for Linux. Sandboxed, cross-distro, and handles auto-updates natively. |
| **Linux** | **Snap** | Snapcraft | Best for Ubuntu users; strictly confined for security. |
| **macOS** | **DMG / App** | Direct / Homebrew | Signed `.dmg` with Sparkle for zero-friction auto-updates. |
| **macOS** | **App Store** | Apple App Store | For users preferring a managed ecosystem. |
| **Windows** | **MSIX / EXE** | Direct / Winget | Signed installer with background update polling. |
| **Windows** | **Store** | Microsoft Store | For maximum reach and trust in the Windows ecosystem. |

### B. Mobile (Android, iOS)
| Platform | Format | Channel | Delivery / Update Strategy |
| :--- | :--- | :--- | :--- |
| **Android** | **APK / AAB** | Direct / F-Droid | **F-Droid** is the priority for open-source purity. Direct APK for "Sovereign" users. |
| **Android** | **Play Store** | Google Play | For mass adoption and automatic updates. |
| **iOS** | **IPA** | App Store | Standard path. Requires strict adherence to Apple's App Sandbox. |
| **iOS** | **TestFlight** | Beta | For early community testing and feature feedback. |

---

## 3. Enterprise & Automated Deployment (Docker / Headless)

For organizations and administrators deploying ExoTalk at scale, we provide a specialized **Docker-based Headless Client**. This is the primary vehicle for our [Enterprise Simulation Tutorials](../scenarios/screenplays/05_enterprise_docker_simulation.md).

### A. The Headless Client
- **Binary**: `exotalk-cli` (A specialized build of the Flutter app compiled as a terminal-only binary using the `dart_io` runner).
- **Automation**: Fully controllable via the [Verification & Telemetry API](19_verification_telemetry_api.md).
- **Use Case**: Organizations can spin up hundreds of transient clients to verify mesh performance or provide automated "Conscierge" services to employees.

### B. Docker Distribution
- **Image**: `ghcr.io/exonomy/exotalk-headless:latest`
- **Environment**: Fully containerized with a volume mount at `/root/.local/share/exotalk` for identity persistence.
- **Scaling**: Optimized for Kubernetes/OpenTofu deployments, allowing for the "AI Multi-Voice Simulation" demonstrated in our tutorials.

---

## 3. The "Solid Identity" Onboarding Experience
Installation is only the first step. The first run experience must be "WOWing" and frictionless:

1. **The Welcome Pulse**: A high-fidelity animated splash screen reflecting the node's heartbeat.
2. **Identity Synthesis (The "Familiar Front Door")**:
   - **OAuth Bridge**: To bridge the gap for users familiar with Google/Apple sign-in, ExoTalk facilitates identity creation *through* these providers.
   - **Synthesis Logic**: During the familiar OAuth flow, a `did:peer` is generated and cryptographically associated with the provider's token. The user feels the comfort of a standard login, while the mesh receives a sovereign P2P identifier.
   - **Sovereign Setup**: A "Raw P2P" path remains available for power users to generate an unanchored `did:peer` in two taps.
3. **Bridged Convenience**: The spirit of ExoTalk is not to force users to abandon their existing technologies, but to leverage them. By allowing users to permanently anchor their mesh identity to familiar OAuth providers, they can enjoy the convenience of standard logins while participating in the decentralized Exosystem. This facilitates rapid adoption and proliferation without sacrificing the benefits of the mesh.
4. **Conscia Pairing**: An optional but encouraged step during onboarding to link a "home node" (Lifeline) for data persistence.
5. **Mesh Discovery**: Automatic local network scan to show immediate P2P connectivity potential (mDNS/Bluetooth).

---

## 4. Technical Requirements for Diverse Distribution

### A. CI/CD Pipeline (GitHub Actions)
- **Matrix Builds**: Automatically compile for all 5 targets on every release tag.
- **Artifact Signing**: Automated signing steps using stored secrets for macOS/Windows/Android.
- **Store Uploads**: Use Fastlane (iOS/Android) and custom scripts for Flathub/Snapcraft.

### B. Sovereign Update Infrastructure
To maintain sovereignty, ExoTalk must not rely solely on centralized stores:
- **Manifest Polling**: The app should check a public JSON manifest on `exotalk.local` or a DHT-based record to notify users of updates when not installed via a store.
- **P2P Update Sharing**: (Experimental) Allow nodes to share update binaries over the mesh itself to bypass censorship or connectivity issues.

## 5. Knowledge Gaps
- **Flatpak FFI issues**: Ensure that the Rust FFI layers (`exotalk_ffi`) are correctly bundled within the Flatpak sandbox.
- **Windows WebView2**: Dependency management for Windows users without the latest runtime.
