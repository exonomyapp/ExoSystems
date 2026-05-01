# ExoTalk (Multi-Platform)

This is the decentralized chat application of the Sovereign Exosystem. 

ExoTalk compiles natively for iOS, Android, macOS, Linux, and Windows using Flutter. It does **not** rely on a centralized backend cloud.

## 🛡️ Sovereign Onboarding
ExoTalk features a seamless "Link or Generate" onboarding flow:
*   **Google & GitHub**: Bridge your social identity to a local `did:peer`.
*   **Conflict Resolution**: High-fidelity notification system for manual identity reconciliation.
*   **Isolation Mode**: Every profile has its own encrypted storage and P2P lifecycle.

## 🪪 Account Manager (Sovereign Dashboard)
The Account Manager is a two-column high-density modal (`maxWidth: 920`) that surfaces all identity and security controls without scrolling:

*   **Profile Section**: Avatar tile with Change/Remove photo context menu. Housing the **Display Name** editor and **Network Sync** controls (Inbound/Outbound toggles) in a symmetrical 50/50 header row.
*   **Security Vault**: DID identifier + masked signing secret with copy buttons. Inline **"Synthesize"** action regenerates the Ed25519 keypair via Rust FFI—a tactical birth of local sovereignty. Occupies the left half of the body.
*   **Verified Identities**: Horizontal carousel of linked social proofs (Twitter, GitHub, Facebook). Each tile opens a context menu with "View Proof" and "Remove Link" actions. Occupies the right half of the body.
*   **Activation**: The primary action button dynamically transitions between **"Initialize Identity"** (for new synthesis) and **"Sync Account"** (for existing profiles), ensuring a narrative-driven onboarding experience.
*   **Pairing Action**: The "Pair" button in the Network Sync header opens the QR-code pairing flow for secure cross-device identity migration.
*   **Tristate Theme Support**: Integrated appearance control for Light, Dark, and System modes. Adheres to the Solid Identity mandate with high-contrast elevated surfaces and borders.
*   **Danger Zone**: Full-width destructive action row for "Discard Identity" (local-only wipe — `did:peer` is decentralized and cannot be globally deleted).

All interactive tiles use a unified `_ConsciaMenuButton` with `AnimatedScale` tactile press feedback (0.96×). The interface strictly enforces the **Solid Identity** aesthetic: all glassmorphism and transparency have been removed in favor of opaque surfaces and high-contrast borders for maximum professional clarity and performance.

## 📊 Mesh Traffic & Node Governance
The main Home Screen features a high-fidelity, connection-aware traffic visualizer and native Conscia fleet management:
*   **Real-Time Feedback**: Smoothly scrolling bar charts that pulse with activity only when active peers are detected on the mesh.
*   **Status Integration**: Meters dynamically transition between "Searching..." (0 peers) and "Mesh Active" states based on the Conscia Lifeline status.
*   **Conscia Node Management**: A dedicated, collapsible sidebar section for managing a fleet of Conscia nodes.
    - **Live Roster**: Dynamic polling of the associated mesh roster.
    - **Capability Governance**: In-place viewing and delegation of Meadowcap capabilities (Reader, Writer, Admin) per node.
    - **Native Integration**: Selecting a node switches the main view to a specialized Node Management dashboard, mirroring the chat experience.
*   **Independent Gating**: Inbound and Outbound lanes independently reflect the user's sync preference and mesh visibility.

## Architecture
ExoTalk's pure UI is written in Dart/Flutter. All networking, state syncing, and cryptography are farmed out to the underlying Rust engine.

- **Infrastructure as Code (IaC):** To provide uniform provisioning across disparate cloud targets (GCP, AWS, Oracle), HA cluster deployments are standardized on **OpenTofu**. This allows users to specify an HA architecture declaratively without worrying about cloud-provider specific APIs, maintaining a sovereign, open-source toolchain.

We use `flutter_rust_bridge` to auto-generate the binding code. Specifically, this application links directly to `../exotalk_engine/exotalk_ffi/` which is a curated, isolated bridge that *only* contains logic for Chat interfaces.

## Development

### 1. Generating the Bridge
If you make a change in the `exotalk_ffi` Rust crate, you must regenerate the Dart bindings:
```bash
flutter_rust_bridge_codegen generate
```

### 2. Generating the Riverpod State
We heavily utilize `riverpod_generator`. When adding new state providers or JSON serialization models, run:
```bash
flutter pub run build_runner watch -d
```

### 3. Launching
```bash
flutter run
```

## ♿ Accessibility & UI Scaling
ExoTalk supports global UI scaling to accommodate different hardware and vision needs.
- **Ctrl +**: Enlarge UI (up to 3.0x)
- **Ctrl -**: Shrink UI (down to 0.5x)
- **Ctrl 0**: Reset to 1.0x (Default)

This scaling applies globally to all screens, fonts, and icons.
